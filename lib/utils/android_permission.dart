import 'dart:io';

import 'package:flutter/services.dart';

class AccessibilityHelper {
  static const _channel = MethodChannel('siga_automator/channel');

  static Future<bool> request() async {
    try {
      final result = await _channel.invokeMethod<bool>('openAccessibilitySettings');
      return result ?? false;
    } on PlatformException catch (e) {
      print("Error checking accessibility: ${e.message}");
      return false;
    }
  }

  static Future<bool> check() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>('isAccessibilityEnabled');
        return result ?? false;
      } else {
        return true;
      }
    } on PlatformException catch(e) {
      print("Error checking accessibility: ${e.message}");
      return false;
    }
  }
}