This directory contains the configuration for running ffigen to generate the Flutter/Dart bindings needed to call the C functions of libgit2. This particular configuration is set for use on the Mac, so be sure to follow the instructions in `libgit2/README.md` for downloading libgit2 for the iOS version into the `libgit2/ios/plomgit-libgit2/` folder first. The ffigen configuration is configured to use the llvm that comes with MacOS Xcode, but the configuration can be changed to use a different llvm.

Run with

  dart run ffigen