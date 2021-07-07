import 'dart:ffi';
import 'dart:io';

import 'generated_bindings.dart';
import 'package:ffi/ffi.dart';

export 'generated_bindings.dart'
    show
        git_repository,
        git_repository_init_options,
        git_strarray,
        git_reference,
        git_buf,
        git_oid,
        git_remote,
        git_credential,
        git_signature,
        git_status_entry,
        git_diff_delta,
        git_diff_file,
        git_credential_acquire_cb,
        git_remote_callbacks,
        git_fetch_options,
        git_push_options,
        git_status_list,
        git_status_options,
        git_index,
        git_tree,
        git_commit,
        git_annotated_commit;

class git {
  static final DynamicLibrary nativeGit2 = Platform.isAndroid
      ? DynamicLibrary.open("libgit2.so")
      : DynamicLibrary.process();

  static final NativeLibrary git2 = NativeLibrary(Platform.isAndroid
      ? DynamicLibrary.open("libgit2.so")
      : DynamicLibrary.process());

  static int queryFeatures() {
    return git2.git_libgit2_features();
  }

  static int init() {
    return git2.git_libgit2_init();
  }

  static int shutdown() {
    return git2.git_libgit2_shutdown();
  }

  static Pointer<git_error> errorLast() {
    return git2.git_error_last();
  }

  static int error_set_str(int errorClass, Pointer<Int8> str) {
    return git2.git_error_set_str(errorClass, str);
  }

  static int repository_init(
    Pointer<Pointer<git_repository>> out,
    Pointer<Int8> path,
    int is_bare,
  ) {
    return git2.git_repository_init(out, path, is_bare);
  }

  static int repository_init_ext(
    Pointer<Pointer<git_repository>> out,
    Pointer<Int8> repo_path,
    Pointer<git_repository_init_options> opts,
  ) {
    return git2.git_repository_init_ext(out, repo_path, opts);
  }

  static final void Function(Pointer<NativeType>)
      repository_init_options_config = nativeGit2
          .lookup<NativeFunction<Void Function(Pointer<NativeType>)>>(
              "git_repository_init_options_config")
          .asFunction();

  static int repository_open(
    Pointer<Pointer<git_repository>> out,
    Pointer<Int8> path,
  ) {
    return git2.git_repository_open(out, path);
  }

  static int repository_state(Pointer<git_repository> repo) {
    return git2.git_repository_state(repo);
  }

  static int repository_state_cleanup(Pointer<git_repository> repo) {
    return git2.git_repository_state_cleanup(repo);
  }

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

  static void repository_free(Pointer<git_repository> repo) {
    git2.git_repository_free(repo);
  }

  static int repository_head_unborn(Pointer<git_repository> repo) {
    return git2.git_repository_head_unborn(repo);
  }

  static int repository_head(
      Pointer<Pointer<git_reference>> out, Pointer<git_repository> repo) {
    return git2.git_repository_head(out, repo);
  }

  static int repository_set_head(
      Pointer<git_repository> repo, Pointer<Int8> refname) {
    return git2.git_repository_set_head(repo, refname);
  }

  static int graph_ahead_behind(
      Pointer<IntPtr> ahead,
      Pointer<IntPtr> behind,
      Pointer<git_repository> repo,
      Pointer<git_oid> local,
      Pointer<git_oid> upstream) {
    return git2.git_graph_ahead_behind(ahead, behind, repo, local, upstream);
  }

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

  static void strArrayDispose(Pointer<git_strarray> array) {
    git2.git_strarray_dispose(array);
  }

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

  static final int Function(Pointer<NativeType>, int version)
      repository_init_options_init = nativeGit2
          .lookup<NativeFunction<Int32 Function(Pointer<NativeType>, Int32)>>(
              "git_repository_init_options_init")
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

  static final int Function() repository_init_options_size = nativeGit2
      .lookup<NativeFunction<Int32 Function()>>(
          "git_repository_init_options_size")
      .asFunction();

  static int fetch_options_version() {
    return GIT_FETCH_OPTIONS_VERSION;
  }

  static int push_options_version() {
    return GIT_PUSH_OPTIONS_VERSION;
  }

  static int status_options_version() {
    return GIT_STATUS_OPTIONS_VERSION;
  }

  static int clone_options_version() {
    return GIT_CLONE_OPTIONS_VERSION;
  }

  static int checkout_options_version() {
    return GIT_CHECKOUT_OPTIONS_VERSION;
  }

  static int merge_options_version() {
    return GIT_MERGE_OPTIONS_VERSION;
  }

  // static final int Function() repository_init_options_version = nativeGit2
  //     .lookup<NativeFunction<Int32 Function()>>(
  //         "git_repository_init_options_version")
  //     .asFunction();

