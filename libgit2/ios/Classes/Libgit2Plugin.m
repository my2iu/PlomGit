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

@implementation Libgit2Plugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftLibgit2Plugin registerWithRegistrar:registrar];
}
@end

GIT_EXTERN(int) git_fetch_options_size() {
  return sizeof(git_fetch_options);
}

GIT_EXTERN(int) git_push_options_size() {
  return sizeof(git_push_options);
}

GIT_EXTERN(int) git_fetch_options_version() {
  return GIT_FETCH_OPTIONS_VERSION;
}

GIT_EXTERN(int) git_push_options_version() {
  return GIT_PUSH_OPTIONS_VERSION;
}
