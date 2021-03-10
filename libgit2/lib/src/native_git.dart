import 'dart:ffi';
import 'dart:io';

import 'structs.dart';
import 'package:ffi/ffi.dart';

class git {
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

  static final int Function(int, Pointer<Utf8>) error_set_str = nativeGit2
      .lookup<NativeFunction<Int32 Function(Int32, Pointer<Utf8>)>>(
          "git_error_set_str")
      .asFunction();

  static final int Function(
          Pointer<Pointer<git_repository>>, Pointer<Utf8>, int) repositoryInit =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<git_repository>>,
                      Pointer<Utf8>, Uint32)>>("git_repository_init")
          .asFunction();

  static final int Function(Pointer<Pointer<git_repository>>, Pointer<Utf8>)
      repositoryOpen = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<git_repository>>,
                      Pointer<Utf8>)>>("git_repository_open")
          .asFunction();

  static final int Function(Pointer<git_repository>) repository_state =
      nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<git_repository>)>>(
              "git_repository_state")
          .asFunction();

  static final int Function(Pointer<git_repository>) repository_state_cleanup =
      nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<git_repository>)>>(
              "git_repository_state_cleanup")
          .asFunction();

  static final int Function(
          Pointer<git_repository>,
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer<git_oid>, Pointer<NativeType>)>>,
          Pointer<NativeType>) repository_mergehead_foreach =
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

  static final void Function(Pointer<git_repository>) repositoryFree =
      nativeGit2
          .lookup<NativeFunction<Void Function(Pointer<git_repository>)>>(
              "git_repository_free")
          .asFunction();

  static final int Function(Pointer<git_repository>) repository_head_unborn =
      nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<git_repository>)>>(
              "git_repository_head_unborn")
          .asFunction();

  static final int Function(
          Pointer<Pointer<git_reference>>, Pointer<git_repository>)
      repository_head = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<git_reference>>,
                      Pointer<git_repository>)>>("git_repository_head")
          .asFunction();

  static final int Function(Pointer<IntPtr>, Pointer<IntPtr>,
          Pointer<git_repository>, Pointer<git_oid>, Pointer<git_oid>)
      graph_ahead_behind = nativeGit2
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
          Pointer<Utf8>, Pointer<NativeType>) clone =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<git_repository>>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<NativeType>)>>("git_clone")
          .asFunction();

  static final int Function(Pointer<git_strarray>) strArrayDispose = nativeGit2
      .lookup<NativeFunction<Int32 Function(Pointer<git_strarray>)>>(
          "git_strarray_dispose")
      .asFunction();

  static final int Function(Pointer<git_strarray>, Pointer<NativeType>)
      remoteList = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_strarray>,
                      Pointer<NativeType>)>>("git_remote_list")
          .asFunction();

  static final int Function(Pointer<NativeType>, int version)
      fetch_options_init = nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<NativeType>, Int32)>>(
              "git_fetch_options_init")
          .asFunction();

  static final int Function(Pointer<NativeType>, int version)
      push_options_init = nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<NativeType>, Int32)>>(
              "git_push_options_init")
          .asFunction();

  static final int Function(Pointer<NativeType>, int version)
      status_options_init = nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<NativeType>, Int32)>>(
              "git_status_options_init")
          .asFunction();

  static final int Function(Pointer<NativeType>, int version)
      clone_options_init = nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<NativeType>, Int32)>>(
              "git_clone_options_init")
          .asFunction();

  static final int Function(Pointer<NativeType>, int version)
      checkout_options_init = nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<NativeType>, Int32)>>(
              "git_checkout_options_init")
          .asFunction();

  static final int Function(Pointer<NativeType>, int version)
      merge_options_init = nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<NativeType>, Int32)>>(
              "git_merge_options_init")
          .asFunction();

  static final int Function() fetch_options_size = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_fetch_options_size")
      .asFunction();

  static final int Function() push_options_size = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_push_options_size")
      .asFunction();

  static final int Function() status_options_size = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_status_options_size")
      .asFunction();

  static final int Function() clone_options_size = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_clone_options_size")
      .asFunction();

  static final int Function() checkout_options_size = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_checkout_options_size")
      .asFunction();

  static final int Function() merge_options_size = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_merge_options_size")
      .asFunction();

  static final int Function() fetch_options_version = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_fetch_options_version")
      .asFunction();

  static final int Function() push_options_version = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_push_options_version")
      .asFunction();

  static final int Function() status_options_version = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_status_options_version")
      .asFunction();

  static final int Function() clone_options_version = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_clone_options_version")
      .asFunction();

  static final int Function() checkout_options_version = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_checkout_options_version")
      .asFunction();

  static final int Function() merge_options_version = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>("git_merge_options_version")
      .asFunction();

  static final void Function(Pointer<NativeType>,
          Pointer<NativeFunction<git_credentials_acquire_cb>>)
      fetch_options_set_credentials_cb = nativeGit2
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
      push_options_set_credentials_cb = nativeGit2
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
      clone_options_set_credentials_cb = nativeGit2
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
      remote_lookup = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<git_remote>>,
                      Pointer<git_repository>,
                      Pointer<Utf8>)>>("git_remote_lookup")
          .asFunction();

  static final int Function(Pointer<git_remote>) remote_free = nativeGit2
      .lookup<NativeFunction<Int32 Function(Pointer<git_remote>)>>(
          "git_remote_free")
      .asFunction();

  static final int Function(Pointer<git_remote>, Pointer<git_strarray>,
          Pointer<NativeType>, Pointer<Utf8>) remote_fetch =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_remote>, Pointer<git_strarray>,
                      Pointer<NativeType>, Pointer<Utf8>)>>("git_remote_fetch")
          .asFunction();

  static final int Function(
          Pointer<git_remote>, Pointer<git_strarray>, Pointer<NativeType>)
      remote_push = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_remote>, Pointer<git_strarray>,
                      Pointer<NativeType>)>>("git_remote_push")
          .asFunction();

  static final int Function(Pointer<Pointer<git_status_list>>,
          Pointer<git_repository>, Pointer<NativeType>) status_list_new =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<git_status_list>>,
                      Pointer<git_repository>,
                      Pointer<NativeType>)>>("git_status_list_new")
          .asFunction();

  static final void Function(Pointer<git_status_list>) status_list_free =
      nativeGit2
          .lookup<NativeFunction<Void Function(Pointer<git_status_list>)>>(
              "git_status_list_free")
          .asFunction();

  static final int Function(Pointer<git_status_list>) status_list_entrycount =
      nativeGit2
          .lookup<NativeFunction<IntPtr Function(Pointer<git_status_list>)>>(
              "git_status_list_entrycount")
          .asFunction();

  static final Pointer<git_status_entry> Function(Pointer<git_status_list>, int)
      status_byindex = nativeGit2
          .lookup<
              NativeFunction<
                  Pointer<git_status_entry> Function(
                      Pointer<git_status_list>, IntPtr)>>("git_status_byindex")
          .asFunction();

  // The second parameter can be null or a pointer to a pointer of a string
  static final void Function(Pointer<NativeType>, Pointer<Pointer<Utf8>>)
      status_options_config = nativeGit2
          .lookup<
              NativeFunction<
                  Void Function(Pointer<NativeType>,
                      Pointer<Pointer<Utf8>>)>>("git_status_options_config")
          .asFunction();

  static final int Function(
          Pointer<Pointer<git_credential>>, Pointer<Utf8>, Pointer<Utf8>)
      credential_userpass_plaintext_new = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<git_credential>>,
                      Pointer<Utf8>,
                      Pointer<Utf8>)>>("git_credential_userpass_plaintext_new")
          .asFunction();

  static final int Function(
          Pointer<Pointer<git_index>>, Pointer<git_repository>)
      repository_index = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<git_index>>,
                      Pointer<git_repository>)>>("git_repository_index")
          .asFunction();

  static final int Function(Pointer<git_index>) index_free = nativeGit2
      .lookup<NativeFunction<Int32 Function(Pointer<git_index>)>>(
          "git_index_free")
      .asFunction();

  static final int Function(Pointer<git_index>, Pointer<Utf8>)
      index_add_bypath = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_index>,
                      Pointer<Utf8>)>>("git_index_add_bypath")
          .asFunction();

  static final int Function(Pointer<git_index>, Pointer<Utf8>)
      index_remove_bypath = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_index>,
                      Pointer<Utf8>)>>("git_index_remove_bypath")
          .asFunction();

  static final int Function(Pointer<git_index>) index_write = nativeGit2
      .lookup<NativeFunction<Int32 Function(Pointer<git_index>)>>(
          "git_index_write")
      .asFunction();

  static final int Function(Pointer<git_oid>, Pointer<git_index>)
      index_write_tree = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_oid>,
                      Pointer<git_index>)>>("git_index_write_tree")
          .asFunction();

  static final int Function(
          Pointer<Pointer<git_tree>>, Pointer<git_repository>, Pointer<git_oid>)
      tree_lookup = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<git_tree>>,
                      Pointer<git_repository>,
                      Pointer<git_oid>)>>("git_tree_lookup")
          .asFunction();

  static final int Function(
          Pointer<git_repository>, Pointer<NativeType>, Pointer<NativeType>)
      checkout_tree = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_repository>, Pointer<NativeType>,
                      Pointer<NativeType>)>>("git_checkout_tree")
          .asFunction();

  static final int Function(Pointer<git_repository>, Pointer<NativeType>)
      checkout_head = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_repository>,
                      Pointer<NativeType>)>>("git_checkout_head")
          .asFunction();

  // The second parameter can be null or a pointer to a pointer of a string
  static final void Function(Pointer<NativeType>, Pointer<Pointer<Utf8>>)
      checkout_options_config_for_revert = nativeGit2
          .lookup<
                  NativeFunction<
                      Void Function(
                          Pointer<NativeType>, Pointer<Pointer<Utf8>>)>>(
              "git_checkout_options_config_for_revert")
          .asFunction();

  static final void Function(Pointer<NativeType>)
      checkout_options_config_for_fastforward = nativeGit2
          .lookup<NativeFunction<Void Function(Pointer<NativeType>)>>(
              "git_checkout_options_config_for_fastforward")
          .asFunction();

  static final void Function(Pointer<NativeType>)
      checkout_options_config_for_merge = nativeGit2
          .lookup<NativeFunction<Void Function(Pointer<NativeType>)>>(
              "git_checkout_options_config_for_merge")
          .asFunction();

  static final void Function(Pointer<git_tree>) tree_free = nativeGit2
      .lookup<NativeFunction<Void Function(Pointer<git_tree>)>>("git_tree_free")
      .asFunction();

  static final Pointer<Utf8> Function(
      Pointer<
          git_reference>) reference_name = nativeGit2
      .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<git_reference>)>>(
          "git_reference_name")
      .asFunction();

  static final int Function(
          Pointer<git_oid>, Pointer<git_repository>, Pointer<Utf8>)
      reference_name_to_id = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<git_oid>, Pointer<git_repository>,
                      Pointer<Utf8>)>>("git_reference_name_to_id")
          .asFunction();

  static final int Function(Pointer<Pointer<git_reference>>,
          Pointer<git_reference>, Pointer<git_oid>, Pointer<Utf8>)
      reference_set_target = nativeGit2
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
      reference_resolve = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<git_reference>>,
                      Pointer<git_reference>)>>("git_reference_resolve")
          .asFunction();

  static final Pointer<git_oid> Function(Pointer<git_reference>)
      reference_target = nativeGit2
          .lookup<
              NativeFunction<
                  Pointer<git_oid> Function(
                      Pointer<git_reference>)>>("git_reference_target")
          .asFunction();

  static final int Function(Pointer<Pointer<git_commit>>,
          Pointer<git_repository>, Pointer<git_oid>) commit_lookup =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<git_commit>>,
                      Pointer<git_repository>,
                      Pointer<git_oid>)>>("git_commit_lookup")
          .asFunction();

  static final void Function(Pointer<git_commit>) commit_free = nativeGit2
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
          Pointer<Pointer<git_commit>>) commit_create =
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
      signature_now = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<git_signature>>, Pointer<Utf8>,
                      Pointer<Utf8>)>>("git_signature_now")
          .asFunction();

  static final void Function(Pointer<git_signature>) signature_free = nativeGit2
      .lookup<NativeFunction<Void Function(Pointer<git_signature>)>>(
          "git_signature_free")
      .asFunction();

  static final int Function(Pointer<git_oid>, Pointer<git_oid>) oid_cpy =
      nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<git_oid>, Pointer<git_oid>)>>("git_oid_cpy")
          .asFunction();

  static final int Function(Pointer<Int32>, Pointer<Int32>,
          Pointer<git_repository>, Pointer<Pointer<NativeType>>, int)
      merge_analysis = nativeGit2
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
          Pointer<NativeType>) merge =
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
      annotated_commit_from_ref = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Pointer<git_annotated_commit>>,
                      Pointer<git_repository>,
                      Pointer<git_reference>)>>("git_annotated_commit_from_ref")
          .asFunction();

  static final Pointer<git_oid> Function(Pointer<git_annotated_commit>)
      annotated_commit_id = nativeGit2
          .lookup<
                  NativeFunction<
                      Pointer<git_oid> Function(
                          Pointer<git_annotated_commit>)>>(
              "git_annotated_commit_id")
          .asFunction();

  static final void Function(Pointer<git_annotated_commit>)
      annotated_commit_free = nativeGit2
          .lookup<NativeFunction<Void Function(Pointer<git_annotated_commit>)>>(
              "git_annotated_commit_free")
          .asFunction();

  static final int Function(Pointer<Pointer<git_reference>>,
          Pointer<git_repository>, Pointer<Utf8>) reference_dwim =
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
      branch_upstream = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<git_reference>>,
                      Pointer<git_reference>)>>("git_branch_upstream")
          .asFunction();

  static final int Function(Pointer<Pointer<Utf8>>, Pointer<git_reference>)
      branch_name = nativeGit2
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Pointer<Utf8>>,
                      Pointer<git_reference>)>>("git_branch_name")
          .asFunction();

  static final void Function(Pointer<git_reference>) reference_free = nativeGit2
      .lookup<NativeFunction<Void Function(Pointer<git_reference>)>>(
          "git_reference_free")
      .asFunction();

  static Pointer<git_buf> allocateGitBuf() {
    Pointer<git_buf> buf = calloc<git_buf>();
    buf.ref.asize = 0;
    buf.ref.size = 0;
    buf.ref.ptr = nullptr;
    return buf;
  }

  static final void Function(Pointer<git_buf>) buf_dispose = nativeGit2
      .lookup<NativeFunction<Void Function(Pointer<git_buf>)>>(
          "git_buf_dispose")
      .asFunction();
}
