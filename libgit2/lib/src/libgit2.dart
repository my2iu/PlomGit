import 'dart:ffi';
import 'dart:io';
import 'dart:async';

import 'structs.dart';
import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart';

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

  static final int Function(
          Pointer<Pointer<git_repository>>, Pointer<Utf8>, int)
      _repositoryInit = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<git_repository>>,
                      Pointer<Utf8>, Uint32)>>("git_repository_init")
          .asFunction();

  static final int Function(Pointer<Pointer<git_repository>>, Pointer<Utf8>)
      _repositoryOpen = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<git_repository>>,
                      Pointer<Utf8>)>>("git_repository_open")
          .asFunction();

  static final void Function(Pointer<git_repository>) _repositoryFree =
      nativeGit2
          .lookup<NativeFunction<Void Function(Pointer<git_repository>)>>(
              "git_repository_free")
          .asFunction();

  static final int Function(Pointer<Pointer<git_repository>>, Pointer<Utf8>,
          Pointer<Utf8>, Pointer<NativeType>) _clone =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<git_repository>>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<NativeType>)>>("git_clone")
          .asFunction();

  static final int Function(Pointer<git_strarray>) _strArrayDispose = nativeGit2
      .lookup<NativeFunction<Int32 Function(Pointer<git_strarray>)>>(
          "git_strarray_dispose")
      .asFunction();

  static final int Function(Pointer<git_strarray>, Pointer<NativeType>)
      _remoteList = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_strarray>,
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

  static final void Function(Pointer<NativeType>,
          Pointer<NativeFunction<git_credentials_acquire_cb>>)
      _git_fetch_options_set_credentials_cb = nativeGit2
          .lookup<
                  NativeFunction<
                      Void Function(
                          Pointer<NativeType>,
                          Pointer<
                              NativeFunction<git_credentials_acquire_cb>>)>>(
              "git_fetch_options_set_credentials_cb")
          .asFunction();

  static final void Function(Pointer<NativeType>,
          Pointer<NativeFunction<git_credentials_acquire_cb>>)
      _git_push_options_set_credentials_cb = nativeGit2
          .lookup<
                  NativeFunction<
                      Void Function(
                          Pointer<NativeType>,
                          Pointer<
                              NativeFunction<git_credentials_acquire_cb>>)>>(
              "git_push_options_set_credentials_cb")
          .asFunction();

  static final int Function(
          Pointer<Pointer<git_remote>>, Pointer<git_repository>, Pointer<Utf8>)
      _git_remote_lookup = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<git_remote>>,
                      Pointer<git_repository>,
                      Pointer<Utf8>)>>("git_remote_lookup")
          .asFunction();

  static final int Function(Pointer<git_remote>) _git_remote_free = nativeGit2
      .lookup<NativeFunction<Int32 Function(Pointer<git_remote>)>>(
          "git_remote_free")
      .asFunction();

  static final int Function(Pointer<git_remote>, Pointer<git_strarray>,
          Pointer<NativeType>, Pointer<Utf8>) _git_remote_fetch =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_remote>, Pointer<git_strarray>,
                      Pointer<NativeType>, Pointer<Utf8>)>>("git_remote_fetch")
          .asFunction();

  static final int Function(
          Pointer<git_remote>, Pointer<git_strarray>, Pointer<NativeType>)
      _git_remote_push = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_remote>, Pointer<git_strarray>,
                      Pointer<NativeType>)>>("git_remote_push")
          .asFunction();

  static final int Function(Pointer<Pointer<git_status_list>>,
          Pointer<git_repository>, Pointer<NativeType>) _git_status_list_new =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<git_status_list>>,
                      Pointer<git_repository>,
                      Pointer<NativeType>)>>("git_status_list_new")
          .asFunction();

  static final void Function(Pointer<git_status_list>) _git_status_list_free =
      nativeGit2
          .lookup<NativeFunction<Void Function(Pointer<git_status_list>)>>(
              "git_status_list_free")
          .asFunction();

  static final int Function(Pointer<git_status_list>)
      _git_status_list_entrycount = nativeGit2
          .lookup<NativeFunction<IntPtr Function(Pointer<git_status_list>)>>(
              "git_status_list_entrycount")
          .asFunction();

  static final Pointer<git_status_entry> Function(Pointer<git_status_list>, int)
      _git_status_byindex = nativeGit2
          .lookup<
              NativeFunction<
                  Pointer<git_status_entry> Function(
                      Pointer<git_status_list>, IntPtr)>>("git_status_byindex")
          .asFunction();

  // The second parameter can be null or a pointer to a pointer of a string
  static final void Function(Pointer<NativeType>, Pointer<Pointer<Utf8>>)
      _git_status_options_config = nativeGit2
          .lookup<
              NativeFunction<
                  Void Function(Pointer<NativeType>,
                      Pointer<Pointer<Utf8>>)>>("git_status_options_config")
          .asFunction();

  static final int Function(
          Pointer<Pointer<git_credential>>, Pointer<Utf8>, Pointer<Utf8>)
      _git_credential_userpass_plaintext_new = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<git_credential>>,
                      Pointer<Utf8>,
                      Pointer<Utf8>)>>("git_credential_userpass_plaintext_new")
          .asFunction();

  /// Checks the return code for errors and if so, convert it to a thrown
  /// exception
  static int _checkErrors(int errorCode) {
    if (errorCode < 0) throw Libgit2Exception.fromErrorCode(errorCode);
    return errorCode;
  }

  static void initRepository(String dir) {
    Pointer<Pointer<git_repository>> repository =
        allocate<Pointer<git_repository>>();
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

  static void clone(String url, String dir, String username, String password) {
    credentialUsername = username;
    credentialPassword = password;
    Pointer<Pointer<git_repository>> repository =
        allocate<Pointer<git_repository>>();
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

  static T _withRepository<T>(
      String dir, T Function(Pointer<git_repository>) fn) {
    Pointer<Pointer<git_repository>> repository =
        allocate<Pointer<git_repository>>();
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
      T Function(Pointer<git_repository>, Pointer<git_remote>) fn) {
    Pointer<Pointer<git_remote>> remote = allocate<Pointer<git_remote>>();
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
    Pointer<git_strarray> remotesStrings = allocate<git_strarray>();
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

  static void fetch(
      String dir, String remoteStr, String username, String password) {
    credentialUsername = username;
    credentialPassword = password;
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

  // Since Dart is single-threaded, we can only have one libgit2 call
  // in-flight at once, so it's safe to store data needed for callbacks
  // in static variables
  static String lastUrlCredentialCheck = "";
  static String credentialUsername = "";
  static String credentialPassword = "";
  static int credentialsCallback(
      Pointer<Pointer<git_credential>> out,
      Pointer<Utf8> url,
      Pointer<Utf8> username_from_url,
      @Uint32() int allowed_type,
      Pointer<NativeType> payload) {
    // We don't interactively ask the user for a password, so if we
    // get asked for the password for the same page twice, we'll
    // abort instead of repeatedly retrying the same password.
    String currentUrl = Utf8.fromUtf8(url);
    if (currentUrl == lastUrlCredentialCheck) {
      return Libgit2Exception.GIT_PASSTHROUGH;
    }
    lastUrlCredentialCheck = currentUrl;

    if (credentialUsername.isEmpty && credentialPassword.isEmpty) {
      // No authentication credentials available, so ask the user for them
      return Libgit2Exception.GIT_EUSER;
    }

    // User and password combination
    if ((allowed_type & 1) != 0) {
      Pointer<Utf8> username = Utf8.toUtf8(credentialUsername);
      Pointer<Utf8> password = Utf8.toUtf8(credentialPassword);
      try {
        return _git_credential_userpass_plaintext_new(out, username, password);
      } finally {
        free(username);
        free(password);
      }
    }
    return Libgit2Exception.GIT_PASSTHROUGH;
  }

  static void push(
      String dir, String remoteStr, String username, String password) {
    credentialUsername = username;
    credentialPassword = password;
    Pointer<NativeType> pushOptions =
        allocate<Int8>(count: _git_push_options_size());
    try {
      return _withRepositoryAndRemote(dir, remoteStr, (repo, remote) {
        _checkErrors(
            _git_push_options_init(pushOptions, _git_push_options_version()));
        _git_push_options_set_credentials_cb(
            pushOptions,
            Pointer.fromFunction<git_credentials_acquire_cb>(
                credentialsCallback, Libgit2Exception.GIT_PASSTHROUGH));
        _checkErrors(_git_remote_push(remote, nullptr, pushOptions));
      });
    } finally {
      free(pushOptions);
    }
  }

  static dynamic status(String dir) {
    Pointer<NativeType> statusOptions =
        allocate<Int8>(count: _git_status_options_size());
    Pointer<Pointer<git_status_list>> statusList =
        allocate<Pointer<git_status_list>>();
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
          Pointer<git_status_entry> entry =
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

  // Some error codes
  static const int GIT_PASSTHROUGH = -30;
  static const int GIT_EUSER = -7;

  String toString() {
    if (message != null) return message + '($errorCode:$klass)';
    return 'Libgit2Exception($errorCode)';
  }
}
