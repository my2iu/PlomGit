
import 'dart:async';

import 'package:flutter/services.dart';

class Libgit2 {
  static const MethodChannel _channel =
      const MethodChannel('libgit2');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
