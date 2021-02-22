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

GIT_EXTERN(int) git_fetch_options_version(void) {
  return GIT_FETCH_OPTIONS_VERSION;
}

GIT_EXTERN(int) git_push_options_version(void) {
  return GIT_PUSH_OPTIONS_VERSION;
}

GIT_EXTERN(int) git_status_options_version(void) {
  return GIT_STATUS_OPTIONS_VERSION;
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