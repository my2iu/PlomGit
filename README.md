# PlomGit

A very basic Git client that runs on mobile devices. It is built on libgit2 and Flutter. 

Packaged releases of PlomGit can be found through the [PlomGit webpage](https://www.plom.dev/plomgit/).

### Building

PlomGit requires you to download and patch the libgit2 library manually. Go into the libgit2 directory and follow the README.md instructions there about which version of libgit2 to download, where to put it, and how to patch it. You can also update the function interface and going into the libgit2/ffigen directory and follow the README.md instructions there for running ffigen.

To build on iOS, you might also need to separately run `pod install` in the `ios` directory (or maybe it's not necessary since I've checked it in). You possibly need to do this after running the libgit2/example flutter program. In any case, afterwards, just running `flutter run` should be enough to start things up.

### Alternative Git Engines Exploration

One limitation of libgit2 is that it uses the standard C APIs for writing files, making it difficult to adapt it to version control files outside the app using Android's Storage Access Framework or Apple's file providers. 

Eclipse's JGit was considered, but since it's programmed in Java, it's difficult to get it running on iOS. Isomorphic-git was also experimented with, but it was difficult getting it to run in embedded JavaScript interpreters and running it in a webview was deemed risky because of the poor performance of transferring data between a webview and system calls.

