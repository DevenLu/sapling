// Copyright (c) 2018-present, Facebook, Inc.
// All Rights Reserved.
//
// This software may be used and distributed according to the terms of the
// GNU General Public License version 2 or any later version.

use std::collections::BTreeMap;

use ascii::AsAsciiStr;
use bytes::Bytes;
use failure::Error;
use futures::executor::spawn;
use futures::future::Future;
use futures::stream::futures_unordered;
use futures_ext::{BoxFuture, StreamExt};

use blobrepo::{BlobRepo, ChangesetHandle, CreateChangeset, HgBlobEntry, UploadHgEntry};
use memblob::{EagerMemblob, LazyMemblob};
use mercurial::{HgBlobNode, HgNodeHash};
use mercurial_types::{manifest, DNodeHash, FileType, HgBlob, RepoPath};
use mononoke_types::DateTime;
use std::sync::Arc;

pub fn get_empty_eager_repo() -> BlobRepo {
    BlobRepo::new_memblob_empty(None, Some(Arc::new(EagerMemblob::new())))
        .expect("cannot create empty repo")
}

pub fn get_empty_lazy_repo() -> BlobRepo {
    BlobRepo::new_memblob_empty(None, Some(Arc::new(LazyMemblob::new())))
        .expect("cannot create empty repo")
}

macro_rules! test_both_repotypes {
    ($impl_name:ident, $lazy_test:ident, $eager_test:ident) => {
        #[test]
        fn $lazy_test() {
            async_unit::tokio_unit_test(|| {
                $impl_name(get_empty_lazy_repo());
            })
        }

        #[test]
        fn $eager_test() {
            async_unit::tokio_unit_test(|| {
                $impl_name(get_empty_eager_repo());
            })
        }
    };
    (should_panic, $impl_name:ident, $lazy_test:ident, $eager_test:ident) => {
        #[test]
        #[should_panic]
        fn $lazy_test() {
            async_unit::tokio_unit_test(|| {
                $impl_name(get_empty_lazy_repo());
            })
        }

        #[test]
        #[should_panic]
        fn $eager_test() {
            async_unit::tokio_unit_test(|| {
                $impl_name(get_empty_eager_repo());
            })
        }
    }
}

pub fn upload_file_no_parents<B>(
    repo: &BlobRepo,
    data: B,
    path: &RepoPath,
) -> (HgNodeHash, BoxFuture<(HgBlobEntry, RepoPath), Error>)
where
    B: Into<Bytes>,
{
    upload_hg_entry(
        repo,
        data.into(),
        manifest::Type::File(FileType::Regular),
        path.clone(),
        None,
        None,
    )
}

pub fn upload_file_one_parent<B>(
    repo: &BlobRepo,
    data: B,
    path: &RepoPath,
    p1: HgNodeHash,
) -> (HgNodeHash, BoxFuture<(HgBlobEntry, RepoPath), Error>)
where
    B: Into<Bytes>,
{
    upload_hg_entry(
        repo,
        data.into(),
        manifest::Type::File(FileType::Regular),
        path.clone(),
        Some(p1),
        None,
    )
}

pub fn upload_manifest_no_parents<B>(
    repo: &BlobRepo,
    data: B,
    path: &RepoPath,
) -> (HgNodeHash, BoxFuture<(HgBlobEntry, RepoPath), Error>)
where
    B: Into<Bytes>,
{
    upload_hg_entry(
        repo,
        data.into(),
        manifest::Type::Tree,
        path.clone(),
        None,
        None,
    )
}

pub fn upload_manifest_one_parent<B>(
    repo: &BlobRepo,
    data: B,
    path: &RepoPath,
    p1: HgNodeHash,
) -> (HgNodeHash, BoxFuture<(HgBlobEntry, RepoPath), Error>)
where
    B: Into<Bytes>,
{
    upload_hg_entry(
        repo,
        data.into(),
        manifest::Type::Tree,
        path.clone(),
        Some(p1),
        None,
    )
}

fn upload_hg_entry(
    repo: &BlobRepo,
    data: Bytes,
    content_type: manifest::Type,
    path: RepoPath,
    p1: Option<HgNodeHash>,
    p2: Option<HgNodeHash>,
) -> (HgNodeHash, BoxFuture<(HgBlobEntry, RepoPath), Error>) {
    let raw_content = HgBlob::from(data);
    // compute the nodeid from the content
    let nodeid = HgBlobNode::new(raw_content.clone(), p1.as_ref(), p2.as_ref())
        .nodeid()
        .expect("raw_content must have data available");

    let upload = UploadHgEntry {
        nodeid,
        raw_content,
        content_type,
        p1,
        p2,
        path,
        check_nodeid: true,
    };
    upload.upload(repo).unwrap()
}

pub fn create_changeset_no_parents(
    repo: &BlobRepo,
    root_manifest: BoxFuture<(HgBlobEntry, RepoPath), Error>,
    other_nodes: Vec<BoxFuture<(HgBlobEntry, RepoPath), Error>>,
) -> ChangesetHandle {
    let create_changeset = CreateChangeset {
        p1: None,
        p2: None,
        root_manifest,
        sub_entries: futures_unordered(other_nodes).boxify(),
        user: "author <author@fb.com>".into(),
        time: DateTime::from_timestamp(0, 0).expect("valid timestamp"),
        extra: BTreeMap::new(),
        comments: "Test commit".into(),
    };
    create_changeset.create(repo)
}

pub fn create_changeset_one_parent(
    repo: &BlobRepo,
    root_manifest: BoxFuture<(HgBlobEntry, RepoPath), Error>,
    other_nodes: Vec<BoxFuture<(HgBlobEntry, RepoPath), Error>>,
    p1: ChangesetHandle,
) -> ChangesetHandle {
    let create_changeset = CreateChangeset {
        p1: Some(p1),
        p2: None,
        root_manifest,
        sub_entries: futures_unordered(other_nodes).boxify(),
        user: "\u{041F}\u{0451}\u{0442}\u{0440} <peter@fb.com>".into(),
        time: DateTime::from_timestamp(1234, 0).expect("valid timestamp"),
        extra: BTreeMap::new(),
        comments: "Child commit".into(),
    };
    create_changeset.create(repo)
}

pub fn string_to_nodehash(hash: &str) -> DNodeHash {
    DNodeHash::from_ascii_str(hash.as_ascii_str().unwrap()).unwrap()
}

pub fn run_future<F>(future: F) -> Result<F::Item, F::Error>
where
    F: Future,
{
    spawn(future).wait_future()
}
