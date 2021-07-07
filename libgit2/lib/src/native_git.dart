import 'dart:ffi';

import 'generated_bindings.dart';
import 'package:ffi/ffi.dart';

class gitHelpers {
  static final Pointer<Int8> _mainString = "main".toNativeUtf8().cast<Int8>();
  static void repository_init_options_config(
      Pointer<git_repository_init_options> opts) {
    opts.ref.initial_head = _mainString;
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

  static Pointer<git_buf> allocateGitBuf() {
    Pointer<git_buf> buf = calloc<git_buf>();
    buf.ref.asize = 0;
    buf.ref.size = 0;
    buf.ref.ptr = nullptr;
    return buf;
  }
}
