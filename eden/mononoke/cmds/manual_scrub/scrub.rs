/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This software may be used and distributed according to the terms of the
 * GNU General Public License version 2.
 */

use anyhow::{Error, Result};
use cloned::cloned;
use futures::{
    channel::mpsc,
    future::{self, FutureExt},
    sink::SinkExt,
    stream::{Stream, StreamExt, TryStreamExt},
};
use std::time::Instant;

use blobstore::Blobstore;
use context::CoreContext;

use crate::progress::Progress;

const PROGRESS_SAMPLE_KEYS: u64 = 1000;

async fn scrub_key<B: Blobstore + Clone + 'static>(
    blobstore: &B,
    ctx: &CoreContext,
    key: String,
    mut success: mpsc::Sender<String>,
    mut missing: mpsc::Sender<String>,
    mut error: mpsc::Sender<(String, Error)>,
) -> Result<Progress> {
    let handle = {
        cloned!(ctx, key, blobstore);
        tokio::task::spawn(async move { blobstore.get(&ctx, &key).await })
    };
    let res = handle.await?;
    let mut progress = Progress::default();
    match res {
        Ok(None) => {
            missing.send(key).await?;
            progress.missing += 1;
        }
        Err(e) => {
            error.send((key, e)).await?;
            progress.error += 1;
        }
        Ok(Some(_)) => {
            success.send(key).await?;
            progress.success += 1;
        }
    };

    Ok(progress)
}

pub async fn scrub<B: Blobstore + Clone + 'static>(
    blobstore: &B,
    ctx: &CoreContext,
    keys: impl Stream<Item = Result<String>>,
    success: mpsc::Sender<String>,
    missing: mpsc::Sender<String>,
    error: mpsc::Sender<(String, Error)>,
    scheduled_max: usize,
    quiet: bool,
) -> Result<()> {
    let init = Progress::default();
    let started = Instant::now();
    if !quiet {
        init.legend(ctx.logger());
    }

    let (run, last_update) = keys
        .map(|key| match key {
            Ok(key) => scrub_key(
                blobstore,
                ctx,
                key,
                success.clone(),
                missing.clone(),
                error.clone(),
            )
            .left_future(),
            Err(e) => future::ready(Err(e)).right_future(),
        })
        .buffered(scheduled_max)
        .try_fold(
            (init, Some((init, started))),
            |(run, mut prev), latest| async move {
                let run = run + latest;
                // overkill to check time elapsed every key, so sample
                if run.total() % PROGRESS_SAMPLE_KEYS == 0 {
                    if let Some(updated) = run.record(ctx.logger(), quiet, started, prev, false) {
                        prev = Some((run, updated));
                    }
                }
                Ok((run, prev))
            },
        )
        .await?;

    // Record progress at finish
    let _ = run.record(ctx.logger(), quiet, started, last_update, true);

    Ok(())
}
