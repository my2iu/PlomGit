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
        git_annotated_commit,
        git_merge_options,
        git_clone_options,
        git_checkout_options,
        git_object;

class git {
  static final DynamicLibrary nativeGit2 = Platform.isAndroid
      ? DynamicLibrary.open("libgit2.so")
      : DynamicLibrary.process();

  static final NativeLibrary git2 = NativeLibrary(nativeGit2);

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

  static final Pointer<Int8> _mainString = "main".toNativeUtf8().cast<Int8>();
  static void repository_init_options_config(
      Pointer<git_repository_init_options> opts) {
    opts.ref.initial_head = _mainString;
  }

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

  static int repository_mergehead_foreach(
      Pointer<git_repository> repo,
      Pointer<NativeFunction<git_repository_mergehead_foreach_cb>> callback,
      Pointer<Void> payload) {
    return git2.git_repository_mergehead_foreach(repo, callback, payload);
  }

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

  static int clone(Pointer<Pointer<git_repository>> out, Pointer<Int8> url,
      Pointer<Int8> local_path, Pointer<git_clone_options> options) {
    return git2.git_clone(out, url, local_path, options);
  }

  static void strArrayDispose(Pointer<git_strarray> array) {
    git2.git_strarray_dispose(array);
  }

  static int fetch_options_init(Pointer<git_fetch_options> opts, int version) {
    return git2.git_fetch_options_init(opts, version);
  }

  static int push_options_init(Pointer<git_push_options> opts, int version) {
    return git2.git_push_options_init(opts, version);
  }

  static int status_options_init(
      Pointer<git_status_options> opts, int version) {
    return git2.git_status_options_init(opts, version);
  }

  static int clone_options_init(Pointer<git_clone_options> opts, int version) {
    return git2.git_clone_options_init(opts, version);
  }

  static int checkout_options_init(
      Pointer<git_checkout_options> opts, int version) {
    return git2.git_checkout_options_init(opts, version);
  }

  static int merge_options_init(Pointer<git_merge_options> opts, int version) {
    return git2.git_merge_options_init(opts, version);
  }

  static int repository_init_options_init(
      Pointer<git_repository_init_options> opts, int version) {
    return git2.git_repository_init_options_init(opts, version);
  }

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

  static void fetch_options_set_credentials_cb(Pointer<git_fetch_options> opts,
      Pointer<NativeFunction<git_credential_acquire_cb>> credentials_cb) {
    opts.ref.callbacks.credentials = credentials_cb;
  }

  static void push_options_set_credentials_cb(Pointer<git_push_options> opts,
      Pointer<NativeFunction<git_credential_acquire_cb>> credentials_cb) {
    opts.ref.callbacks.credentials = credentials_cb;
  }

  static void clone_options_set_credentials_cb(Pointer<git_clone_options> opts,
      Pointer<NativeFunction<git_credential_acquire_cb>> credentials_cb) {
    opts.ref.fetch_opts.callbacks.credentials = credentials_cb;
  }

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
  static void status_options_config(
      Pointer<git_status_options> opts, Pointer<Pointer<Int8>> path) {
    if (path != nullptr) {
      opts.ref.pathspec.count = 1;
      opts.ref.pathspec.strings = path;
    }
    opts.ref.show_1 = git_status_show_t.GIT_STATUS_SHOW_INDEX_AND_WORKDIR;
    opts.ref.flags = git_status_opt_t.GIT_STATUS_OPT_INCLUDE_UNTRACKED |
        git_status_opt_t.GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS |
        git_status_opt_t.GIT_STATUS_OPT_INCLUDE_UNMODIFIED;
  }

  static int credential_userpass_plaintext_new(
      Pointer<Pointer<git_credential>> out,
      Pointer<Int8> username,
      Pointer<Int8> password) {
    return git2.git_credential_userpass_plaintext_new(out, username, password);
  }

  static int repository_index(
      Pointer<Pointer<git_index>> out, Pointer<git_repository> repo) {
    return git2.git_repository_index(out, repo);
  }

  static void index_free(Pointer<git_index> index) {
    return git2.git_index_free(index);
  }

  static int index_add_bypath(Pointer<git_index> index, Pointer<Int8> path) {
    return git2.git_index_add_bypath(index, path);
  }

  static int index_remove_bypath(Pointer<git_index> index, Pointer<Int8> path) {
    return git2.git_index_remove_bypath(index, path);
  }

  static int index_write(Pointer<git_index> index) {
    return git2.git_index_write(index);
  }

  static int index_write_tree(Pointer<git_oid> out, Pointer<git_index> index) {
    return git2.git_index_write_tree(out, index);
  }

  static int tree_lookup(Pointer<Pointer<git_tree>> out,
      Pointer<git_repository> repo, Pointer<git_oid> id) {
    return git2.git_tree_lookup(out, repo, id);
  }

  static int checkout_tree(Pointer<git_repository> repo,
      Pointer<git_object> treeish, Pointer<git_checkout_options> opts) {
    return git2.git_checkout_tree(repo, treeish, opts);
  }

  static int checkout_head(
      Pointer<git_repository> repo, Pointer<git_checkout_options> opts) {
    return git2.git_checkout_head(repo, opts);
  }

