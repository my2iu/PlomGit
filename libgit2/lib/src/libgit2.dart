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

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
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

  static final int Function(int, Pointer<Utf8>) _git_error_set_str = nativeGit2
      .lookup<NativeFunction<Int32 Function(Int32, Pointer<Utf8>)>>(
          "git_error_set_str")
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

  static final int Function(Pointer<git_repository>) _git_repository_state =
      nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<git_repository>)>>(
              "git_repository_state")
          .asFunction();

  static final int Function(Pointer<git_repository>)
      _git_repository_state_cleanup = nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<git_repository>)>>(
              "git_repository_state_cleanup")
          .asFunction();

  static final int Function(
          Pointer<git_repository>,
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer<git_oid>, Pointer<NativeType>)>>,
          Pointer<NativeType>) _git_repository_mergehead_foreach =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<git_repository>,
                      Pointer<
                          NativeFunction<
                              Int32 Function(
                                  Pointer<git_oid>, Pointer<NativeType>)>>,
                      Pointer<NativeType>)>>("git_repository_mergehead_foreach")
          .asFunction();

  static final void Function(Pointer<git_repository>) _repositoryFree =
      nativeGit2
          .lookup<NativeFunction<Void Function(Pointer<git_repository>)>>(
              "git_repository_free")
          .asFunction();

  static final int Function(Pointer<git_repository>)
      _git_repository_head_unborn = nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<git_repository>)>>(
              "git_repository_head_unborn")
          .asFunction();

  static final int Function(
          Pointer<Pointer<git_reference>>, Pointer<git_repository>)
      _git_repository_head = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<git_reference>>,
                      Pointer<git_repository>)>>("git_repository_head")
          .asFunction();

  static final int Function(Pointer<IntPtr>, Pointer<IntPtr>,
          Pointer<git_repository>, Pointer<git_oid>, Pointer<git_oid>)
      _git_graph_ahead_behind = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<IntPtr>,
                      Pointer<IntPtr>,
                      Pointer<git_repository>,
                      Pointer<git_oid>,
                      Pointer<git_oid>)>>("git_graph_ahead_behind")
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

  static final int Function(Pointer<git_strarray>) _strArrayDispose =
      nativeGit2
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

  static final int Function(Pointer<NativeType>, int version)
      _git_clone_options_init = nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<NativeType>, Int32)>>(
              "git_clone_options_init")
          .asFunction();

  static final int Function(Pointer<NativeType>, int version)
      _git_checkout_options_init = nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<NativeType>, Int32)>>(
              "git_checkout_options_init")
          .asFunction();

  static final int Function(Pointer<NativeType>, int version)
      _git_merge_options_init = nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<NativeType>, Int32)>>(
              "git_merge_options_init")
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

  static final int Function() _git_clone_options_size = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_clone_options_size")
      .asFunction();

  static final int Function() _git_checkout_options_size = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_checkout_options_size")
      .asFunction();

  static final int Function() _git_merge_options_size = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_merge_options_size")
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

  static final int Function() _git_clone_options_version = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_clone_options_version")
      .asFunction();

  static final int Function() _git_checkout_options_version = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_checkout_options_version")
      .asFunction();

  static final int Function() _git_merge_options_version = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_merge_options_version")
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

  static final void Function(Pointer<NativeType>,
          Pointer<NativeFunction<git_credentials_acquire_cb>>)
      _git_clone_options_set_credentials_cb = nativeGit2
          .lookup<
                  NativeFunction<
                      Void Function(
                          Pointer<NativeType>,
                          Pointer<
                              NativeFunction<git_credentials_acquire_cb>>)>>(
              "git_clone_options_set_credentials_cb")
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

  static final int Function(
          Pointer<Pointer<git_index>>, Pointer<git_repository>)
      _git_repository_index = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<git_index>>,
                      Pointer<git_repository>)>>("git_repository_index")
          .asFunction();

  static final int Function(Pointer<git_index>) _git_index_free = nativeGit2
      .lookup<NativeFunction<Int32 Function(Pointer<git_index>)>>(
          "git_index_free")
      .asFunction();

  static final int Function(Pointer<git_index>, Pointer<Utf8>)
      _git_index_add_bypath = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_index>,
                      Pointer<Utf8>)>>("git_index_add_bypath")
          .asFunction();

  static final int Function(Pointer<git_index>, Pointer<Utf8>)
      _git_index_remove_bypath = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_index>,
                      Pointer<Utf8>)>>("git_index_remove_bypath")
          .asFunction();

  static final int Function(Pointer<git_index>) _git_index_write = nativeGit2
      .lookup<NativeFunction<Int32 Function(Pointer<git_index>)>>(
          "git_index_write")
      .asFunction();

  static final int Function(Pointer<git_oid>, Pointer<git_index>)
      _git_index_write_tree = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_oid>,
                      Pointer<git_index>)>>("git_index_write_tree")
          .asFunction();

  static final int Function(
          Pointer<Pointer<git_tree>>, Pointer<git_repository>, Pointer<git_oid>)
      _git_tree_lookup = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<git_tree>>,
                      Pointer<git_repository>,
                      Pointer<git_oid>)>>("git_tree_lookup")
          .asFunction();

  static final int Function(
          Pointer<git_repository>, Pointer<NativeType>, Pointer<NativeType>)
      _git_checkout_tree = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_repository>, Pointer<NativeType>,
                      Pointer<NativeType>)>>("git_checkout_tree")
          .asFunction();

  static final int Function(Pointer<git_repository>, Pointer<NativeType>)
      _git_checkout_head = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_repository>,
                      Pointer<NativeType>)>>("git_checkout_head")
          .asFunction();

  // The second parameter can be null or a pointer to a pointer of a string
  static final void Function(Pointer<NativeType>, Pointer<Pointer<Utf8>>)
      _git_checkout_options_config_for_revert = nativeGit2
          .lookup<
                  NativeFunction<
                      Void Function(
                          Pointer<NativeType>, Pointer<Pointer<Utf8>>)>>(
              "git_checkout_options_config_for_revert")
          .asFunction();

  static final void Function(Pointer<NativeType>)
      _git_checkout_options_config_for_fastforward = nativeGit2
          .lookup<NativeFunction<Void Function(Pointer<NativeType>)>>(
              "git_checkout_options_config_for_fastforward")
          .asFunction();

  static final void Function(Pointer<NativeType>)
      _git_checkout_options_config_for_merge = nativeGit2
          .lookup<NativeFunction<Void Function(Pointer<NativeType>)>>(
              "git_checkout_options_config_for_merge")
          .asFunction();

  static final void Function(Pointer<git_tree>) _git_tree_free = nativeGit2
      .lookup<NativeFunction<Void Function(Pointer<git_tree>)>>("git_tree_free")
      .asFunction();

  static final Pointer<Utf8> Function(
      Pointer<
          git_reference>) _git_reference_name = nativeGit2
      .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<git_reference>)>>(
          "git_reference_name")
      .asFunction();

  static final int Function(
          Pointer<git_oid>, Pointer<git_repository>, Pointer<Utf8>)
      _git_reference_name_to_id = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_oid>, Pointer<git_repository>,
                      Pointer<Utf8>)>>("git_reference_name_to_id")
          .asFunction();

  static final int Function(Pointer<Pointer<git_reference>>,
          Pointer<git_reference>, Pointer<git_oid>, Pointer<Utf8>)
      _git_reference_set_target = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<git_reference>>,
                      Pointer<git_reference>,
                      Pointer<git_oid>,
                      Pointer<Utf8>)>>("git_reference_set_target")
          .asFunction();

  static final int Function(
          Pointer<Pointer<git_reference>>, Pointer<git_reference>)
      _git_reference_resolve = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<git_reference>>,
                      Pointer<git_reference>)>>("git_reference_resolve")
          .asFunction();

  static final Pointer<git_oid> Function(Pointer<git_reference>)
      _git_reference_target = nativeGit2
          .lookup<
              NativeFunction<
                  Pointer<git_oid> Function(
                      Pointer<git_reference>)>>("git_reference_target")
          .asFunction();

  static final int Function(Pointer<Pointer<git_commit>>,
          Pointer<git_repository>, Pointer<git_oid>) _git_commit_lookup =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<git_commit>>,
                      Pointer<git_repository>,
                      Pointer<git_oid>)>>("git_commit_lookup")
          .asFunction();

  static final void Function(Pointer<git_commit>) _git_commit_free = nativeGit2
      .lookup<NativeFunction<Void Function(Pointer<git_commit>)>>(
          "git_commit_free")
      .asFunction();

  static final int Function(
          Pointer<git_oid>,
          Pointer<git_repository>,
          Pointer<Utf8>,
          Pointer<git_signature>,
          Pointer<git_signature>,
          Pointer<Utf8>,
          Pointer<Utf8>,
          Pointer<git_tree>,
          int,
          Pointer<Pointer<git_commit>>) _git_commit_create =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<git_oid>,
                      Pointer<git_repository>,
                      Pointer<Utf8>,
                      Pointer<git_signature>,
                      Pointer<git_signature>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<git_tree>,
                      IntPtr,
                      Pointer<Pointer<git_commit>>)>>("git_commit_create")
          .asFunction();

  static final int Function(
          Pointer<Pointer<git_signature>>, Pointer<Utf8>, Pointer<Utf8>)
      _git_signature_now = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<git_signature>>, Pointer<Utf8>,
                      Pointer<Utf8>)>>("git_signature_now")
          .asFunction();

  static final void Function(Pointer<git_signature>) _git_signature_free =
      nativeGit2
          .lookup<NativeFunction<Void Function(Pointer<git_signature>)>>(
              "git_signature_free")
          .asFunction();

  static final int Function(Pointer<git_oid>, Pointer<git_oid>)
      _git_oid_cpy = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<git_oid>, Pointer<git_oid>)>>("git_oid_cpy")
          .asFunction();

  static final int Function(Pointer<Int32>, Pointer<Int32>,
          Pointer<git_repository>, Pointer<Pointer<NativeType>>, int)
      _git_merge_analysis = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Int32>,
                      Pointer<Int32>,
                      Pointer<git_repository>,
                      Pointer<Pointer<NativeType>>,
                      IntPtr)>>("git_merge_analysis")
          .asFunction();

  static final int Function(
          Pointer<git_repository>,
          Pointer<Pointer<git_annotated_commit>>,
          int,
          Pointer<NativeType>,
          Pointer<NativeType>) _git_merge =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<git_repository>,
                      Pointer<Pointer<git_annotated_commit>>,
                      IntPtr,
                      Pointer<NativeType>,
                      Pointer<NativeType>)>>("git_merge")
          .asFunction();

  static final int Function(Pointer<Pointer<git_annotated_commit>>,
          Pointer<git_repository>, Pointer<git_reference>)
      _git_annotated_commit_from_ref = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<git_annotated_commit>>,
                      Pointer<git_repository>,
                      Pointer<git_reference>)>>("git_annotated_commit_from_ref")
          .asFunction();

  static final Pointer<git_oid> Function(Pointer<git_annotated_commit>)
      _git_annotated_commit_id = nativeGit2
          .lookup<
                  NativeFunction<
                      Pointer<git_oid> Function(
                          Pointer<git_annotated_commit>)>>(
              "git_annotated_commit_id")
          .asFunction();

  static final void Function(Pointer<git_annotated_commit>)
      _git_annotated_commit_free = nativeGit2
          .lookup<NativeFunction<Void Function(Pointer<git_annotated_commit>)>>(
              "git_annotated_commit_free")
          .asFunction();

  static final int Function(Pointer<Pointer<git_reference>>,
          Pointer<git_repository>, Pointer<Utf8>) _git_reference_dwim =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<git_reference>>,
                      Pointer<git_repository>,
                      Pointer<Utf8>)>>("git_reference_dwim")
          .asFunction();

  static final int Function(
          Pointer<Pointer<git_reference>>, Pointer<git_reference>)
      _git_branch_upstream = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<git_reference>>,
                      Pointer<git_reference>)>>("git_branch_upstream")
          .asFunction();

  static final int Function(Pointer<Pointer<Utf8>>, Pointer<git_reference>)
      _git_branch_name = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<Utf8>>,
                      Pointer<git_reference>)>>("git_branch_name")
          .asFunction();

  static final void Function(Pointer<git_reference>) _git_reference_free =
      nativeGit2
          .lookup<NativeFunction<Void Function(Pointer<git_reference>)>>(
              "git_reference_free")
          .asFunction();

  static Pointer<git_buf> _allocateGitBuf() {
    Pointer<git_buf> buf = calloc<git_buf>();
    buf.ref.asize = 0;
    buf.ref.size = 0;
    buf.ref.ptr = nullptr;
    return buf;
  }

  static final void Function(Pointer<git_buf>) _git_buf_dispose = nativeGit2
      .lookup<NativeFunction<Void Function(Pointer<git_buf>)>>(
          "git_buf_dispose")
      .asFunction();

  /// Checks the return code for errors and if so, convert it to a thrown
  /// exception
  static int _checkErrors(int errorCode) {
    if (errorCode < 0) throw Libgit2Exception.fromErrorCode(errorCode);
    return errorCode;
  }

  static void initRepository(String dir) {
    Pointer<Pointer<git_repository>> repository =
        calloc<Pointer<git_repository>>();
    repository.value = nullptr;
    var dirPtr = dir.toNativeUtf8();
    try {
      _checkErrors(_repositoryInit(repository, dirPtr, 0));
    } finally {
      calloc.free(dirPtr);
      if (repository.value != nullptr) _repositoryFree(repository.value);
      calloc.free(repository);
    }
  }

  static void clone(String url, String dir, String username, String password) {
    setupCredentials(username, password);
    Pointer<Pointer<git_repository>> repository =
        calloc<Pointer<git_repository>>();
    repository.value = nullptr;
    Pointer<NativeType> cloneOptions =
        calloc.call<Int8>(_git_clone_options_size());
    var dirPtr = dir.toNativeUtf8();
    var urlPtr = url.toNativeUtf8();
    try {
      _checkErrors(
          _git_clone_options_init(cloneOptions, _git_clone_options_version()));
      _git_clone_options_set_credentials_cb(
          cloneOptions,
          Pointer.fromFunction<git_credentials_acquire_cb>(
              credentialsCallback, Libgit2Exception.GIT_PASSTHROUGH));
      _checkErrors(_clone(repository, urlPtr, dirPtr, cloneOptions));
    } finally {
      calloc.free(dirPtr);
      calloc.free(urlPtr);
      if (repository.value != nullptr) _repositoryFree(repository.value);
      calloc.free(repository);
      calloc.free(cloneOptions);
    }
  }

  static T _withRepository<T>(
      String dir, T Function(Pointer<git_repository>) fn) {
    Pointer<Pointer<git_repository>> repository =
        calloc<Pointer<git_repository>>();
    repository.value = nullptr;
    var dirPtr = dir.toNativeUtf8();
    try {
      _checkErrors(_repositoryOpen(repository, dirPtr));
      return fn(repository.value);
    } finally {
      calloc.free(dirPtr);
      if (repository.value != nullptr) _repositoryFree(repository.value);
      calloc.free(repository);
    }
  }

  static T _withRepositoryAndRemote<T>(String dir, String remoteStr,
      T Function(Pointer<git_repository>, Pointer<git_remote>) fn) {
    Pointer<Pointer<git_remote>> remote = calloc<Pointer<git_remote>>();
    remote.value = nullptr;
    var remoteStrPtr = remoteStr.toNativeUtf8();
    try {
      return _withRepository(dir, (repo) {
        _checkErrors(_git_remote_lookup(remote, repo, remoteStrPtr));
        return fn(repo, remote.value);
      });
    } finally {
      calloc.free(remoteStrPtr);
      if (remote.value != nullptr) _git_remote_free(remote.value);
      calloc.free(remote);
    }
  }

  static T _withRepositoryAndIndex<T>(
      String dir, T Function(Pointer<git_repository>, Pointer<git_index>) fn) {
    Pointer<Pointer<git_index>> index = calloc<Pointer<git_index>>();
    index.value = nullptr;
    try {
      return _withRepository(dir, (repo) {
        _checkErrors(_git_repository_index(index, repo));
        return fn(repo, index.value);
      });
    } finally {
      if (index.value != nullptr) _git_index_free(index.value);
      calloc.free(index);
    }
  }

  static List<String> remoteList(String dir) {
    Pointer<git_strarray> remotesStrings = calloc<git_strarray>();
    try {
      return _withRepository(dir, (repo) {
        _checkErrors(_remoteList(remotesStrings, repo));
        List<String> remotes = List();
        for (int n = 0; n < remotesStrings.ref.count; n++)
          remotes.add(remotesStrings.ref.strings[n].toDartString());
        _strArrayDispose(remotesStrings);
        return remotes;
      });
    } finally {
      calloc.free(remotesStrings);
    }
  }

  static void fetch(
      String dir, String remoteStr, String username, String password) {
    setupCredentials(username, password);
    Pointer<NativeType> fetchOptions =
        calloc.call<Int8>(_git_fetch_options_size());
    try {
      return _withRepositoryAndRemote(dir, remoteStr, (repo, remote) {
        _checkErrors(_git_fetch_options_init(
            fetchOptions, _git_fetch_options_version()));
        _git_fetch_options_set_credentials_cb(
            fetchOptions,
            Pointer.fromFunction<git_credentials_acquire_cb>(
                credentialsCallback, Libgit2Exception.GIT_PASSTHROUGH));
        _checkErrors(_git_remote_fetch(remote, nullptr, fetchOptions, nullptr));
      });
    } finally {
      calloc.free(fetchOptions);
    }
  }

  // Since Dart is single-threaded, we can only have one libgit2 call
  // in-flight at once, so it's safe to store data needed for callbacks
  // in static variables
  static String _lastUrlCredentialCheck = "";
  static String _credentialUsername = "";
  static String _credentialPassword = "";
  static int credentialsCallback(
      Pointer<Pointer<git_credential>> out,
      Pointer<Utf8> url,
      Pointer<Utf8> username_from_url,
      @Uint32() int allowed_type,
      Pointer<NativeType> payload) {
    // We don't interactively ask the user for a password, so if we
    // get asked for the password for the same page twice, we'll
    // abort instead of repeatedly retrying the same password.
    String currentUrl = url.toDartString();
    if (currentUrl == _lastUrlCredentialCheck) {
      Pointer<Utf8> msg = "Security credentials not accepted".toNativeUtf8();
      _git_error_set_str(0, msg);
      calloc.free(msg);
      return Libgit2Exception.GIT_EUSER;
    }
    _lastUrlCredentialCheck = currentUrl;

    if (_credentialUsername.isEmpty && _credentialPassword.isEmpty) {
      // No authentication credentials available, so ask the user for them
      return Libgit2Exception.GIT_EUSER;
    }

    // User and password combination
    if ((allowed_type & 1) != 0) {
      Pointer<Utf8> username = _credentialUsername.toNativeUtf8();
      Pointer<Utf8> password = _credentialPassword.toNativeUtf8();
      try {
        return _git_credential_userpass_plaintext_new(out, username, password);
      } finally {
        calloc.free(username);
        calloc.free(password);
      }
    }
    return Libgit2Exception.GIT_PASSTHROUGH;
  }

  static void setupCredentials(String username, String password) {
    _credentialUsername = username;
    _credentialPassword = password;
    _lastUrlCredentialCheck = "";
  }

  static void push(
      String dir, String remoteStr, String username, String password) {
    setupCredentials(username, password);
    Pointer<NativeType> pushOptions =
        calloc.call<Int8>(_git_push_options_size());
    Pointer<git_strarray> refStrings = calloc<git_strarray>();
    refStrings.ref.count = 1;
    refStrings.ref.strings = calloc.call<Pointer<Utf8>>(1);
    Pointer<Pointer<git_reference>> headRef = calloc<Pointer<git_reference>>();
    headRef.value = nullptr;
    try {
      return _withRepositoryAndRemote(dir, remoteStr, (repo, remote) {
        // Just push head to wherever for now
        _checkErrors(_git_repository_head(headRef, repo));
        refStrings.ref.strings[0] = _git_reference_name(headRef.value);

        _checkErrors(
            _git_push_options_init(pushOptions, _git_push_options_version()));
        _git_push_options_set_credentials_cb(
            pushOptions,
            Pointer.fromFunction<git_credentials_acquire_cb>(
                credentialsCallback, Libgit2Exception.GIT_PASSTHROUGH));
        _checkErrors(_git_remote_push(remote, refStrings, pushOptions));
      });
    } finally {
      calloc.free(pushOptions);
      if (headRef.value != nullptr) _git_reference_free(headRef.value);
      calloc.free(headRef);
      calloc.free(refStrings.ref.strings);
      calloc.free(refStrings);
    }
  }

  static dynamic status(String dir) {
    Pointer<NativeType> statusOptions =
        calloc.call<Int8>(_git_status_options_size());
    Pointer<Pointer<git_status_list>> statusList =
        calloc<Pointer<git_status_list>>();
    statusList.value = nullptr;
    // Pointer<Pointer<Utf8>> path = calloc.call<Pointer<Utf8>>( 1);
    // path.value = "*".toNativeUtf8();
    try {
      return _withRepository(dir, (repo) {
        _checkErrors(_git_status_options_init(
            statusOptions, _git_status_options_version()));
        _git_status_options_config(statusOptions, nullptr);
        _checkErrors(_git_status_list_new(statusList, repo, statusOptions));
        int numStatuses = _git_status_list_entrycount(statusList.value);
        if (numStatuses > 0) {
          var statusEntries = [];
          for (int n = 0; n < numStatuses; n++) {
            Pointer<git_status_entry> entry =
                _git_status_byindex(statusList.value, n);
            var entryData = [];
            if (entry.ref.index_to_workdir != nullptr &&
                entry.ref.index_to_workdir.ref.new_file_path != nullptr)
              entryData.add(
                  entry.ref.index_to_workdir.ref.new_file_path.toDartString());
            else
              entryData.add(null);
            if (entry.ref.head_to_index != nullptr &&
                entry.ref.head_to_index.ref.old_file_path != nullptr)
              entryData.add(
                  entry.ref.head_to_index.ref.old_file_path.toDartString());
            else
              entryData.add(null);
            entryData.add(entry.ref.status);
            statusEntries.add(entryData);
          }
          return statusEntries;
        }
        return [];
      });
    } finally {
      calloc.free(statusOptions);
      if (statusList.value != nullptr) _git_status_list_free(statusList.value);
      calloc.free(statusList);
      // calloc.free(path.value);
      // calloc.free(path);
    }
  }

  static void addToIndex(String dir, String file) {
    var filePtr = file.toNativeUtf8();
    try {
      _withRepositoryAndIndex(dir, (repo, index) {
        _checkErrors(_git_index_add_bypath(index, filePtr));
        _checkErrors(_git_index_write(index));
      });
    } finally {
      calloc.free(filePtr);
    }
  }

  static void removeFromIndex(String dir, String file) {
    var filePtr = file.toNativeUtf8();
    try {
      _withRepositoryAndIndex(dir, (repo, index) {
        _checkErrors(_git_index_remove_bypath(index, filePtr));
        _checkErrors(_git_index_write(index));
      });
    } finally {
      calloc.free(filePtr);
    }
  }

  // Since Dart is single-threaded, we can only have one libgit2 call
  // in-flight at once, so it's safe to store data needed for callbacks
  // in static variables
  static List<Pointer<git_oid> >? mergeHeadsFromCallback;
  static int mergeHeadsCallback(
      Pointer<git_oid> oid, Pointer<NativeType> payload) {
    Pointer<git_oid> newOid = calloc<git_oid>();
    _git_oid_cpy(newOid, oid);
    mergeHeadsFromCallback!.add(newOid);
    return 0;
  }

  static void commit(String dir, String message, String name, String email) {
    Pointer<git_oid> headOid = calloc<git_oid>();
    Pointer<git_oid> treeOid = calloc<git_oid>();
    Pointer<git_oid> finalCommitOid = calloc<git_oid>();
    Pointer<Utf8> headStr = "HEAD".toNativeUtf8();
    Pointer<Utf8> messageStr = message.toNativeUtf8();
    Pointer<Utf8> nameStr = name.toNativeUtf8();
    Pointer<Utf8> emailStr = email.toNativeUtf8();
    Pointer<Pointer<git_tree>> indexTree = calloc<Pointer<git_tree>>();
    indexTree.value = nullptr;
    int numParentCommits = 0;
    Pointer<Pointer<git_commit>> parentCommits = nullptr;
    Pointer<Pointer<git_signature>> authorSig =
        calloc<Pointer<git_signature>>();
    authorSig.value = nullptr;
    try {
      _withRepositoryAndIndex(dir, (repo, index) {
        // Check if we're in the middle of a merge
        int repoState = _git_repository_state(repo);
        // Figure out the different heads that we're merging
        mergeHeadsFromCallback = [];
        try {
          if (repoState == 1) {
            _git_repository_mergehead_foreach(
                repo,
                Pointer.fromFunction<
                        Int32 Function(Pointer<git_oid>, Pointer<NativeType>)>(
                    mergeHeadsCallback, 1),
                nullptr);
          }
          // Allocate parent commits
          numParentCommits = mergeHeadsFromCallback!.length + 1;
          parentCommits = calloc.call<Pointer<git_commit>>(numParentCommits);
          for (int n = 0; n < numParentCommits; n++) parentCommits[n] = nullptr;

          // Convert merge heads to annotated_commits
          for (int n = 0; n < mergeHeadsFromCallback!.length; n++) {
            _checkErrors(_git_commit_lookup(parentCommits.elementAt(n + 1),
                repo, mergeHeadsFromCallback![n]));
          }
        } finally {
          mergeHeadsFromCallback!.forEach((oid) {
            calloc.free(oid);
          });
          mergeHeadsFromCallback = null;
        }

        // Convert index to a tree
        _checkErrors(_git_index_write_tree(treeOid, index));
        _checkErrors(_git_tree_lookup(indexTree, repo, treeOid));

        // If the repository has no head, then this initial commit has nothing
        // to branch off of
        var hasNoHead = _git_repository_head_unborn(repo);
        _checkErrors(hasNoHead);
        if (hasNoHead == 0) {
          // Get head commit that we're branching off of
          _checkErrors(_git_reference_name_to_id(headOid, repo, headStr));
          _checkErrors(
              _git_commit_lookup(parentCommits.elementAt(0), repo, headOid));
        }

        // Use the same info for author and commiter signature
        _checkErrors(_git_signature_now(authorSig, nameStr, emailStr));

        // Perform the commit
        _checkErrors(_git_commit_create(
            finalCommitOid,
            repo,
            headStr,
            authorSig.value,
            authorSig.value,
            nullptr,
            messageStr,
            indexTree.value,
            numParentCommits,
            parentCommits));

        _checkErrors(_git_repository_state_cleanup(repo));
      });
    } finally {
      calloc.free(finalCommitOid);
      calloc.free(headOid);
      calloc.free(treeOid);
      calloc.free(headStr);
      if (indexTree.value != nullptr) _git_tree_free(indexTree.value);
      calloc.free(indexTree);
      if (parentCommits != nullptr) {
        for (int n = 0; n < numParentCommits; n++) {
          if (parentCommits[n] != nullptr) _git_commit_free(parentCommits[n]);
        }
        calloc.free(parentCommits);
      }
      calloc.free(messageStr);
      calloc.free(nameStr);
      calloc.free(emailStr);
      if (authorSig.value != nullptr) _git_signature_free(authorSig.value);
      calloc.free(authorSig);
    }
  }

  static void revertFile(String dir, String file) {
    var filePtr = file.toNativeUtf8();
    Pointer<NativeType> checkoutOptions =
        calloc.call<Int8>(_git_checkout_options_size());
    Pointer<Pointer<Utf8>> fileStrStr = calloc.call<Pointer<Utf8>>(1);
    fileStrStr[0] = file.toNativeUtf8();
    try {
      _withRepository(dir, (repo) {
        _checkErrors(_git_checkout_options_init(
            checkoutOptions, _git_checkout_options_version()));
        _git_checkout_options_config_for_revert(checkoutOptions, fileStrStr);
        _checkErrors(_git_checkout_head(repo, checkoutOptions));
      });
    } finally {
      calloc.free(checkoutOptions);
      calloc.free(filePtr);
      calloc.free(fileStrStr[0]);
      calloc.free(fileStrStr);
    }
  }

  static int _mergeAnalysis(Pointer<git_repository> repo,
      Pointer<Pointer<git_annotated_commit>> upstreamToMerge) {
    Pointer<Int32> mergeAnalysis = calloc<Int32>();
    mergeAnalysis.value = 0;
    Pointer<Int32> mergePreferences = calloc<Int32>();
    mergePreferences.value = 0;
    try {
      _checkErrors(_git_merge_analysis(
          mergeAnalysis, mergePreferences, repo, upstreamToMerge, 1));
      int toReturn = mergeAnalysis.value;
      return toReturn;
    } finally {
      calloc.free(mergeAnalysis);
      calloc.free(mergePreferences);
    }
  }

  static String mergeWithUpstream(
      String dir, String remoteStr, String username, String password) {
    setupCredentials(username, password);
    Pointer<Pointer<git_annotated_commit>> upstreamToMerge =
        calloc.call<Pointer<git_annotated_commit>>(1);
    upstreamToMerge.elementAt(0).value = nullptr;

    Pointer<Pointer<git_reference>> headRefToMergeWith =
        calloc<Pointer<git_reference>>();
    headRefToMergeWith.value = nullptr;
    Pointer<Utf8> headRefString = "HEAD".toNativeUtf8();
    Pointer<git_buf> buf = _allocateGitBuf();

    Pointer<Pointer<git_reference>> headRef = calloc<Pointer<git_reference>>();
    headRef.value = nullptr;
    Pointer<Pointer<git_reference>> upstreamRef =
        calloc<Pointer<git_reference>>();
    upstreamRef.value = nullptr;
    try {
      return _withRepository(dir, (repo) {
        _checkErrors(_git_repository_head(headRef, repo));
        _checkErrors(_git_branch_upstream(upstreamRef, headRef.value));
        _checkErrors(_git_annotated_commit_from_ref(
            upstreamToMerge.elementAt(0), repo, upstreamRef.value));
        int analysisResults = _mergeAnalysis(repo, upstreamToMerge);
        if ((analysisResults & 2) != 0) {
          return "Merge already up-to-date";
        } else if ((analysisResults & (8)) != 0) {
          return "No HEAD commit to merge";
        } else if ((analysisResults & (4)) != 0) {
          Pointer<git_oid> upstreamCommitId =
              _git_annotated_commit_id(upstreamToMerge[0]);
          Pointer<NativeType> checkoutOptions =
              calloc.call<Int8>(_git_checkout_options_size());
          Pointer<Pointer<git_commit>> upstreamCommit =
              calloc<Pointer<git_commit>>();
          upstreamCommit.value = nullptr;
          Pointer<Pointer<git_reference>> newHeadRef =
              calloc<Pointer<git_reference>>();
          newHeadRef.value = nullptr;
          try {
            // Get the commit to merge to
            _checkErrors(
                _git_commit_lookup(upstreamCommit, repo, upstreamCommitId));

            // Checkout upstream to fast-forward
            _checkErrors(_git_checkout_options_init(
                checkoutOptions, _git_checkout_options_version()));
            _git_checkout_options_config_for_fastforward(checkoutOptions);
            _checkErrors(_git_checkout_tree(
                repo, upstreamCommit.value, checkoutOptions));

            // Move HEAD
            _checkErrors(_git_reference_set_target(
                newHeadRef, headRef.value, upstreamCommitId, nullptr));
            return "Merge fast-forward";
          } finally {
            calloc.free(checkoutOptions);
            if (upstreamCommit.value != nullptr)
              _git_commit_free(upstreamCommit.value);
            calloc.free(upstreamCommit);
            if (newHeadRef.value != nullptr)
              _git_reference_free(newHeadRef.value);
            calloc.free(newHeadRef);
          }
        } else if ((analysisResults & 1) != 0) {
          Pointer<NativeType> checkoutOptions =
              calloc.call<Int8>(_git_checkout_options_size());
          Pointer<NativeType> mergeOptions =
              calloc.call<Int8>(_git_merge_options_size());

          try {
            _checkErrors(_git_checkout_options_init(
                checkoutOptions, _git_checkout_options_version()));
            _git_checkout_options_config_for_merge(checkoutOptions);
            _checkErrors(_git_merge_options_init(
                mergeOptions, _git_merge_options_version()));

            _checkErrors(_git_merge(
                repo, upstreamToMerge, 1, mergeOptions, checkoutOptions));

            return "Merge complete, please commit";
          } finally {
            calloc.free(checkoutOptions);
            calloc.free(mergeOptions);
          }
        }
        return "Cannot merge";
      });
    } finally {
      if (upstreamToMerge.value != nullptr)
        _git_annotated_commit_free(upstreamToMerge.value);
      calloc.free(upstreamToMerge);
      if (headRefToMergeWith.value != nullptr)
        _git_reference_free(headRefToMergeWith.value);
      calloc.free(headRefToMergeWith);
      calloc.free(headRefString);
      _git_buf_dispose(buf);
      calloc.free(buf);

      if (headRef.value != nullptr) _git_reference_free(headRef.value);
      calloc.free(headRef);
      if (upstreamRef.value != nullptr) _git_reference_free(upstreamRef.value);
      calloc.free(upstreamRef);
    }
  }

  static int repositoryState(String dir) {
    return _withRepository(dir, (repo) {
      return _git_repository_state(repo);
    });
  }

  static List<int> aheadBehind(String dir) {
    Pointer<IntPtr> ahead = calloc<IntPtr>();
    Pointer<IntPtr> behind = calloc<IntPtr>();
    Pointer<Pointer<git_reference>> headRef = calloc<Pointer<git_reference>>();
    headRef.value = nullptr;
    Pointer<Pointer<git_reference>> headDirectRef =
        calloc<Pointer<git_reference>>();
    headDirectRef.value = nullptr;
    Pointer<Pointer<git_reference>> upstreamRef =
        calloc<Pointer<git_reference>>();
    upstreamRef.value = nullptr;
    Pointer<Pointer<git_reference>> upstreamDirectRef =
        calloc<Pointer<git_reference>>();
    upstreamDirectRef.value = nullptr;

    try {
      return _withRepository(dir, (repo) {
        _checkErrors(_git_repository_head(headRef, repo));
        _checkErrors(_git_reference_resolve(headDirectRef, headRef.value));

        _checkErrors(_git_branch_upstream(upstreamRef, headRef.value));
        _checkErrors(
            _git_reference_resolve(upstreamDirectRef, upstreamRef.value));

        _checkErrors(_git_graph_ahead_behind(
            ahead,
            behind,
            repo,
            _git_reference_target(headDirectRef.value),
            _git_reference_target(upstreamDirectRef.value)));
        return <int>[ahead.value, behind.value];
      });
    } finally {
      calloc.free(ahead);
      calloc.free(behind);
      if (headRef.value != nullptr) _git_reference_free(headRef.value);
      calloc.free(headRef);
      if (headDirectRef.value != nullptr)
        _git_reference_free(headDirectRef.value);
      calloc.free(headDirectRef);
      if (upstreamRef.value != nullptr) _git_reference_free(upstreamRef.value);
      calloc.free(upstreamRef);
      if (upstreamDirectRef.value != nullptr)
        _git_reference_free(upstreamDirectRef.value);
      calloc.free(upstreamDirectRef);
    }
  }
}

/// Packages up Libgit2 error code and error message in a single class
class Libgit2Exception implements Exception {
  String? message;
  int? errorCode;
  int? klass;

  Libgit2Exception(this.errorCode, this.message, this.klass);

  Libgit2Exception.fromErrorCode(this.errorCode) {
    var err = Libgit2.errorLast();
    if (err != nullptr) {
      message = err.ref.message.toDartString();
      klass = err.ref.klass;
    }
  }

  // Some error codes
  static const int GIT_PASSTHROUGH = -30;
  static const int GIT_EUSER = -7;

  String toString() {
    if (message != null) return (message ?? "") + '($errorCode:$klass)';
    return 'Libgit2Exception($errorCode)';
  }
}
