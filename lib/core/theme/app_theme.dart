import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

abstract final class AppTheme {
  static const secondaryTextColor = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF595963),
    darkColor: Color(0xFFAEAEB8),
  );

  static const actionColor = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF0062CC),
    darkColor: Color(0xFF6BAEFF),
  );

  static const destructiveColor = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFC9362C),
    darkColor: Color(0xFFFF6961),
  );

  static const _onActionColor = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.white,
    darkColor: CupertinoColors.black,
  );

  static const _barBackgroundColor = CupertinoDynamicColor.withBrightness(
    color: Color(0xEBF2F2F7),
    darkColor: Color(0xEB000000),
  );

  static CupertinoThemeData build(Brightness brightness) {
    final usesAppleFonts =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    final fontFamily = usesAppleFonts ? null : 'Inter';
    const defaults = CupertinoTextThemeData();

    TextStyle platformStyle(TextStyle style) =>
        usesAppleFonts ? style : style.copyWith(fontFamily: fontFamily);

    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: actionColor,
      primaryContrastingColor: _onActionColor,
      scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      barBackgroundColor: _barBackgroundColor,
      textTheme: CupertinoTextThemeData(
        primaryColor: actionColor,
        textStyle: platformStyle(defaults.textStyle),
        actionTextStyle: platformStyle(defaults.actionTextStyle)
            .copyWith(color: actionColor),
        actionSmallTextStyle: platformStyle(defaults.actionSmallTextStyle)
            .copyWith(color: actionColor),
        tabLabelTextStyle: platformStyle(defaults.tabLabelTextStyle)
            .copyWith(color: AppTheme.secondaryTextColor),
        navTitleTextStyle: platformStyle(defaults.navTitleTextStyle),
        navLargeTitleTextStyle: platformStyle(defaults.navLargeTitleTextStyle),
        navActionTextStyle: platformStyle(defaults.navActionTextStyle)
            .copyWith(color: actionColor),
        pickerTextStyle: platformStyle(defaults.pickerTextStyle),
        dateTimePickerTextStyle: platformStyle(
          defaults.dateTimePickerTextStyle,
        ),
      ),
    );
  }

  static TextStyle tabularFigures(TextStyle style) =>
      style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
