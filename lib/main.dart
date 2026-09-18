import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/onboarding.dart';
import 'services/analytics.dart';
import 'services/display.dart';
import 'services/notifications.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crash reporting: every uncaught error is recorded (see Insights screen,
  // and Crashlytics once Firebase is connected).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Analytics.recordError(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    Analytics.recordError(error, stack);
    return true;
  };
  // In release builds, never show the red error screen: degrade gracefully.
  if (kReleaseMode) {
    ErrorWidget.builder = (_) => const SizedBox.shrink();
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting();
  await LocalAnalytics.instance.init();
  final state = AppState();
  await state.load();
  unawaited(Notifications.init());
  // Run at the screen's own refresh rate (120 Hz where the phone has it).
  unawaited(Display.useHighestRefreshRate());
  Analytics.log('app_open');

  runApp(PardaApp(state: state));
}

class PardaApp extends StatefulWidget {
  final AppState state;
  const PardaApp({super.key, required this.state});

  @override
  State<PardaApp> createState() => _PardaAppState();
}

class _PardaAppState extends State<PardaApp> with WidgetsBindingObserver {
  ThemeData? _theme;
  bool? _themeIsLight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Some phones drop the app back to 60 Hz after it has been in the
    // background, so ask again when it returns.
    if (state == AppLifecycleState.resumed) {
      unawaited(Display.useHighestRefreshRate());
    }
  }

  @override
  void didChangePlatformBrightness() =>
      widget.state.onPlatformBrightnessChanged();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          // Only rebuild the theme when light/dark actually changes.
          if (_themeIsLight != AppColors.light) {
            _theme = buildTheme();
            _themeIsLight = AppColors.light;
          }
          return MaterialApp(
            title: 'Parda Cinemas',
            debugShowCheckedModeBanner: false,
            theme: _theme,
            locale: Locale(widget.state.language),
            supportedLocales: const [Locale('en'), Locale('ur')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
