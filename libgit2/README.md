# libgit2

Flutter plugin package for libgit2.

## To build 

Unzip the libgit2 1.1.0 source release into the ios/libgit2-1.1.0 folder.


For iOS only,

copy libgit2-overlay over top of libgit2-1.1.0 folder so that features.h and config.h get placed in the proper folders
modify src/xdiff/xpatience.c, replace all of "struct entry" to "struct xdiff_entry"
modify src/indexer.c, replace all of "struct entry" to "struct indexer_entry"
