import 'dart:ffi';
import 'dart:io';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart';

class git_error extends Struct {
  Pointer<Utf8> message;

  @Int32()
  int klass;
}

class _git_strarray extends Struct {
  Pointer<Pointer<Utf8>> strings;

  @Int64()
  int count;
}

class Libgit2 {
  // I don't really need this MethodChannel stuff since I don't need
  // interop with Java/Objective-C, but I'll keep it around anyway just
  // in case.
  static const MethodChannel _channel = const MethodChannel('libgit2');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static final DynamicLibrary nativeGit2 = Platform.isAndroid
      ? DynamicLibrary.open("libgit2.so")
      : DynamicLibrary.process();

  static final int Function() queryFeatures = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_libgit2_features")
      .asFunction();

  static final int Function() init = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_libgit2_init")
      .asFunction();

  static final int Function() shutdown = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_libgit2_shutdown")
      .asFunction();

  static final Pointer<git_error> Function() errorLast = nativeGit2
      .lookup<NativeFunction<Pointer<git_error> Function()>>("git_error_last")
      .asFunction();

  static final int Function(Pointer<Pointer<NativeType>>, Pointer<Utf8>, int)
      _repositoryInit = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<NativeType>>, Pointer<Utf8>,
                      Uint32)>>("git_repository_init")
          .asFunction();

  static final int Function(Pointer<Pointer<NativeType>>, Pointer<Utf8>)
      _repositoryOpen = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<NativeType>>,
                      Pointer<Utf8>)>>("git_repository_open")
          .asFunction();

  static final void Function(Pointer<NativeType>) _repositoryFree = nativeGit2
      .lookup<NativeFunction<Void Function(Pointer<NativeType>)>>(
          "git_repository_free")
      .asFunction();

  static final int Function(Pointer<Pointer<NativeType>>, Pointer<Utf8>,
          Pointer<Utf8>, Pointer<NativeType>) _clone =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<NativeType>>, Pointer<Utf8>,
                      Pointer<Utf8>, Pointer<NativeType>)>>("git_clone")
          .asFunction();

  static final int Function(Pointer<_git_strarray>) _strArrayDispose =
      nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<_git_strarray>)>>(
              "git_strarray_dispose")
          .asFunction();

  static final int Function(Pointer<_git_strarray>, Pointer<NativeType>)
      _remoteList = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<_git_strarray>,
                      Pointer<NativeType>)>>("git_remote_list")
          .asFunction();

  static final int Function(Pointer<NativeType>, int version)
      _git_fetch_options_init = nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<NativeType>, Int32)>>(
              "git_fetch_options_init")
          .asFunction();

  static final int Function(Pointer<NativeType>, int version)
      _git_push_options_init = nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<NativeType>, Int32)>>(
              "git_push_options_init")
          .asFunction();

  static final int Function() _git_fetch_options_size = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_fetch_options_size")
      .asFunction();

  static final int Function() _git_push_options_size = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_push_options_size")
      .asFunction();

  static final int Function() _git_fetch_options_version = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_fetch_options_version")
      .asFunction();

  static final int Function() _git_push_options_version = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_push_options_version")
      .asFunction();

  static final int Function(
          Pointer<Pointer<NativeType>>, Pointer<NativeType>, Pointer<Utf8>)
      _git_remote_lookup = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<NativeType>>,
                      Pointer<NativeType>, Pointer<Utf8>)>>("git_remote_lookup")
          .asFunction();

  static final int Function(Pointer<NativeType>) _git_remote_free = nativeGit2
      .lookup<NativeFunction<Int32 Function(Pointer<NativeType>)>>(
          "git_remote_free")
      .asFunction();

  static final int Function(Pointer<NativeType>, Pointer<_git_strarray>,
          Pointer<NativeType>, Pointer<Utf8>) _git_remote_fetch =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<NativeType>, Pointer<_git_strarray>,
                      Pointer<NativeType>, Pointer<Utf8>)>>("git_remote_fetch")
          .asFunction();

  static final int Function(
          Pointer<NativeType>, Pointer<_git_strarray>, Pointer<NativeType>)
      _git_remote_push = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<NativeType>, Pointer<_git_strarray>,
                      Pointer<NativeType>)>>("git_remote_push")
          .asFunction();

  /// Checks the return code for errors and if so, convert it to a thrown
  /// exception
  static int _checkErrors(int errorCode) {
    if (errorCode < 0) throw Libgit2Exception.fromErrorCode(errorCode);
    return errorCode;
  }

  static void initRepository(String dir) {
    Pointer<Pointer<NativeType>> repository = allocate<Pointer<NativeType>>();
    repository.value = nullptr;
    var dirPtr = Utf8.toUtf8(dir);
    try {
      _checkErrors(_repositoryInit(repository, dirPtr, 0));
    } finally {
      free(dirPtr);
      if (repository.value != nullptr) _repositoryFree(repository.value);
      free(repository);
    }
  }

  static void clone(String url, String dir) {
    Pointer<Pointer<NativeType>> repository = allocate<Pointer<NativeType>>();
    repository.value = nullptr;
    var dirPtr = Utf8.toUtf8(dir);
    var urlPtr = Utf8.toUtf8(url);
    try {
      _checkErrors(_clone(repository, urlPtr, dirPtr, nullptr));
    } finally {
      free(dirPtr);
      free(urlPtr);
      if (repository.value != nullptr) _repositoryFree(repository.value);
      free(repository);
    }
  }

  static T _withRepository<T>(String dir, T Function(Pointer<NativeType>) fn) {
    Pointer<Pointer<NativeType>> repository = allocate<Pointer<NativeType>>();
    repository.value = nullptr;
    var dirPtr = Utf8.toUtf8(dir);
    try {
      _checkErrors(_repositoryOpen(repository, dirPtr));
      return fn(repository.value);
    } finally {
      free(dirPtr);
      if (repository.value != nullptr) _repositoryFree(repository.value);
      free(repository);
    }
  }

  static T _withRepositoryAndRemote<T>(String dir, String remoteStr,
      T Function(Pointer<NativeType>, Pointer<NativeType>) fn) {
    Pointer<Pointer<NativeType>> remote = allocate<Pointer<NativeType>>();
    remote.value = nullptr;
    var remoteStrPtr = Utf8.toUtf8(remoteStr);
    try {
      return _withRepository(dir, (repo) {
        _checkErrors(_git_remote_lookup(remote, repo, remoteStrPtr));
        return fn(repo, remote.value);
      });
    } finally {
      free(remoteStrPtr);
      if (remote.value != nullptr) _git_remote_free(remote.value);
      free(remote);
    }
  }

  static List<String> remoteList(String dir) {
    Pointer<_git_strarray> remotesStrings = allocate<_git_strarray>();
    try {
      return _withRepository(dir, (repo) {
        _checkErrors(_remoteList(remotesStrings, repo));
        List<String> remotes = List();
        for (int n = 0; n < remotesStrings.ref.count; n++)
          remotes.add(Utf8.fromUtf8(remotesStrings.ref.strings[n]));
        _strArrayDispose(remotesStrings);
        return remotes;
      });
    } finally {
      free(remotesStrings);
    }
  }

  static void fetch(String dir, String remoteStr) {
    Pointer<NativeType> fetchOptions =
        allocate<Int8>(count: _git_fetch_options_size());
    try {
      return _withRepositoryAndRemote(dir, remoteStr, (repo, remote) {
        _checkErrors(_git_fetch_options_init(
            fetchOptions, _git_fetch_options_version()));
        _checkErrors(_git_remote_fetch(remote, nullptr, fetchOptions, nullptr));
      });
    } finally {
      free(fetchOptions);
    }
  }

  static void push(String dir, String remoteStr) {
    Pointer<NativeType> pushOptions =
        allocate<Int8>(count: _git_push_options_size());
    try {
      return _withRepositoryAndRemote(dir, remoteStr, (repo, remote) {
        _checkErrors(
            _git_push_options_init(pushOptions, _git_push_options_version()));
        _checkErrors(_git_remote_push(remote, nullptr, pushOptions));
      });
    } finally {
      free(pushOptions);
    }
  }
}

/// Packages up Libgit2 error code and error message in a single class
class Libgit2Exception implements Exception {
  String message;
  int errorCode;
  int klass;

  Libgit2Exception(this.errorCode, this.message, this.klass);

  Libgit2Exception.fromErrorCode(this.errorCode) {
    var err = Libgit2.errorLast();
    if (err != nullptr) {
      message = Utf8.fromUtf8(err.ref.message);
      klass = err.ref.klass;
    }
  }

  String toString() {
    if (message != null) return message + '($errorCode:$klass)';
    return 'Libgit2Exception($errorCode)';
  }
}
