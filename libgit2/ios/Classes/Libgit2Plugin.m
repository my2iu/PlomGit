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
#include "git2/merge.h"

@implementation Libgit2Plugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftLibgit2Plugin registerWithRegistrar:registrar];
}
@end
