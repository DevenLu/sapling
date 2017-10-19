// Copyright (c) 2017-present, Facebook, Inc.
// All Rights Reserved.
//
// This software may be used and distributed according to the terms of the
// GNU General Public License version 2 or any later version.

use std::error;
use std::sync::mpsc::SyncSender;

use bincode;
use bytes::Bytes;
use futures::{self, Future, IntoFuture, Stream};

use blobrepo::RawNodeBlob;
use futures_ext::StreamExt;
use mercurial::{self, RevlogRepo};
use mercurial::revlog::RevIdx;
use mercurial_types::{self, Blob, BlobHash, Entry, NodeHash, Parents, Type};

use BlobstoreEntry;
use errors::*;

pub(crate) fn put_manifest_entry(
    sender: SyncSender<BlobstoreEntry>,
    entry_hash: NodeHash,
    blob: Blob<Vec<u8>>,
    parents: Parents,
) -> impl Future<Item = (), Error = Error> + Send + 'static
where
    Error: Send + 'static,
{
    let bytes = blob.into_inner()
        .ok_or("missing blob data".into())
        .map(Bytes::from)
        .into_future();
    bytes.and_then(move |bytes| {
        let nodeblob = RawNodeBlob {
            parents: parents,
            blob: BlobHash::from(bytes.as_ref()),
        };
        // TODO: (jsgf) T21597565 Convert blobimport to use blobrepo methods to name and create
        // blobs.
        let nodekey = format!("node-{}.bincode", entry_hash);
        let blobkey = format!("sha1-{}", nodeblob.blob.sha1());
        let nodeblob = bincode::serialize(&nodeblob, bincode::Bounded(4096))
            .expect("bincode serialize failed");

        let res1 = sender.send(BlobstoreEntry::ManifestEntry(
            (nodekey, Bytes::from(nodeblob)),
        ));
        let res2 = sender.send(BlobstoreEntry::ManifestEntry((blobkey, bytes)));

        res1.and(res2)
            .map_err(|err| Error::from(format!("{}", err)))
    })
}

// Copy a single manifest entry into the blobstore
// TODO: #[async]
pub(crate) fn copy_manifest_entry<E>(
    entry: Box<Entry<Error = E>>,
    sender: SyncSender<BlobstoreEntry>,
) -> impl Future<Item = (), Error = Error> + Send + 'static
where
    Error: From<E>,
    E: error::Error + Send + 'static,
{
    let hash = *entry.get_hash();

    let blobfuture = entry.get_raw_content().map_err(Error::from);

    blobfuture
        .join(entry.get_parents().map_err(Error::from))
        .and_then(move |(blob, parents)| {
            put_manifest_entry(sender, hash, blob, parents)
        })
}

pub(crate) fn get_stream_of_manifest_entries(
    entry: Box<Entry<Error = mercurial::Error>>,
    revlog_repo: RevlogRepo,
    cs_rev: RevIdx,
) -> Box<Stream<Item = Box<Entry<Error = mercurial::Error>>, Error = Error> + Send> {
    let revlog = match entry.get_type() {
        Type::File | Type::Executable | Type::Symlink => {
            revlog_repo.get_file_revlog(entry.get_path())
        }
        Type::Tree => revlog_repo.get_tree_revlog(entry.get_path()),
    };

    let linkrev = revlog
        .and_then(|file_revlog| {
            file_revlog.get_entry_by_nodeid(entry.get_hash())
        })
        .map(|e| e.linkrev)
        .map_err(|e| {
            Error::with_chain(e, format!("cannot get linkrev of {}", entry.get_hash()))
        });

    match linkrev {
        Ok(linkrev) => if linkrev != cs_rev {
            return futures::stream::empty().boxify();
        },
        Err(e) => {
            return futures::stream::once(Err(e)).boxify();
        }
    }

    match entry.get_type() {
        Type::File | Type::Executable | Type::Symlink => futures::stream::once(Ok(entry)).boxify(),
        Type::Tree => entry
            .get_content()
            .and_then(|content| match content {
                mercurial_types::manifest::Content::Tree(manifest) => Ok(manifest.list()),
                _ => panic!("should not happened"),
            })
            .flatten_stream()
            .map(move |entry| {
                get_stream_of_manifest_entries(entry, revlog_repo.clone(), cs_rev.clone())
            })
            .map_err(Error::from)
            .flatten()
            .chain(futures::stream::once(Ok(entry)))
            .boxify(),
    }
}
