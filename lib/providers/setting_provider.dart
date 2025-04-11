import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:siga/utils/settings_manager.dart';

final settingProvider = StateProvider((ref) => _SettingProvider());

class _SettingProvider {
  Map<String, dynamic> _settings = {
    "theme" : {
      "dark": false,
      "zenith": false,
    },
    "login": {
      "stayLoggedIn": false,
      "userData": null,
      "username": "",
    },
  };
  bool _finalized = false;

  _SettingProvider() {
    _init();
  }

  Map<String, dynamic> get settings => _settings;
  Map<String, dynamic> get login => _settings["login"];
  Map<String, dynamic> get theme => _settings["theme"];

  set settings(Map<String, dynamic> newValue) {
    _settings = newValue;
    SettingsManager.saveSettings(_settings);
  }

  set login(Map<String, dynamic> newValue) {
    _settings["login"] = newValue;
    SettingsManager.saveSettings(_settings);
  }
  
  set theme(Map<String, dynamic> newValue) {
    _settings["theme"] = newValue;
    SettingsManager.saveSettings(_settings);
  }

  void _init() async {
    final loadedSetting = await SettingsManager.loadSettings();
    _settings.addAll(loadedSetting);
    _finalized = true;
  }

  Future<bool> get isFinalized async {
    while (!_finalized) {
      await Future.delayed(Duration(milliseconds: 500));
    }
    return true;
  }
}