  static final void Function(Pointer<NativeType>,
          Pointer<NativeFunction<git_credential_acquire_cb>>)
      fetch_options_set_credentials_cb = nativeGit2
          .lookup<
                  NativeFunction<
                      Void Function(Pointer<NativeType>,
                          Pointer<NativeFunction<git_credential_acquire_cb>>)>>(
              "git_fetch_options_set_credentials_cb")
          .asFunction();

  static final void Function(Pointer<NativeType>,
          Pointer<NativeFunction<git_credential_acquire_cb>>)
      push_options_set_credentials_cb = nativeGit2
          .lookup<
                  NativeFunction<
                      Void Function(Pointer<NativeType>,
                          Pointer<NativeFunction<git_credential_acquire_cb>>)>>(
              "git_push_options_set_credentials_cb")
          .asFunction();

  static final void Function(Pointer<NativeType>,
          Pointer<NativeFunction<git_credential_acquire_cb>>)
      clone_options_set_credentials_cb = nativeGit2
          .lookup<
                  NativeFunction<
                      Void Function(Pointer<NativeType>,
                          Pointer<NativeFunction<git_credential_acquire_cb>>)>>(
              "git_clone_options_set_credentials_cb")
          .asFunction();

  static int remote_list(
      Pointer<git_strarray> out, Pointer<git_repository> repo) {
    return git2.git_remote_list(out, repo);
  }

  static int remote_create(
    Pointer<Pointer<git_remote>> out,
    Pointer<git_repository> repo,
    Pointer<Int8> name,
    Pointer<Int8> url,
  ) {
    return git2.git_remote_create(out, repo, name, url);
  }

  static int remote_delete(Pointer<git_repository> repo, Pointer<Int8> name) {
    return git2.git_remote_delete(repo, name);
  }

  static int remote_lookup(Pointer<Pointer<git_remote>> out,
      Pointer<git_repository> repo, Pointer<Int8> name) {
    return git2.git_remote_lookup(out, repo, name);
  }

  static void remote_free(Pointer<git_remote> remote) {
    git2.git_remote_free(remote);
  }

  static int remote_fetch(
    Pointer<git_remote> remote,
    Pointer<git_strarray> refspecs,
    Pointer<git_fetch_options> opts,
    Pointer<Int8> reflog_message,
  ) {
    return git2.git_remote_fetch(remote, refspecs, opts, reflog_message);
  }

  static int remote_push(
    Pointer<git_remote> remote,
    Pointer<git_strarray> refspecs,
    Pointer<git_push_options> opts,
  ) {
    return git2.git_remote_push(remote, refspecs, opts);
  }

  static int status_list_new(Pointer<Pointer<git_status_list>> out,
      Pointer<git_repository> repo, Pointer<git_status_options> opts) {
    return git2.git_status_list_new(out, repo, opts);
  }

  static void status_list_free(Pointer<git_status_list> statuslist) {
    git2.git_status_list_free(statuslist);
  }

  static int status_list_entrycount(Pointer<git_status_list> statuslist) {
    return git2.git_status_list_entrycount(statuslist);
  }

  static Pointer<git_status_entry> status_byindex(
      Pointer<git_status_list> statuslist, int idx) {
    return git2.git_status_byindex(statuslist, idx);
  }

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

  static int repository_index(
      Pointer<Pointer<git_index>> out, Pointer<git_repository> repo) {
    return git2.git_repository_index(out, repo);
  }

  static void index_free(Pointer<git_index> index) {
    return git2.git_index_free(index);
  }

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

  static int index_write_tree(Pointer<git_oid> out, Pointer<git_index> index) {
    return git2.git_index_write_tree(out, index);
  }

  static int tree_lookup(Pointer<Pointer<git_tree>> out,
      Pointer<git_repository> repo, Pointer<git_oid> id) {
    return git2.git_tree_lookup(out, repo, id);
  }

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

  static Pointer<Int8> reference_name(Pointer<git_reference> ref) {
    return git2.git_reference_name(ref);
  }

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

  static int commit_lookup(Pointer<Pointer<git_commit>> commit,
      Pointer<git_repository> repo, Pointer<git_oid> id) {
    return git2.git_commit_lookup(commit, repo, id);
  }

  static void commit_free(Pointer<git_commit> commit) {
    git2.git_commit_free(commit);
  }

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

  static int annotated_commit_from_ref(
      Pointer<Pointer<git_annotated_commit>> out,
      Pointer<git_repository> repo,
      Pointer<git_reference> ref) {
    return git2.git_annotated_commit_from_ref(out, repo, ref);
  }

  static Pointer<git_oid> annotated_commit_id(
      Pointer<git_annotated_commit> commit) {
    return git2.git_annotated_commit_id(commit);
  }

  static void annotated_commit_free(Pointer<git_annotated_commit> commit) {
    git2.git_annotated_commit_free(commit);
  }

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
