import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:siga/providers/setting_provider.dart';
import 'package:siga/providers/theme_provider.dart';

class SettingPage extends ConsumerWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeState = ref.watch(appThemeStateNotifier);

    return Scaffold(
      appBar: AppBar(title: Text('Setting'), forceMaterialTransparency: true),
      body: Padding(
        padding: EdgeInsets.fromLTRB(20, 7, 20, 7),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(flex: 3, child: Text('Dark mode:')),
                Expanded(
                  flex: 7,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: Switch(
                      // value: widget.api.themeController.isDark.value,
                      value: appThemeState.isDarkModeEnabled,
                      onChanged: (value) {
                        if (value) {
                          appThemeState.setDarkTheme();
                        } else {
                          appThemeState.setLightTheme();
                        }

                        final current = {"dark": appThemeState.isDarkModeEnabled, "zenith": appThemeState.isZenith};
                        ref.read(settingProvider).theme = current;
                      },
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(flex: 3, child: Text('Zenith mode:')),
                Expanded(
                  flex: 7,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: Switch(
                      // value: widget.api.themeController.isZenith.value,
                      value: appThemeState.isZenith,
                      onChanged: (value) {
                        if (value) {
                          appThemeState.zenith();
                        } else {
                          appThemeState.unZenith();
                        }
                        final current = {"dark": appThemeState.isDarkModeEnabled, "zenith": appThemeState.isZenith};
                        ref.read(settingProvider).theme = current;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
