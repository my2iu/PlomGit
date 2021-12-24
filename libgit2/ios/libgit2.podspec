#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint libgit2.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'libgit2'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC 
A new flutter plugin project. 
 DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,m,c,swift}', 'libgit2-1.3.0/src/**/*.c', 'libgit2-1.3.0/deps/http-parser/*.c', 'libgit2-1.3.0/deps/pcre/*.c'
  #s.source_files = 'Classes/**/*.{h,c}', 'libgit2-1.3.0/src/**/*.{h,c}', 'libgit2-1.3.0/include/**/*.h', 'libgit2-1.3.0/deps/http-parser/*.{h,c}', 'libgit2-1.3.0/deps/pcre/*.{h,c}'
  #s.source_files = 'Classes/**/*.{h,c}', 'libgit2-1.3.0/src/**/*.{h,c}', 'libgit2-1.3.0/include/**/*.h', 'libgit2-1.3.0/deps/http-parser/*.{h,c}', 'libgit2-1.3.0/deps/ntlmclient/*.{h,c}'
  s.exclude_files = "libgit2-1.3.0/include/git2/inttypes.h", "libgit2-1.3.0/include/git2/stdint.h", "libgit2-1.3.0/src/win32/**/*", "libgit2-1.3.0/src/allocators/win32*", "libgit2-1.3.0/src/hash/sha1/win32.c", "libgit2-1.3.0/src/hash/sha1/openssl.c", "libgit2-1.3.0/src/hash/sha1/mbedtls.c", "libgit2-1.3.0/src/hash/sha1/generic.c", "libgit2-1.3.0/src/hash/sha1/common_crypto.c"
  s.preserve_paths = "libgit2-1.3.0/src/**/*.h", "libgit2-1.3.0/include/**/*.h", "libgit2-1.3.0/deps/http-parser/*.h", "libgit2-1.3.0/deps/pcre/*.h"
#  s.public_header_files = "Classes/Libgit2Plugin.h" # "libgit2-1.3.0/src/**/*.h", "libgit2-1.3.0/include/**/*.h"
#  s.header_mappings_dir = "libgit2-1.3.0/include libgit2-1.3.0/src"
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'
  s.libraries = "pthread", "iconv"
  #s.compiler_flags = '-Ilibgit2.1.1.0/include'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.xcconfig = {
    "OTHER_CFLAGS": "-Wdocumentation-deprecated-sync -DHAVE_CONFIG_H",
    "HEADER_SEARCH_PATHS": "$(PODS_ROOT)/../.symlinks/plugins/libgit2/ios/libgit2-1.3.0/include $(PODS_ROOT)/../.symlinks/plugins/libgit2/ios/libgit2-1.3.0/src $(PODS_ROOT)/../.symlinks/plugins/libgit2/ios/libgit2-1.3.0/deps/pcre $(PODS_ROOT)/../.symlinks/plugins/libgit2/ios/libgit2-1.3.0/deps/http-parser",
    "GCC_WARN_ABOUT_DEPRECATED_FUNCTIONS":"NO"
  }
  s.swift_version = '5.0'
end
