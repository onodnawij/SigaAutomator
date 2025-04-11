import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:siga/vars.dart';


abstract final class BlueTheme {
  // The defined light theme.
  static ThemeData light = FlexThemeData.light(
  scheme: FlexScheme.ebonyClay,
  surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
  blendLevel: 1,
  subThemesData: const FlexSubThemesData(
    interactionEffects: true,
    tintedDisabledControls: true,
    blendOnLevel: 8,
    useM2StyleDividerInM3: true,
    defaultRadius: 12.0,
    elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
    elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
    outlinedButtonOutlineSchemeColor: SchemeColor.primary,
    toggleButtonsBorderSchemeColor: SchemeColor.primary,
    segmentedButtonSchemeColor: SchemeColor.primary,
    segmentedButtonBorderSchemeColor: SchemeColor.primary,
    unselectedToggleIsColored: true,
    sliderValueTinted: true,
    inputDecoratorSchemeColor: SchemeColor.primary,
    inputDecoratorIsFilled: true,
    inputDecoratorBackgroundAlpha: 31,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    inputDecoratorUnfocusedHasBorder: false,
    inputDecoratorFocusedBorderWidth: 1.0,
    inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
    fabUseShape: true,
    fabAlwaysCircular: true,
    fabSchemeColor: SchemeColor.tertiary,
    popupMenuRadius: 8.0,
    popupMenuElevation: 3.0,
    alignedDropdown: true,
    drawerIndicatorRadius: 12.0,
    drawerIndicatorSchemeColor: SchemeColor.primary,
    bottomNavigationBarMutedUnselectedLabel: false,
    bottomNavigationBarMutedUnselectedIcon: false,
    menuRadius: 8.0,
    menuElevation: 3.0,
    menuBarRadius: 0.0,
    menuBarElevation: 2.0,
    menuBarShadowColor: Color(0x00000000),
    searchBarElevation: 1.0,
    searchViewElevation: 1.0,
    searchUseGlobalShape: true,
    navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
    navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
    navigationBarIndicatorSchemeColor: SchemeColor.primary,
    navigationBarIndicatorRadius: 12.0,
    navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
    navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
    navigationRailUseIndicator: true,
    navigationRailIndicatorSchemeColor: SchemeColor.primary,
    navigationRailIndicatorOpacity: 1.00,
    navigationRailIndicatorRadius: 12.0,
    navigationRailBackgroundSchemeColor: SchemeColor.surface,
    navigationRailLabelType: NavigationRailLabelType.all,
  ),
  keyColors: const FlexKeyColors(
    useSecondary: true,
    useTertiary: true,
    keepPrimary: true,
  ),
  tones: FlexSchemeVariant.jolly.tones(Brightness.light),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
  // The defined dark theme.
  static ThemeData dark = FlexThemeData.dark(
  scheme: FlexScheme.ebonyClay,
  surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
  blendLevel: 2,
  subThemesData: const FlexSubThemesData(
    interactionEffects: true,
    tintedDisabledControls: true,
    blendOnLevel: 10,
    blendOnColors: true,
    useM2StyleDividerInM3: true,
    defaultRadius: 12.0,
    elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
    elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
    outlinedButtonOutlineSchemeColor: SchemeColor.primary,
    toggleButtonsBorderSchemeColor: SchemeColor.primary,
    segmentedButtonSchemeColor: SchemeColor.primary,
    segmentedButtonBorderSchemeColor: SchemeColor.primary,
    unselectedToggleIsColored: true,
    sliderValueTinted: true,
    inputDecoratorSchemeColor: SchemeColor.primary,
    inputDecoratorIsFilled: true,
    inputDecoratorBackgroundAlpha: 43,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    inputDecoratorUnfocusedHasBorder: false,
    inputDecoratorFocusedBorderWidth: 1.0,
    inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
    fabUseShape: true,
    fabAlwaysCircular: true,
    fabSchemeColor: SchemeColor.tertiary,
    popupMenuRadius: 8.0,
    popupMenuElevation: 3.0,
    alignedDropdown: true,
    drawerIndicatorRadius: 12.0,
    drawerIndicatorSchemeColor: SchemeColor.primary,
    bottomNavigationBarMutedUnselectedLabel: false,
    bottomNavigationBarMutedUnselectedIcon: false,
    menuRadius: 8.0,
    menuElevation: 3.0,
    menuBarRadius: 0.0,
    menuBarElevation: 2.0,
    menuBarShadowColor: Color(0x00000000),
    searchBarElevation: 1.0,
    searchViewElevation: 1.0,
    searchUseGlobalShape: true,
    navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
    navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
    navigationBarIndicatorSchemeColor: SchemeColor.primary,
    navigationBarIndicatorRadius: 12.0,
    navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
    navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
    navigationRailUseIndicator: true,
    navigationRailIndicatorSchemeColor: SchemeColor.primary,
    navigationRailIndicatorOpacity: 1.00,
    navigationRailIndicatorRadius: 12.0,
    navigationRailBackgroundSchemeColor: SchemeColor.surface,
    navigationRailLabelType: NavigationRailLabelType.all,
  ),
  keyColors: const FlexKeyColors(
    useSecondary: true,
    useTertiary: true,
  ),
  tones: FlexSchemeVariant.jolly.tones(Brightness.dark),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
}


abstract final class PinkTheme {
  // The defined light theme.
  static ThemeData light = FlexThemeData.light(
  scheme: FlexScheme.sakura,
  surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
  blendLevel: 1,
  subThemesData: const FlexSubThemesData(
    interactionEffects: true,
    tintedDisabledControls: true,
    blendOnLevel: 8,
    useM2StyleDividerInM3: true,
    defaultRadius: 12.0,
    elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
    elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
    outlinedButtonOutlineSchemeColor: SchemeColor.primary,
    toggleButtonsBorderSchemeColor: SchemeColor.primary,
    segmentedButtonSchemeColor: SchemeColor.primary,
    segmentedButtonBorderSchemeColor: SchemeColor.primary,
    unselectedToggleIsColored: true,
    sliderValueTinted: true,
    inputDecoratorSchemeColor: SchemeColor.primary,
    inputDecoratorIsFilled: true,
    inputDecoratorBackgroundAlpha: 31,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    inputDecoratorUnfocusedHasBorder: false,
    inputDecoratorFocusedBorderWidth: 1.0,
    inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
    fabUseShape: true,
    fabAlwaysCircular: true,
    fabSchemeColor: SchemeColor.tertiary,
    popupMenuRadius: 8.0,
    popupMenuElevation: 3.0,
    alignedDropdown: true,
    drawerIndicatorRadius: 12.0,
    drawerIndicatorSchemeColor: SchemeColor.primary,
    bottomNavigationBarMutedUnselectedLabel: false,
    bottomNavigationBarMutedUnselectedIcon: false,
    menuRadius: 8.0,
    menuElevation: 3.0,
    menuBarRadius: 0.0,
    menuBarElevation: 2.0,
    menuBarShadowColor: Color(0x00000000),
    searchBarElevation: 1.0,
    searchViewElevation: 1.0,
    searchUseGlobalShape: true,
    navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
    navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
    navigationBarIndicatorSchemeColor: SchemeColor.primary,
    navigationBarIndicatorRadius: 12.0,
    navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
    navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
    navigationRailUseIndicator: true,
    navigationRailIndicatorSchemeColor: SchemeColor.primary,
    navigationRailIndicatorOpacity: 1.00,
    navigationRailIndicatorRadius: 12.0,
    navigationRailBackgroundSchemeColor: SchemeColor.surface,
    navigationRailLabelType: NavigationRailLabelType.all,
  ),
  keyColors: const FlexKeyColors(
    useSecondary: true,
    useTertiary: true,
    keepPrimary: true,
  ),
  tones: FlexSchemeVariant.jolly.tones(Brightness.light),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
  // The defined dark theme.
  static ThemeData dark = FlexThemeData.dark(
  scheme: FlexScheme.sakura,
  surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
  blendLevel: 2,
  subThemesData: const FlexSubThemesData(
    interactionEffects: true,
    tintedDisabledControls: true,
    blendOnLevel: 10,
    blendOnColors: true,
    useM2StyleDividerInM3: true,
    defaultRadius: 12.0,
    elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
    elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
    outlinedButtonOutlineSchemeColor: SchemeColor.primary,
    toggleButtonsBorderSchemeColor: SchemeColor.primary,
    segmentedButtonSchemeColor: SchemeColor.primary,
    segmentedButtonBorderSchemeColor: SchemeColor.primary,
    unselectedToggleIsColored: true,
    sliderValueTinted: true,
    inputDecoratorSchemeColor: SchemeColor.primary,
    inputDecoratorIsFilled: true,
    inputDecoratorBackgroundAlpha: 43,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    inputDecoratorUnfocusedHasBorder: false,
    inputDecoratorFocusedBorderWidth: 1.0,
    inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
    fabUseShape: true,
    fabAlwaysCircular: true,
    fabSchemeColor: SchemeColor.tertiary,
    popupMenuRadius: 8.0,
    popupMenuElevation: 3.0,
    alignedDropdown: true,
    drawerIndicatorRadius: 12.0,
    drawerIndicatorSchemeColor: SchemeColor.primary,
    bottomNavigationBarMutedUnselectedLabel: false,
    bottomNavigationBarMutedUnselectedIcon: false,
    menuRadius: 8.0,
    menuElevation: 3.0,
    menuBarRadius: 0.0,
    menuBarElevation: 2.0,
    menuBarShadowColor: Color(0x00000000),
    searchBarElevation: 1.0,
    searchViewElevation: 1.0,
    searchUseGlobalShape: true,
    navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
    navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
    navigationBarIndicatorSchemeColor: SchemeColor.primary,
    navigationBarIndicatorRadius: 12.0,
    navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
    navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
    navigationRailUseIndicator: true,
    navigationRailIndicatorSchemeColor: SchemeColor.primary,
    navigationRailIndicatorOpacity: 1.00,
    navigationRailIndicatorRadius: 12.0,
    navigationRailBackgroundSchemeColor: SchemeColor.surface,
    navigationRailLabelType: NavigationRailLabelType.all,
  ),
  keyColors: const FlexKeyColors(
    useSecondary: true,
    useTertiary: true,
  ),
  tones: FlexSchemeVariant.jolly.tones(Brightness.dark),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );}

class CustomTheme {
  final ThemeData lightBlue = BlueTheme.light.copyWith(
    textTheme: appFont(BlueTheme.light.textTheme),
  );
  final ThemeData lightPink = PinkTheme.light.copyWith(
    textTheme: appFont(PinkTheme.light.textTheme),
  );
  final ThemeData darkBlue = BlueTheme.dark.copyWith(
    textTheme: appFont(BlueTheme.dark.textTheme),
  );
  final ThemeData darkPink = PinkTheme.dark.copyWith(
    textTheme: appFont(PinkTheme.dark.textTheme),
  );

  MenuStyle getMenuStyle(context) {
    return MenuStyle(
      backgroundColor: WidgetStateProperty<Color>.fromMap(
        <WidgetStatesConstraint, Color>{
          WidgetState.any: Theme.of(context).colorScheme.surfaceBright,
        },
      ),
    );
  }

  final BoxDecoration innerWhite = BoxDecoration(
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(color: Colors.black26),
      BoxShadow(color: Colors.white, spreadRadius: -1, blurRadius: 2),
    ],
  );

  final BoxDecoration innerNone = BoxDecoration();

  late ThemeData lightTheme;
  late ThemeData darkTheme;
  late BoxDecoration innerColor;
  late ThemeMode themeMode;

  CustomTheme() {
    lightTheme = FlexThemeData.light(scheme: FlexScheme.pinkM3);
    darkTheme = darkBlue;
    innerColor = innerWhite;
    themeMode = ThemeMode.system;
  }
}