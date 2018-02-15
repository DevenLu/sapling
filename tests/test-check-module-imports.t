#require test-repo

  $ . "$TESTDIR/helpers-testrepo.sh"
  $ import_checker="$TESTDIR"/../contrib/import-checker.py

  $ cd "$TESTDIR"/..

There are a handful of cases here that require renaming a module so it
doesn't overlap with a stdlib module name. There are also some cycles
here that we should still endeavor to fix, and some cycles will be
hidden by deduplication algorithm in the cycle detector, so fixing
these may expose other cycles.

Known-bad files are excluded by -X as some of them would produce unstable
outputs, which should be fixed later.

  $ testrepohg locate '**.py' 'tests/**.t' \
  > -I . \
  > -X hgweb.cgi \
  > -X setup.py \
  > -X contrib/debugshell.py \
  > -X contrib/hgweb.fcgi \
  > -X contrib/python-zstandard/ \
  > -X contrib/win32/hgwebdir_wsgi.py \
  > -X doc/gendoc.py \
  > -X doc/hgmanpage.py \
  > -X i18n/posplit \
  > -X mercurial/thirdparty \
  > -X tests/hypothesishelpers.py \
  > -X tests/test-commit-interactive.t \
  > -X tests/test-contrib-check-code.t \
  > -X tests/test-demandimport.py \
  > -X tests/test-extension.t \
  > -X tests/test-hghave.t \
  > -X tests/test-hgweb-auth.py \
  > -X tests/test-hgweb-no-path-info.t \
  > -X tests/test-hgweb-no-request-uri.t \
  > -X tests/test-hgweb-non-interactive.t \
  > -X tests/test-hook.t \
  > -X tests/test-import.t \
  > -X tests/test-imports-checker.t \
  > -X tests/test-lock.py \
  > -X tests/test-verify-repo-operations.py \
  > | sed 's-\\-/-g' | $PYTHON "$import_checker" -
  fb/facebook-hg-rpms/vendorcrates.py:14: imports not lexically sorted: collections < sys
  fb/packaging/nupkg_templates.py:7: relative import of stdlib module
  fb/packaging/nupkg_templates.py:7: direct symbol import Template from string
  hgext/age.py:21: imports not lexically sorted: re < time
  hgext/cleanobsstore.py:37: symbol import follows non-symbol import: mercurial.i18n
  hgext/conflictinfo.py:30: direct symbol import absentfilectx from mercurial.filemerge
  hgext/crdump.py:5: multiple imported names: json, re, shutil, tempfile
  hgext/crdump.py:6: relative import of stdlib module
  hgext/crdump.py:6: direct symbol import path from os
  hgext/crdump.py:16: symbol import follows non-symbol import: mercurial.i18n
  hgext/crdump.py:17: symbol import follows non-symbol import: mercurial.node
  hgext/dirsync.py:46: symbol import follows non-symbol import: mercurial.i18n
  hgext/fastannotate/revmap.py:16: symbol import follows non-symbol import: mercurial.node
  hgext/fastmanifest/cachemanager.py:10: imports not lexically sorted: errno < os
  hgext/fastmanifest/cachemanager.py:22: imports from hgext.fastmanifest not lexically sorted: concurrency < constants
  hgext/fastmanifest/cachemanager.py:23: direct symbol import metricscollector from hgext.fastmanifest.metrics
  hgext/fastmanifest/cachemanager.py:23: symbol import follows non-symbol import: hgext.fastmanifest.metrics
  hgext/fastmanifest/cachemanager.py:24: direct symbol import fastmanifestcache, CacheFullException from hgext.fastmanifest.implementation
  hgext/fastmanifest/cachemanager.py:24: symbol import follows non-symbol import: hgext.fastmanifest.implementation
  hgext/fastmanifest/cachemanager.py:24: imports from hgext.fastmanifest.implementation not lexically sorted: CacheFullException < fastmanifestcache
  hgext/fastmanifest/implementation.py:12: imports not lexically sorted: heapq < time
  hgext/fastmanifest/implementation.py:22: direct symbol import metricscollector from hgext.fastmanifest.metrics
  hgext/fastmanifest/implementation.py:22: symbol import follows non-symbol import: hgext.fastmanifest.metrics
  hgext/fastmanifest/implementation.py:23: direct symbol import CACHE_SUBDIR, DEFAULT_MAX_MEMORY_ENTRIES from hgext.fastmanifest.constants
  hgext/fastmanifest/implementation.py:23: symbol import follows non-symbol import: hgext.fastmanifest.constants
  hgext/fastmanifest/implementation.py:30: import should be relative: hgext
  hgext/fbamend/__init__.py:63: symbol import follows non-symbol import: mercurial.node
  hgext/fbamend/__init__.py:65: symbol import follows non-symbol import: mercurial.i18n
  hgext/fbamend/__init__.py:67: import should be relative: hgext
  hgext/fbamend/__init__.py:86: stdlib import "tempfile" follows local import: hgext.fbamend
  hgext/fbamend/common.py:10: relative import of stdlib module
  hgext/fbamend/common.py:10: direct symbol import defaultdict from collections
  hgext/fbamend/common.py:12: import should be relative: hgext
  hgext/fbamend/common.py:21: symbol import follows non-symbol import: mercurial.i18n
  hgext/fbamend/common.py:22: symbol import follows non-symbol import: mercurial.node
  hgext/fbamend/fold.py:23: symbol import follows non-symbol import: mercurial.i18n
  hgext/fbamend/hiddenoverride.py:10: import should be relative: hgext
  hgext/fbamend/hiddenoverride.py:12: symbol import follows non-symbol import: mercurial.node
  hgext/fbamend/hide.py:12: imports from mercurial not lexically sorted: extensions < hg
  hgext/fbamend/hide.py:22: symbol import follows non-symbol import: mercurial.i18n
  hgext/fbamend/metaedit.py:23: symbol import follows non-symbol import: mercurial.i18n
  hgext/fbamend/movement.py:10: relative import of stdlib module
  hgext/fbamend/movement.py:10: direct symbol import count from itertools
  hgext/fbamend/movement.py:21: symbol import follows non-symbol import: mercurial.i18n
  hgext/fbamend/movement.py:22: symbol import follows non-symbol import: mercurial.node
  hgext/fbamend/prune.py:14: imports from mercurial not lexically sorted: repair < util
  hgext/fbamend/prune.py:26: symbol import follows non-symbol import: mercurial.i18n
  hgext/fbamend/restack.py:16: import should be relative: hgext
  hgext/fbamend/split.py:25: symbol import follows non-symbol import: mercurial.i18n
  hgext/fbamend/unamend.py:17: symbol import follows non-symbol import: mercurial.i18n
  hgext/gitrevset.py:25: symbol import follows non-symbol import: mercurial.i18n
  hgext/gitrevset.py:26: stdlib import "re" follows local import: mercurial.i18n
  hgext/hiddenerror.py:28: symbol import follows non-symbol import: mercurial.i18n
  hgext/hiddenerror.py:29: symbol import follows non-symbol import: mercurial.node
  hgext/infinitepush/__init__.py:102: direct symbol import copiedpart, getscratchbranchparts, scratchbookmarksparttype, scratchbranchparttype from hgext.infinitepush.bundleparts
  hgext/infinitepush/__init__.py:108: imports from hgext.infinitepush not lexically sorted: common < infinitepushcommands
  hgext/infinitepush/__init__.py:113: relative import of stdlib module
  hgext/infinitepush/__init__.py:113: direct symbol import defaultdict from collections
  hgext/infinitepush/__init__.py:113: symbol import follows non-symbol import: collections
  hgext/infinitepush/__init__.py:114: relative import of stdlib module
  hgext/infinitepush/__init__.py:114: direct symbol import partial from functools
  hgext/infinitepush/__init__.py:114: symbol import follows non-symbol import: functools
  hgext/infinitepush/__init__.py:132: direct symbol import wrapcommand, wrapfunction, unwrapfunction from mercurial.extensions
  hgext/infinitepush/__init__.py:132: symbol import follows non-symbol import: mercurial.extensions
  hgext/infinitepush/__init__.py:132: imports from mercurial.extensions not lexically sorted: unwrapfunction < wrapfunction
  hgext/infinitepush/__init__.py:133: direct symbol import repository from mercurial.hg
  hgext/infinitepush/__init__.py:133: symbol import follows non-symbol import: mercurial.hg
  hgext/infinitepush/__init__.py:134: symbol import follows non-symbol import: mercurial.node
  hgext/infinitepush/__init__.py:135: symbol import follows non-symbol import: mercurial.i18n
  hgext/infinitepush/__init__.py:136: direct symbol import batchable, future from mercurial.peer
  hgext/infinitepush/__init__.py:136: symbol import follows non-symbol import: mercurial.peer
  hgext/infinitepush/__init__.py:137: direct symbol import encodelist, decodelist from mercurial.wireproto
  hgext/infinitepush/__init__.py:137: symbol import follows non-symbol import: mercurial.wireproto
  hgext/infinitepush/__init__.py:137: imports from mercurial.wireproto not lexically sorted: decodelist < encodelist
  hgext/infinitepush/backupcommands.py:52: direct symbol import getscratchbookmarkspart, getscratchbranchparts from hgext.infinitepush.bundleparts
  hgext/infinitepush/backupcommands.py:74: relative import of stdlib module
  hgext/infinitepush/backupcommands.py:74: direct symbol import defaultdict, namedtuple from collections
  hgext/infinitepush/backupcommands.py:74: symbol import follows non-symbol import: collections
  hgext/infinitepush/backupcommands.py:76: direct symbol import wrapfunction, unwrapfunction from mercurial.extensions
  hgext/infinitepush/backupcommands.py:76: symbol import follows non-symbol import: mercurial.extensions
  hgext/infinitepush/backupcommands.py:76: imports from mercurial.extensions not lexically sorted: unwrapfunction < wrapfunction
  hgext/infinitepush/backupcommands.py:77: symbol import follows non-symbol import: mercurial.node
  hgext/infinitepush/backupcommands.py:78: symbol import follows non-symbol import: mercurial.i18n
  hgext/infinitepush/backupcommands.py:82: relative import of stdlib module
  hgext/infinitepush/backupcommands.py:82: direct symbol import ConfigParser from ConfigParser
  hgext/infinitepush/backupcommands.py:82: symbol import follows non-symbol import: ConfigParser
  hgext/infinitepush/infinitepushcommands.py:18: direct symbol import cmdtable from hgext.infinitepush.backupcommands
  hgext/infinitepush/infinitepushcommands.py:31: direct symbol import downloadbundle from hgext.infinitepush.common
  hgext/infinitepush/infinitepushcommands.py:31: symbol import follows non-symbol import: hgext.infinitepush.common
  hgext/infinitepush/infinitepushcommands.py:32: symbol import follows non-symbol import: mercurial.node
  hgext/infinitepush/infinitepushcommands.py:33: symbol import follows non-symbol import: mercurial.i18n
  hgext/lz4revlog.py:76: relative import of stdlib module
  hgext/p4fastimport/__init__.py:35: imports from hgext.p4fastimport not lexically sorted: importer < p4
  hgext/p4fastimport/__init__.py:35: imports from hgext.p4fastimport not lexically sorted: filetransaction < importer
  hgext/p4fastimport/__init__.py:41: direct symbol import decodefileflags, getcl, lastcl, runworker from hgext.p4fastimport.util
  hgext/p4fastimport/__init__.py:41: symbol import follows non-symbol import: hgext.p4fastimport.util
  hgext/p4fastimport/__init__.py:43: symbol import follows non-symbol import: mercurial.i18n
  hgext/p4fastimport/__init__.py:44: symbol import follows non-symbol import: mercurial.node
  hgext/p4fastimport/__init__.py:44: imports from mercurial.node not lexically sorted: hex < short
  hgext/p4fastimport/importer.py:20: direct symbol import caseconflict, localpath, runworker from hgext.p4fastimport.util
  hgext/p4fastimport/importer.py:20: symbol import follows non-symbol import: hgext.p4fastimport.util
  hgext/p4fastimport/p4.py:10: direct symbol import runworker from hgext.p4fastimport.util
  hgext/pushrebase.py:27: multiple imported names: errno, os, tempfile, mmap, time
  hgext/pushrebase.py:49: direct symbol import wrapcommand, wrapfunction, unwrapfunction from mercurial.extensions
  hgext/pushrebase.py:49: symbol import follows non-symbol import: mercurial.extensions
  hgext/pushrebase.py:49: imports from mercurial.extensions not lexically sorted: unwrapfunction < wrapfunction
  hgext/pushrebase.py:50: symbol import follows non-symbol import: mercurial.node
  hgext/pushrebase.py:50: imports from mercurial.node not lexically sorted: hex < nullid
  hgext/pushrebase.py:50: imports from mercurial.node not lexically sorted: bin < hex
  hgext/pushrebase.py:51: symbol import follows non-symbol import: mercurial.i18n
  hgext/remotefilelog/__init__.py:72: symbol import follows non-symbol import: mercurial.node
  hgext/remotefilelog/__init__.py:73: symbol import follows non-symbol import: mercurial.i18n
  hgext/remotefilelog/__init__.py:74: direct symbol import wrapfunction from mercurial.extensions
  hgext/remotefilelog/__init__.py:74: symbol import follows non-symbol import: mercurial.extensions
  hgext/remotefilelog/__init__.py:103: stdlib import "os" follows local import: mercurial
  hgext/remotefilelog/__init__.py:104: stdlib import "time" follows local import: mercurial
  hgext/remotefilelog/__init__.py:105: stdlib import "traceback" follows local import: mercurial
  hgext/remotefilelog/basestore.py:3: multiple imported names: errno, hashlib, os, shutil, stat, time
  hgext/remotefilelog/basestore.py:15: symbol import follows non-symbol import: mercurial.i18n
  hgext/remotefilelog/basestore.py:16: symbol import follows non-symbol import: mercurial.node
  hgext/remotefilelog/cacheclient.py:15: multiple imported names: os, sys
  hgext/remotefilelog/constants.py:4: stdlib import "struct" follows local import: mercurial.i18n
  hgext/remotefilelog/contentstore.py:12: symbol import follows non-symbol import: mercurial.node
  hgext/remotefilelog/datapack.py:6: direct symbol import lz4compress, lz4decompress from hgext.remotefilelog.lz4wrapper
  hgext/remotefilelog/debugcommands.py:10: symbol import follows non-symbol import: mercurial.node
  hgext/remotefilelog/debugcommands.py:11: symbol import follows non-symbol import: mercurial.i18n
  hgext/remotefilelog/debugcommands.py:12: import should be relative: hgext
  hgext/remotefilelog/debugcommands.py:21: direct symbol import repacklockvfs from hgext.remotefilelog.repack
  hgext/remotefilelog/debugcommands.py:21: symbol import follows non-symbol import: hgext.remotefilelog.repack
  hgext/remotefilelog/debugcommands.py:22: direct symbol import lz4decompress from hgext.remotefilelog.lz4wrapper
  hgext/remotefilelog/debugcommands.py:22: symbol import follows non-symbol import: hgext.remotefilelog.lz4wrapper
  hgext/remotefilelog/debugcommands.py:23: multiple imported names: hashlib, os
  hgext/remotefilelog/debugcommands.py:23: stdlib import "hashlib" follows local import: hgext.remotefilelog.lz4wrapper
  hgext/remotefilelog/fileserverclient.py:10: multiple imported names: hashlib, os, time, io, struct
  hgext/remotefilelog/fileserverclient.py:15: imports from mercurial.node not lexically sorted: bin < hex
  hgext/remotefilelog/fileserverclient.py:30: direct symbol import unioncontentstore from hgext.remotefilelog.contentstore
  hgext/remotefilelog/fileserverclient.py:30: symbol import follows non-symbol import: hgext.remotefilelog.contentstore
  hgext/remotefilelog/fileserverclient.py:31: direct symbol import unionmetadatastore from hgext.remotefilelog.metadatastore
  hgext/remotefilelog/fileserverclient.py:31: symbol import follows non-symbol import: hgext.remotefilelog.metadatastore
  hgext/remotefilelog/fileserverclient.py:32: direct symbol import lz4decompress from hgext.remotefilelog.lz4wrapper
  hgext/remotefilelog/fileserverclient.py:32: symbol import follows non-symbol import: hgext.remotefilelog.lz4wrapper
  hgext/remotefilelog/historypack.py:2: multiple imported names: hashlib, struct
  hgext/remotefilelog/historypack.py:4: symbol import follows non-symbol import: mercurial.node
  hgext/remotefilelog/lz4wrapper.py:3: symbol import follows non-symbol import: mercurial.i18n
  hgext/remotefilelog/lz4wrapper.py:5: stdlib import "lz4" follows local import: mercurial.i18n
  hgext/remotefilelog/lz4wrapper.py:15: relative import of stdlib module
  hgext/remotefilelog/metadatastore.py:3: symbol import follows non-symbol import: mercurial.node
  hgext/remotefilelog/remotefilectx.py:13: imports from mercurial not lexically sorted: error < util
  hgext/remotefilelog/remotefilectx.py:13: imports from mercurial not lexically sorted: ancestor < error
  hgext/remotefilelog/remotefilectx.py:13: imports from mercurial not lexically sorted: extensions < phases
  hgext/remotefilelog/remotefilectx.py:25: import should be relative: hgext
  hgext/remotefilelog/remotefilelog.py:15: multiple imported names: collections, os
  hgext/remotefilelog/remotefilelog.py:15: stdlib import "collections" follows local import: hgext.remotefilelog
  hgext/remotefilelog/remotefilelog.py:16: symbol import follows non-symbol import: mercurial.node
  hgext/remotefilelog/remotefilelog.py:17: imports from mercurial not lexically sorted: mdiff < revlog
  hgext/remotefilelog/remotefilelog.py:17: imports from mercurial not lexically sorted: ancestor < mdiff
  hgext/remotefilelog/remotefilelog.py:18: symbol import follows non-symbol import: mercurial.i18n
  hgext/remotefilelog/remotefilelogserver.py:9: imports from mercurial not lexically sorted: changegroup < wireproto
  hgext/remotefilelog/remotefilelogserver.py:9: imports from mercurial not lexically sorted: changelog < util
  hgext/remotefilelog/remotefilelogserver.py:10: imports from mercurial not lexically sorted: error < store
  hgext/remotefilelog/remotefilelogserver.py:11: direct symbol import wrapfunction from mercurial.extensions
  hgext/remotefilelog/remotefilelogserver.py:11: symbol import follows non-symbol import: mercurial.extensions
  hgext/remotefilelog/remotefilelogserver.py:13: symbol import follows non-symbol import: mercurial.node
  hgext/remotefilelog/remotefilelogserver.py:14: symbol import follows non-symbol import: mercurial.i18n
  hgext/remotefilelog/remotefilelogserver.py:22: multiple imported names: errno, stat, os, time
  hgext/remotefilelog/remotefilelogserver.py:22: stdlib import "errno" follows local import: hgext.remotefilelog
  hgext/remotefilelog/repack.py:4: direct symbol import runshellcommand, flock from hgext.extutil
  hgext/remotefilelog/repack.py:4: imports from hgext.extutil not lexically sorted: flock < runshellcommand
  hgext/remotefilelog/repack.py:15: symbol import follows non-symbol import: mercurial.node
  hgext/remotefilelog/repack.py:19: symbol import follows non-symbol import: mercurial.i18n
  hgext/remotefilelog/repack.py:28: stdlib import "time" follows local import: hgext.remotefilelog
  hgext/remotefilelog/shallowbundle.py:10: stdlib import "os" follows local import: hgext.remotefilelog
  hgext/remotefilelog/shallowbundle.py:11: symbol import follows non-symbol import: mercurial.node
  hgext/remotefilelog/shallowbundle.py:12: imports from mercurial not lexically sorted: match < mdiff
  hgext/remotefilelog/shallowbundle.py:12: imports from mercurial not lexically sorted: bundlerepo < match
  hgext/remotefilelog/shallowbundle.py:13: imports from mercurial not lexically sorted: error < util
  hgext/remotefilelog/shallowbundle.py:14: symbol import follows non-symbol import: mercurial.i18n
  hgext/remotefilelog/shallowrepo.py:9: direct symbol import runshellcommand from hgext.extutil
  hgext/remotefilelog/shallowrepo.py:12: imports from mercurial not lexically sorted: match < util
  hgext/remotefilelog/shallowrepo.py:21: direct symbol import remotefilelogcontentstore, unioncontentstore from hgext.remotefilelog.contentstore
  hgext/remotefilelog/shallowrepo.py:21: symbol import follows non-symbol import: hgext.remotefilelog.contentstore
  hgext/remotefilelog/shallowrepo.py:22: direct symbol import remotecontentstore from hgext.remotefilelog.contentstore
  hgext/remotefilelog/shallowrepo.py:22: symbol import follows non-symbol import: hgext.remotefilelog.contentstore
  hgext/remotefilelog/shallowrepo.py:23: direct symbol import remotefilelogmetadatastore, unionmetadatastore from hgext.remotefilelog.metadatastore
  hgext/remotefilelog/shallowrepo.py:23: symbol import follows non-symbol import: hgext.remotefilelog.metadatastore
  hgext/remotefilelog/shallowrepo.py:24: direct symbol import remotemetadatastore from hgext.remotefilelog.metadatastore
  hgext/remotefilelog/shallowrepo.py:24: symbol import follows non-symbol import: hgext.remotefilelog.metadatastore
  hgext/remotefilelog/shallowrepo.py:25: direct symbol import datapackstore from hgext.remotefilelog.datapack
  hgext/remotefilelog/shallowrepo.py:25: symbol import follows non-symbol import: hgext.remotefilelog.datapack
  hgext/remotefilelog/shallowrepo.py:26: direct symbol import historypackstore from hgext.remotefilelog.historypack
  hgext/remotefilelog/shallowrepo.py:26: symbol import follows non-symbol import: hgext.remotefilelog.historypack
  hgext/remotefilelog/shallowrepo.py:28: stdlib import "os" follows local import: hgext.remotefilelog.historypack
  hgext/remotefilelog/shallowutil.py:*: multiple imported names: errno, hashlib, os, stat, struct, tempfile (glob)
  hgext/remotefilelog/shallowutil.py:*: relative import of stdlib module (glob)
  hgext/remotefilelog/shallowutil.py:*: direct symbol import defaultdict from collections (glob)
  hgext/remotefilelog/shallowutil.py:*: imports from mercurial not lexically sorted: error < util (glob)
  hgext/remotefilelog/shallowutil.py:*: symbol import follows non-symbol import: mercurial.node (glob)
  hgext/remotefilelog/shallowutil.py:*: symbol import follows non-symbol import: mercurial.i18n (glob)
  hgext/remotefilelog/wirepack.py:12: stdlib import "struct" follows local import: hgext.remotefilelog
  hgext/remotefilelog/wirepack.py:13: relative import of stdlib module
  hgext/remotefilelog/wirepack.py:13: direct symbol import StringIO from StringIO
  hgext/remotefilelog/wirepack.py:13: symbol import follows non-symbol import: StringIO
  hgext/remotefilelog/wirepack.py:14: relative import of stdlib module
  hgext/remotefilelog/wirepack.py:14: direct symbol import defaultdict from collections
  hgext/remotefilelog/wirepack.py:14: symbol import follows non-symbol import: collections
  hgext/remotefilelog/wirepack.py:16: direct symbol import readexactly, readunpack, mkstickygroupdir, readpath from hgext.remotefilelog.shallowutil
  hgext/remotefilelog/wirepack.py:16: symbol import follows non-symbol import: hgext.remotefilelog.shallowutil
  hgext/remotefilelog/wirepack.py:16: imports from hgext.remotefilelog.shallowutil not lexically sorted: mkstickygroupdir < readunpack
  hgext/remotefilelog/wirepack.py:17: multiple "from . import" statements
  hgext/treemanifest/__init__.py:*: symbol import follows non-symbol import: hgext.remotefilelog (glob)
  hgext/treemanifest/__init__.py:*: direct symbol import manifestrevlogstore, unioncontentstore from hgext.remotefilelog.contentstore (glob)
  hgext/treemanifest/__init__.py:*: symbol import follows non-symbol import: hgext.remotefilelog.contentstore (glob)
  hgext/treemanifest/__init__.py:*: direct symbol import unionmetadatastore from hgext.remotefilelog.metadatastore (glob)
  hgext/treemanifest/__init__.py:*: symbol import follows non-symbol import: hgext.remotefilelog.metadatastore (glob)
  hgext/treemanifest/__init__.py:*: direct symbol import datapack, datapackstore, mutabledatapack from hgext.remotefilelog.datapack (glob)
  hgext/treemanifest/__init__.py:*: symbol import follows non-symbol import: hgext.remotefilelog.datapack (glob)
  hgext/treemanifest/__init__.py:*: direct symbol import historypack, historypackstore, mutablehistorypack from hgext.remotefilelog.historypack (glob)
  hgext/treemanifest/__init__.py:*: symbol import follows non-symbol import: hgext.remotefilelog.historypack (glob)
  hgext/treemanifest/__init__.py:*: direct symbol import _computeincrementaldatapack, _computeincrementalhistorypack, _runrepack, _topacks, backgroundrepack from hgext.remotefilelog.repack (glob)
  hgext/treemanifest/__init__.py:*: symbol import follows non-symbol import: hgext.remotefilelog.repack (glob)
  hgext/tweakdefaults.py:69: imports from mercurial not lexically sorted: encoding < error
  hgext/tweakdefaults.py:88: stdlib import "inspect" follows local import: hgext
  hgext/tweakdefaults.py:89: stdlib import "json" follows local import: hgext
  hgext/tweakdefaults.py:90: stdlib import "os" follows local import: hgext
  hgext/tweakdefaults.py:91: stdlib import "re" follows local import: hgext
  hgext/tweakdefaults.py:92: stdlib import "shlex" follows local import: hgext
  hgext/tweakdefaults.py:93: stdlib import "subprocess" follows local import: hgext
  hgext/tweakdefaults.py:94: imports not lexically sorted: stat < subprocess
  hgext/tweakdefaults.py:94: stdlib import "stat" follows local import: hgext
  hgext/tweakdefaults.py:95: stdlib import "time" follows local import: hgext
  hgext/tweakdefaults.py:1058: multiple imported names: msvcrt, _subprocess
  hgext/undo.py:39: symbol import follows non-symbol import: mercurial.node
  tests/getflogheads.py:3: symbol import follows non-symbol import: mercurial.i18n
  tests/hghave.py:277: relative import of stdlib module
  tests/test-fb-hgext-cstore-datapackstore.py:13: direct symbol import datapackstore from hgext.extlib.cstore
  tests/test-fb-hgext-cstore-datapackstore.py:17: direct symbol import fastdatapack, mutabledatapack from hgext.remotefilelog.datapack
  tests/test-fb-hgext-cstore-datapackstore.py:23: imports not lexically sorted: mercurial.ui < silenttestrunner
  tests/test-fb-hgext-cstore-uniondatapackstore.py:12: direct symbol import datapackstore, uniondatapackstore from hgext.extlib.cstore
  tests/test-fb-hgext-cstore-uniondatapackstore.py:17: direct symbol import datapack, mutabledatapack from hgext.remotefilelog.datapack
  tests/test-fb-hgext-cstore-uniondatapackstore.py:23: symbol import follows non-symbol import: mercurial.node
  tests/test-fb-hgext-cstore-uniondatapackstore.py:24: imports not lexically sorted: mercurial.ui < silenttestrunner
  tests/test-fb-hgext-remotefilelog-datapack.py:16: direct symbol import datapack, datapackstore, fastdatapack, mutabledatapack from hgext.remotefilelog.datapack
  tests/test-fb-hgext-remotefilelog-datapack.py:22: direct symbol import SMALLFANOUTCUTOFF, SMALLFANOUTPREFIX, LARGEFANOUTPREFIX from hgext.remotefilelog.basepack
  tests/test-fb-hgext-remotefilelog-datapack.py:22: imports from hgext.remotefilelog.basepack not lexically sorted: LARGEFANOUTPREFIX < SMALLFANOUTPREFIX
  tests/test-fb-hgext-remotefilelog-datapack.py:29: symbol import follows non-symbol import: mercurial.node
  tests/test-fb-hgext-remotefilelog-datapack.py:30: imports not lexically sorted: mercurial.ui < silenttestrunner
  tests/test-fb-hgext-remotefilelog-histpack.py:15: direct symbol import historypack, mutablehistorypack from hgext.remotefilelog.historypack
  tests/test-fb-hgext-remotefilelog-histpack.py:18: imports not lexically sorted: mercurial.ui < silenttestrunner
  tests/test-fb-hgext-remotefilelog-histpack.py:20: direct symbol import SMALLFANOUTCUTOFF, LARGEFANOUTPREFIX from hgext.remotefilelog.basepack
  tests/test-fb-hgext-remotefilelog-histpack.py:20: imports from hgext.remotefilelog.basepack not lexically sorted: LARGEFANOUTPREFIX < SMALLFANOUTCUTOFF
  [1]
