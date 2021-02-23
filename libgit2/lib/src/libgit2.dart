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

  @IntPtr()
  int count;
}

class _git_diff_file extends Struct {
  @Int64()
  int id_0; // Should be a 20 bytes git_oid
  @Int64()
  int id_1;
  @Int32()
  int id_2;

  Pointer<Utf8> path;

  @Int64()
  int size;

  @Uint32()
  int flags;

  @Uint16()
  int mode;

  @Uint16()
  int id_abbrev;
}

class _git_diff_delta extends Struct {
  @Int32()
  int status;

  @Uint32()
  int flags;

  @Uint16()
  int similarity;

  @Uint16()
  int nfiles;

  // (this should be a nested struct)
  @Int64()
  int old_file_id_0; // Should be a 20 bytes git_oid
  @Int64()
  int old_file_id_1;
  @Int32()
  int old_file_id_2;

  Pointer<Utf8> old_file_path;

  @Int64()
  int old_file_size;

  @Uint32()
  int old_file_flags;

  @Uint16()
  int old_file_mode;

  @Uint16()
  int old_file_id_abbrev;

  // (this should be a nested struct)
  @Int64()
  int new_file_id_0; // Should be a 20 bytes git_oid
  @Int64()
  int new_file_id_1;
  @Int32()
  int new_file_id_2;

  Pointer<Utf8> new_file_path;

  @Int64()
  int new_file_size;

  @Uint32()
  int new_file_flags;

  @Uint16()
  int new_file_mode;

  @Uint16()
  int new_file_id_abbrev;
}

class _git_status_entry extends Struct {
  @Int32()
  int status;

  Pointer<_git_diff_delta> head_to_index;
  Pointer<_git_diff_delta> index_to_workdir;

  // GIT_STATUS_CURRENT = 0,

  // GIT_STATUS_INDEX_NEW        = (1u << 0),
  // GIT_STATUS_INDEX_MODIFIED   = (1u << 1),
  // GIT_STATUS_INDEX_DELETED    = (1u << 2),
  // GIT_STATUS_INDEX_RENAMED    = (1u << 3),
  // GIT_STATUS_INDEX_TYPECHANGE = (1u << 4),

  // GIT_STATUS_WT_NEW           = (1u << 7),
  // GIT_STATUS_WT_MODIFIED      = (1u << 8),
  // GIT_STATUS_WT_DELETED       = (1u << 9),
  // GIT_STATUS_WT_TYPECHANGE    = (1u << 10),
  // GIT_STATUS_WT_RENAMED       = (1u << 11),
  // GIT_STATUS_WT_UNREADABLE    = (1u << 12),

  // GIT_STATUS_IGNORED          = (1u << 14),
  // GIT_STATUS_CONFLICTED       = (1u << 15),
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

  static final int Function(Pointer<NativeType>, int version)
      _git_status_options_init = nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<NativeType>, Int32)>>(
              "git_status_options_init")
          .asFunction();

  static final int Function() _git_fetch_options_size = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_fetch_options_size")
      .asFunction();

  static final int Function() _git_push_options_size = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_push_options_size")
      .asFunction();

  static final int Function() _git_status_options_size = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_status_options_size")
      .asFunction();

  static final int Function() _git_fetch_options_version = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_fetch_options_version")
      .asFunction();

  static final int Function() _git_push_options_version = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_push_options_version")
      .asFunction();

  static final int Function() _git_status_options_version = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_status_options_version")
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

  static final int Function(Pointer<Pointer<NativeType>>, Pointer<NativeType>,
          Pointer<NativeType>) _git_status_list_new =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<NativeType>>,
                      Pointer<NativeType>,
                      Pointer<NativeType>)>>("git_status_list_new")
          .asFunction();

  static final void Function(Pointer<NativeType>) _git_status_list_free =
      nativeGit2
          .lookup<NativeFunction<Void Function(Pointer<NativeType>)>>(
              "git_status_list_free")
          .asFunction();

  static final int Function(Pointer<NativeType>) _git_status_list_entrycount =
      nativeGit2
          .lookup<NativeFunction<IntPtr Function(Pointer<NativeType>)>>(
              "git_status_list_entrycount")
          .asFunction();

  static final Pointer<_git_status_entry> Function(Pointer<NativeType>, int)
      _git_status_byindex = nativeGit2
          .lookup<
              NativeFunction<
                  Pointer<_git_status_entry> Function(
                      Pointer<NativeType>, IntPtr)>>("git_status_byindex")
          .asFunction();

  // The second parameter can be null or a pointer to a pointer of a string
  static final void Function(Pointer<NativeType>, Pointer<Pointer<Utf8>>)
      _git_status_options_config = nativeGit2
          .lookup<
              NativeFunction<
                  Void Function(Pointer<NativeType>,
                      Pointer<Pointer<Utf8>>)>>("git_status_options_config")
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

  static dynamic status(String dir) {
    Pointer<NativeType> statusOptions =
        allocate<Int8>(count: _git_status_options_size());
    Pointer<Pointer<NativeType>> statusList = allocate<Pointer<NativeType>>();
    statusList.value = nullptr;
    // Pointer<Pointer<Utf8>> path = allocate<Pointer<Utf8>>(count: 1);
    // path.value = Utf8.toUtf8("*");
    try {
      return _withRepository(dir, (repo) {
        _checkErrors(_git_status_options_init(
            statusOptions, _git_status_options_version()));
        _git_status_options_config(statusOptions, nullptr);
        _checkErrors(_git_status_list_new(statusList, repo, statusOptions));
        int numStatuses = _git_status_list_entrycount(statusList.value);
        print(numStatuses);
        if (numStatuses > 0) {
          int n = 0;
          Pointer<_git_status_entry> entry =
              _git_status_byindex(statusList.value, n);
          print(entry.ref.status);
          print(entry.ref.head_to_index);
          print(entry.ref.head_to_index.ref.nfiles);
          print(Utf8.fromUtf8(entry.ref.head_to_index.ref.new_file_path));
        }
        return "";
      });
    } finally {
      free(statusOptions);
      if (statusList.value != nullptr) _git_status_list_free(statusList.value);
      free(statusList);
      // free(path.value);
      // free(path);
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
