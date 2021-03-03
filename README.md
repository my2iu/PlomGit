# PlomGit

A very basic Git client that runs on mobile devices. It is built on libgit2 and Flutter. 


### Alternative Git Engines Exploration

One limitation of libgit2 is that it uses the standard C APIs for writing files, making it difficult to adapt it to version control files outside the app using Android's Storage Access Framework or Apple's file providers. 

Eclipse's JGit was considered, but since it's programmed in Java, it's difficult to get it running on iOS. Isomorphic-git was also experimented with, but it was difficult getting it to run in embedded JavaScript interpreters and running it in a webview was deemed risky because of the poor performance of transferring data between a webview and system calls.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
