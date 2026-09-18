import 'package:flutter/foundation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'analytics.dart';

/// Refresh rate.
///
/// Flutter always draws in step with the display, but many Android phones
/// keep an app at 60 Hz until it asks for a faster display mode. This picks
/// the highest mode the screen actually supports, so a 120 Hz phone animates
/// at 120 Hz and a 60 Hz phone simply stays at 60 Hz.
///
/// iPhones with ProMotion are handled by `CADisableMinimumFrameDuration` in
/// ios/Runner/Info.plist.
class Display {
  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// The mode the phone is running in, e.g. "1080x2400 @120Hz". Null when the
  /// platform does not report one.
  static String? activeMode;

  static Future<void> useHighestRefreshRate() async {
    if (!_supported) return;
    try {
      await FlutterDisplayMode.setHighRefreshRate();
      final mode = await FlutterDisplayMode.active;
      activeMode =
          '${mode.width}x${mode.height} @${mode.refreshRate.round()}Hz';
    } catch (error, stack) {
      // Older phones and some manufacturer skins don't expose display modes;
      // the app then runs at the system default instead of failing.
      Analytics.recordError(error, stack);
    }
  }
}