  // The second parameter can be null or a pointer to a pointer of a string
  static void checkout_options_config_for_revert(
      Pointer<git_checkout_options> opts, Pointer<Pointer<Int8>> path) {
    opts.ref.checkout_strategy = git_checkout_strategy_t.GIT_CHECKOUT_FORCE |
        git_checkout_strategy_t.GIT_CHECKOUT_REMOVE_UNTRACKED |
        git_checkout_strategy_t.GIT_CHECKOUT_RECREATE_MISSING;
    if (path != nullptr) {
      opts.ref.checkout_strategy |=
          git_checkout_strategy_t.GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH;
      opts.ref.paths.count = 1;
      opts.ref.paths.strings = path;
    }
  }

  static void checkout_options_config_for_fastforward(
      Pointer<git_checkout_options> opts) {
    opts.ref.checkout_strategy = git_checkout_strategy_t.GIT_CHECKOUT_SAFE;
  }

  static void checkout_options_config_for_merge(
      Pointer<git_checkout_options> opts) {
    opts.ref.checkout_strategy = git_checkout_strategy_t.GIT_CHECKOUT_FORCE |
        git_checkout_strategy_t.GIT_CHECKOUT_ALLOW_CONFLICTS;
  }

  static void tree_free(Pointer<git_tree> tree) {
    git2.git_tree_free(tree);
  }

  static Pointer<Int8> reference_name(Pointer<git_reference> ref) {
    return git2.git_reference_name(ref);
  }

  static int reference_name_to_id(
      Pointer<git_oid> out, Pointer<git_repository> repo, Pointer<Int8> name) {
    return git2.git_reference_name_to_id(out, repo, name);
  }

  static int reference_set_target(
      Pointer<Pointer<git_reference>> out,
      Pointer<git_reference> ref,
      Pointer<git_oid> id,
      Pointer<Int8> log_message) {
    return git2.git_reference_set_target(out, ref, id, log_message);
  }

  static int reference_resolve(
      Pointer<Pointer<git_reference>> out, Pointer<git_reference> ref) {
    return git2.git_reference_resolve(out, ref);
  }

  static Pointer<git_oid> reference_target(Pointer<git_reference> ref) {
    return git2.git_reference_target(ref);
  }

  static int commit_lookup(Pointer<Pointer<git_commit>> commit,
      Pointer<git_repository> repo, Pointer<git_oid> id) {
    return git2.git_commit_lookup(commit, repo, id);
  }

  static void commit_free(Pointer<git_commit> commit) {
    git2.git_commit_free(commit);
  }

  static int commit_create(
      Pointer<git_oid> id,
      Pointer<git_repository> repo,
      Pointer<Int8> update_ref,
      Pointer<git_signature> author,
      Pointer<git_signature> committer,
      Pointer<Int8> message_encoding,
      Pointer<Int8> message,
      Pointer<git_tree> tree,
      int parent_count,
      Pointer<Pointer<git_commit>> parents) {
    return git2.git_commit_create(id, repo, update_ref, author, committer,
        message_encoding, message, tree, parent_count, parents);
  }

  static int signature_now(Pointer<Pointer<git_signature>> out,
      Pointer<Int8> name, Pointer<Int8> email) {
    return git2.git_signature_now(out, name, email);
  }

  static void signature_free(Pointer<git_signature> sig) {
    return git2.git_signature_free(sig);
  }

  static int oid_cpy(Pointer<git_oid> out, Pointer<git_oid> src) {
    return git2.git_oid_cpy(out, src);
  }

  static int merge_analysis(
      Pointer<Int32> analysis_out,
      Pointer<Int32> preference_out,
      Pointer<git_repository> repo,
      Pointer<Pointer<git_annotated_commit>> their_heads,
      int their_heads_len) {
    return git2.git_merge_analysis(
        analysis_out, preference_out, repo, their_heads, their_heads_len);
  }

  static int merge(
      Pointer<git_repository> repo,
      Pointer<Pointer<git_annotated_commit>> their_heads,
      int their_heads_len,
      Pointer<git_merge_options> merge_opts,
      Pointer<git_checkout_options> checkout_opts) {
    return git2.git_merge(
        repo, their_heads, their_heads_len, merge_opts, checkout_opts);
  }

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

  static int reference_dwim(Pointer<Pointer<git_reference>> out,
      Pointer<git_repository> repo, Pointer<Int8> shorthand) {
    return git2.git_reference_dwim(out, repo, shorthand);
  }

  static int branch_upstream(
      Pointer<Pointer<git_reference>> out, Pointer<git_reference> branch) {
    return git2.git_branch_upstream(out, branch);
  }

  static int branch_name(
      Pointer<Pointer<Int8>> out, Pointer<git_reference> ref) {
    return git2.git_branch_name(out, ref);
  }

  static void reference_free(Pointer<git_reference> ref) {
    git2.git_reference_free(ref);
  }

  static Pointer<git_buf> allocateGitBuf() {
    Pointer<git_buf> buf = calloc<git_buf>();
    buf.ref.asize = 0;
    buf.ref.size = 0;
    buf.ref.ptr = nullptr;
    return buf;
  }

  static void buf_dispose(Pointer<git_buf> buffer) {
    git2.git_buf_dispose(buffer);
  }
}
