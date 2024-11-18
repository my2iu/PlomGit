# libgit2

Flutter plugin package for libgit2.

## To build 

This sub-project should build automatically when the parent PlomGit project is built. But to build it separately, you can go into the `examples` folder and build/run the project there.

Be sure to install the necessary libgit2 files before building:

### For iOS

For ios, enter the `libgit2/ios` directory. Then download the PlomGit iOS version of libgit2 using

```
git clone -b plomgit-ios --single-branch https://github.com/my2iu/plomgit-libgit2.git
```

### For Android

For Android, enter the `libgit2/android` directory. Then download the PlomGit Android version of libgit2 using

```
git clone -b plomgit-android --single-branch https://github.com/my2iu/plomgit-libgit2.git
```

## Rebuilding the ffi bindings

This plugin uses ffigen to automatically generate bindings from Flutter to the C++ library libgit2. If you need to generate new bindings, you can do so by following the instructions in the `ffigen` folder.