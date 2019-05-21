// Copyright Facebook, Inc. 2019

use std::path::PathBuf;

use failure::Fallible;

use types::{Key, NodeInfo};

use crate::datastore::{Delta, Metadata, MutableDeltaStore};
use crate::historystore::MutableHistoryStore;

/// A `MultiplexDeltaStore` is a store that will duplicate all the writes to all the
/// delta stores that it is made of.
pub struct MultiplexDeltaStore<'a> {
    stores: Vec<Box<dyn MutableDeltaStore + 'a>>,
}

/// A `MultiplexHistoryStore` is a store that will duplicate all the writes to all the
/// history stores that it is made of.
pub struct MultiplexHistoryStore<'a> {
    stores: Vec<Box<dyn MutableHistoryStore + 'a>>,
}

impl<'a> MultiplexDeltaStore<'a> {
    pub fn new() -> Self {
        Self { stores: Vec::new() }
    }

    pub fn add_store(&mut self, store: Box<dyn MutableDeltaStore + 'a>) {
        self.stores.push(store)
    }
}

impl<'a> MultiplexHistoryStore<'a> {
    pub fn new() -> Self {
        Self { stores: Vec::new() }
    }

    pub fn add_store(&mut self, store: Box<dyn MutableHistoryStore + 'a>) {
        self.stores.push(Box::new(store))
    }
}

impl<'a> MutableDeltaStore for MultiplexDeltaStore<'a> {
    /// Write the `Delta` and `Metadata` to all the stores
    fn add(&mut self, delta: &Delta, metadata: &Metadata) -> Fallible<()> {
        for store in self.stores.iter_mut() {
            store.add(delta, metadata)?;
        }

        Ok(())
    }

    fn flush(&mut self) -> Fallible<Option<PathBuf>> {
        for store in self.stores.iter_mut() {
            store.flush()?;
        }

        Ok(None)
    }
}

impl<'a> MutableHistoryStore for MultiplexHistoryStore<'a> {
    fn add(&mut self, key: &Key, info: &NodeInfo) -> Fallible<()> {
        for store in self.stores.iter_mut() {
            store.add(key, info)?;
        }

        Ok(())
    }

    fn flush(&mut self) -> Fallible<Option<PathBuf>> {
        for store in self.stores.iter_mut() {
            store.flush()?;
        }

        Ok(None)
    }

    fn close(self) -> Fallible<Option<PathBuf>> {
        // close() cannot be implemented as the concrete types of the stores aren't known
        // statically. For now, the user of this MultiplexHistoryStore would have to manually close
        // all of the stores.
        unimplemented!()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    use bytes::Bytes;
    use tempfile::TempDir;

    use types::testutil::*;

    use crate::datapack::DataPackVersion;
    use crate::datastore::DataStore;
    use crate::historypack::HistoryPackVersion;
    use crate::historystore::HistoryStore;
    use crate::indexedlogdatastore::IndexedLogDataStore;
    use crate::mutabledatapack::MutableDataPack;
    use crate::mutablehistorypack::MutableHistoryPack;

    #[test]
    fn test_delta_add_static() -> Fallible<()> {
        let tempdir = TempDir::new()?;
        let mut log = IndexedLogDataStore::new(&tempdir)?;
        let mut multiplex = MultiplexDeltaStore::new();
        multiplex.add_store(Box::new(&mut log));

        let delta = Delta {
            data: Bytes::from(&[1, 2, 3, 4][..]),
            base: None,
            key: key("a", "1"),
        };
        let metadata = Default::default();

        multiplex.add(&delta, &metadata)?;
        drop(multiplex);
        let read_delta = log.get_delta(&delta.key)?;
        assert_eq!(delta, read_delta);
        log.flush()?;
        Ok(())
    }

    #[test]
    fn test_delta_add_dynamic() -> Fallible<()> {
        let tempdir = TempDir::new()?;
        let mut log = IndexedLogDataStore::new(&tempdir)?;
        let mut pack = MutableDataPack::new(&tempdir, DataPackVersion::One)?;
        let mut multiplex = MultiplexDeltaStore::new();
        multiplex.add_store(Box::new(&mut log));
        multiplex.add_store(Box::new(&mut pack));

        let delta = Delta {
            data: Bytes::from(&[1, 2, 3, 4][..]),
            base: None,
            key: key("a", "1"),
        };
        let metadata = Default::default();

        multiplex.add(&delta, &metadata)?;
        drop(multiplex);

        let read_delta = log.get_delta(&delta.key)?;
        assert_eq!(delta, read_delta);

        let read_delta = pack.get_delta(&delta.key)?;
        assert_eq!(delta, read_delta);

        log.flush()?;
        pack.flush()?;
        Ok(())
    }

    #[test]
    fn test_history_add_static() -> Fallible<()> {
        let tempdir = TempDir::new()?;
        let mut pack = MutableHistoryPack::new(&tempdir, HistoryPackVersion::One)?;
        let mut multiplex = MultiplexHistoryStore::new();
        multiplex.add_store(Box::new(&mut pack));

        let k = key("a", "1");
        let nodeinfo = NodeInfo {
            parents: [key("a", "2"), key("a", "3")],
            linknode: node("4"),
        };

        multiplex.add(&k, &nodeinfo)?;
        drop(multiplex);

        let read_node = pack.get_node_info(&k)?;
        assert_eq!(nodeinfo, read_node);

        pack.flush()?;
        Ok(())
    }

    #[test]
    fn test_history_add_dynamic() -> Fallible<()> {
        let tempdir = TempDir::new()?;
        let mut pack1 = MutableHistoryPack::new(&tempdir, HistoryPackVersion::One)?;
        let mut pack2 = MutableHistoryPack::new(&tempdir, HistoryPackVersion::One)?;
        let mut multiplex = MultiplexHistoryStore::new();
        multiplex.add_store(Box::new(&mut pack1));
        multiplex.add_store(Box::new(&mut pack2));

        let k = key("a", "1");
        let nodeinfo = NodeInfo {
            parents: [key("a", "2"), key("a", "3")],
            linknode: node("4"),
        };

        multiplex.add(&k, &nodeinfo)?;
        drop(multiplex);

        let read_node = pack1.get_node_info(&k)?;
        assert_eq!(nodeinfo, read_node);

        let read_node = pack2.get_node_info(&k)?;
        assert_eq!(nodeinfo, read_node);

        pack1.flush()?;
        pack2.flush()?;
        Ok(())
    }
}
