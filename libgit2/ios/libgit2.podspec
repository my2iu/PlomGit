#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint libgit2.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'libgit2'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,m,c,swift}', 'plomgit-libgit2/src/**/*.c', 'plomgit-libgit2/deps/http-parser/*.c', 'plomgit-libgit2/deps/pcre/*.c'
  #s.source_files = 'Classes/**/*.{h,c}', 'plomgit-libgit2/src/**/*.{h,c}', 'plomgit-libgit2/include/**/*.h', 'plomgit-libgit2/deps/http-parser/*.{h,c}', 'plomgit-libgit2/deps/pcre/*.{h,c}'
  #s.source_files = 'Classes/**/*.{h,c}', 'plomgit-libgit2/src/**/*.{h,c}', 'plomgit-libgit2/include/**/*.h', 'plomgit-libgit2/deps/http-parser/*.{h,c}', 'plomgit-libgit2/deps/ntlmclient/*.{h,c}'
  s.exclude_files = "plomgit-libgit2/include/git2/inttypes.h", "plomgit-libgit2/include/git2/stdint.h", "plomgit-libgit2/src/win32/**/*", "plomgit-libgit2/src/allocators/win32*", "plomgit-libgit2/src/hash/sha1/win32.c", "plomgit-libgit2/src/hash/sha1/openssl.c", "plomgit-libgit2/src/hash/sha1/mbedtls.c", "plomgit-libgit2/src/hash/sha1/generic.c", "plomgit-libgit2/src/hash/sha1/common_crypto.c"
  s.preserve_paths = "plomgit-libgit2/src/**/*.h", "plomgit-libgit2/include/**/*.h", "plomgit-libgit2/deps/http-parser/*.h", "plomgit-libgit2/deps/pcre/*.h"
#  s.public_header_files = "Classes/Libgit2Plugin.h" # "plomgit-libgit2/src/**/*.h", "plomgit-libgit2/include/**/*.h"
#  s.header_mappings_dir = "plomgit-libgit2/include plomgit-libgit2/src"
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.libraries = "pthread", "iconv"
  #s.compiler_flags = '-Ilibgit2.1.1.0/include'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.xcconfig = {
    "OTHER_CFLAGS": "-Wdocumentation-deprecated-sync -DHAVE_CONFIG_H",
    "HEADER_SEARCH_PATHS": "$(PODS_ROOT)/../.symlinks/plugins/libgit2/ios/plomgit-libgit2/include $(PODS_ROOT)/../.symlinks/plugins/libgit2/ios/plomgit-libgit2/src $(PODS_ROOT)/../.symlinks/plugins/libgit2/ios/plomgit-libgit2/deps/pcre $(PODS_ROOT)/../.symlinks/plugins/libgit2/ios/plomgit-libgit2/deps/http-parser",
    "GCC_WARN_ABOUT_DEPRECATED_FUNCTIONS":"NO"
  }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'libgit2_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
