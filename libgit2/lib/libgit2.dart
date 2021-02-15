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

  static final int Function(Pointer<Pointer<NativeType>>, Pointer<Utf8>, int)
      _repositoryInit = nativeGit2
          .lookup<
              NativeFunction<
                  IntPtr Function(Pointer<Pointer<NativeType>>, Pointer<Utf8>,
                      IntPtr)>>("git_repository_init")
          .asFunction();

  /// Checks the return code for errors and if so, convert it to a thrown
  /// exception
  static int _checkErrors(int errorCode) {
    if (errorCode < 0) throw Libgit2Exception.fromErrorCode(errorCode);
    return errorCode;
  }

  static void initRepository(String dir) {
    Pointer<Pointer<NativeType>> repository = allocate<Pointer<NativeType>>();
    var dirPtr = Utf8.toUtf8(dir);
    _checkErrors(_repositoryInit(repository, dirPtr, 0));
    free(dirPtr);
  }
}

/// Packages up Libgit2 error code and error message in a single class
class Libgit2Exception implements Exception {
  String message;
  int errorCode;
  int klass;

  Libgit2Exception(this.errorCode, this.message, this.klass);

  Libgit2Exception.fromErrorCode(this.errorCode) {
    var err = Libgit2.errorLast();
    if (err.address != 0) {
      message = Utf8.fromUtf8(err.ref.message);
      klass = err.ref.klass;
    }
  }
}
