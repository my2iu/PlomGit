import 'dart:ffi';
import 'dart:io';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart';

class git_error extends Struct {
  Pointer<Utf8> message;

  @IntPtr()
  int klass;
}

class Libgit2 {
  // I don't really need this MethodChannel stuff since I don't need
  // interop with Java/Objective-C, but I'll keep it around anyway just
  // in case.
  static const MethodChannel _channel = const MethodChannel('libgit2');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static final DynamicLibrary nativeGit2 = Platform.isAndroid
      ? DynamicLibrary.open("libgit2.so")
      : DynamicLibrary.process();

  static final int Function() queryFeatures = nativeGit2
      .lookup<NativeFunction<IntPtr Function()>>("git_libgit2_features")
      .asFunction();

  static final int Function() init = nativeGit2
      .lookup<NativeFunction<IntPtr Function()>>("git_libgit2_init")
      .asFunction();

  static final int Function() shutdown = nativeGit2
      .lookup<NativeFunction<IntPtr Function()>>("git_libgit2_shutdown")
      .asFunction();

  static final Pointer<git_error> Function() errorLast = nativeGit2
      .lookup<NativeFunction<Pointer<git_error> Function()>>("git_error_last")
      .asFunction();

  static initTest() {
    print(Libgit2.init());
    print(Libgit2.errorLast()); 
  }
}
