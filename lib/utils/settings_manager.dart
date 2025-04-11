import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsManager {
  /// Get the correct app data directory based on the platform.
  static Future<String> getAppDataPath() async {
    if (Platform.isAndroid) {
      Directory? directory;

      if (await _isAndroid10OrBelow()) {
        directory = Directory('/storage/emulated/0/Android/data/com.onodnawij.siga/files');
      } else {
        directory = await getExternalStorageDirectory();
      }

      if (directory != null) {
        if (!(await directory.exists())) {
          await directory.create(recursive: true);
        }
        return directory.path;
      }
    } else {
      // Use application documents directory for non-Android platforms
      Directory directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }

    throw Exception("Could not determine storage path.");
  }

  /// Check if the Android device is running **Android 10 or lower**
  static Future<bool> _isAndroid10OrBelow() async {
    if (Platform.isAndroid) {
      try {
        int sdkInt = int.tryParse(Platform.environment['ro.build.version.sdk'] ?? '') ?? 0;
        return sdkInt <= 29;
      } catch (e) {
        print("Error determining Android version: $e");
      }
    }
    return false;
  }

  /// **Check and request storage permission** (only for Android)
  static Future<bool> checkAndRequestPermission() async {
    if (Platform.isAndroid && await _isAndroid10OrBelow()) {
      var status = await Permission.storage.status;

      if (status.isGranted) {
        return true;
      }

      var result = await Permission.storage.request();
      return result.isGranted;
    }

    return true; // Non-Android or Android 11+ doesn't require explicit permission
  }

  /// **Save Settings** to `settings.json`
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    if (!await checkAndRequestPermission()) {
      return;
    }

    final path = await getAppDataPath();
    final file = File('$path/settings.json');

    await file.writeAsString(jsonEncode(settings));
  }

  /// **Load Settings** from `settings.json`
  static Future<Map<String, dynamic>> loadSettings() async {
    if (!await checkAndRequestPermission()) {
      return {};
    }

    final path = await getAppDataPath();
    final file = File('$path/settings.json');

    if (await file.exists()) {
      String contents = await file.readAsString();
      return jsonDecode(contents);
    }

    return {}; // Return empty map if file does not exist
  }
}