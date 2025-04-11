import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:siga/themes.dart';

final appThemeStateNotifier = ChangeNotifierProvider((ref) => AppThemeState());

class AppThemeState extends ChangeNotifier {
  bool isDarkModeEnabled = false;
  bool isZenith = false;
  final CustomTheme theme = CustomTheme();

  void setLightTheme() {
    isDarkModeEnabled = false;
    notifyListeners();
  }

  void setDarkTheme() {
    isDarkModeEnabled = true;
    notifyListeners();
  }

  void zenith() {
    isZenith = true;
    notifyListeners();
  }

  void unZenith() {
    isZenith = false;
    notifyListeners();
  }
}
