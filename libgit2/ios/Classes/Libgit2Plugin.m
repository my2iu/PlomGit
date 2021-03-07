#import "Libgit2Plugin.h"
#if __has_include(<libgit2/libgit2-Swift.h>)
#import <libgit2/libgit2-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "libgit2-Swift.h"
#endif

#include "git2/remote.h"
#include "git2/status.h"
#include "git2/checkout.h"
#include "git2/clone.h"

@implementation Libgit2Plugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftLibgit2Plugin registerWithRegistrar:registrar];
}
@end

GIT_EXTERN(int) git_fetch_options_size(void) {
  return sizeof(git_fetch_options);
}

GIT_EXTERN(int) git_push_options_size(void) {
  return sizeof(git_push_options);
}

GIT_EXTERN(int) git_status_options_size(void) {
  return sizeof(git_status_options);
}

GIT_EXTERN(int) git_clone_options_size(void) {
  return sizeof(git_clone_options);
}

GIT_EXTERN(int) git_checkout_options_size(void) {
  return sizeof(git_checkout_options);
}

GIT_EXTERN(int) git_merge_options_size(void) {
  return sizeof(git_checkout_options);
}

GIT_EXTERN(int) git_fetch_options_version(void) {
  return GIT_FETCH_OPTIONS_VERSION;
}

GIT_EXTERN(int) git_push_options_version(void) {
  return GIT_PUSH_OPTIONS_VERSION;
}

GIT_EXTERN(int) git_status_options_version(void) {
  return GIT_STATUS_OPTIONS_VERSION;
}

GIT_EXTERN(int) git_clone_options_version(void) {
  return GIT_CLONE_OPTIONS_VERSION;
}

GIT_EXTERN(int) git_checkout_options_version(void) {
  return GIT_CHECKOUT_OPTIONS_VERSION;
}

GIT_EXTERN(int) git_merge_options_version(void) {
  return GIT_CHECKOUT_OPTIONS_VERSION;
}

GIT_EXTERN(void) git_fetch_options_set_credentials_cb(git_fetch_options *opts, git_credential_acquire_cb *credentials_cb) {
  opts->callbacks.credentials = credentials_cb;
}

GIT_EXTERN(void) git_push_options_set_credentials_cb(git_push_options *opts, git_credential_acquire_cb *credentials_cb) {
  opts->callbacks.credentials = credentials_cb;
}

GIT_EXTERN(void) git_clone_options_set_credentials_cb(git_clone_options *opts, git_credential_acquire_cb *credentials_cb) {
  opts->fetch_opts.callbacks.credentials = credentials_cb;
}

GIT_EXTERN(void) git_status_options_config(git_status_options * opts, const char **path) {
  if (path != NULL) {
    opts->pathspec.count = 1;
    opts->pathspec.strings = path;
  }
  opts->show = GIT_STATUS_SHOW_INDEX_AND_WORKDIR;
	opts->flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED |
		GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS |
		GIT_STATUS_OPT_INCLUDE_UNMODIFIED;
}

GIT_EXTERN(void) git_checkout_options_config_for_revert(git_checkout_options * opts, const char **path) {
  opts->checkout_strategy = GIT_CHECKOUT_FORCE | GIT_CHECKOUT_REMOVE_UNTRACKED | GIT_CHECKOUT_RECREATE_MISSING;
  if (path != NULL) {
    opts->checkout_strategy |= GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH;
    opts->paths.count = 1;
    opts->paths.strings = path;
  }
}

GIT_EXTERN(void) git_checkout_options_config_for_fastforward(git_checkout_options * opts) {
  opts->checkout_strategy = GIT_CHECKOUT_SAFE;
}

GIT_EXTERN(void) git_checkout_options_config_for_merge(git_checkout_options * opts) {
  opts->checkout_strategy = GIT_CHECKOUT_FORCE | GIT_CHECKOUT_ALLOW_CONFLICTS;
}