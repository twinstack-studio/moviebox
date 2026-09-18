import 'package:moviebox/l10n.dart';
import 'package:moviebox/main.dart';
import 'package:moviebox/services/analytics.dart';
import 'package:moviebox/state/app_state.dart';
import 'package:moviebox/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    appLanguage = 'en';
    AppColors.light = false;
  });

  test('Urdu is used for known strings and falls back to English', () {
    appLanguage = 'ur';
    expect(tr('Now Showing'), isNot('Now Showing'));
    expect(tr('Book Tickets'), isNot('Book Tickets'));
    // Placeholders survive translation.
    expect(tr('{0} seats: {1}', [3, 'G8, G9, G10']), contains('G8, G9, G10'));
    expect(tr('{0} seats: {1}', [3, 'G8']), startsWith('3'));
    // Unknown text is passed through rather than showing a blank.
    expect(tr('Spider-Man: Brand New Day'), 'Spider-Man: Brand New Day');

    appLanguage = 'en';
    expect(tr('Now Showing'), 'Now Showing');
    expect(tr('{0} seats: {1}', [2, 'A1, A2']), '2 seats: A1, A2');
  });

  test('Appearance setting resolves to a palette', () {
    final state = AppState();

    state.themePref = 'light';
    state.applyTheme();
    expect(AppColors.light, isTrue);
    expect(AppColors.bg.computeLuminance(), greaterThan(0.5));

    state.themePref = 'dark';
    state.applyTheme();
    expect(AppColors.light, isFalse);
    expect(AppColors.bg.computeLuminance(), lessThan(0.1));

    // Brand red stays the same in both themes.
    expect(AppColors.primary, const Color(0xFFE0243A));
  });

  test('Analytics records the booking funnel and errors', () async {
    SharedPreferences.setMockInitialValues({});
    final analytics = LocalAnalytics.instance;
    await analytics.init();
    analytics.reset();

    Analytics.log('view_movie', {'movie': 'The Odyssey'});
    Analytics.log('view_movie', {'movie': 'The Odyssey'});
    Analytics.log('purchase', {'value': 3200, 'movie': 'The Odyssey'});
    Analytics.recordError('boom', StackTrace.current);

    expect(analytics.count('view_movie'), 2);
    expect(analytics.count('purchase'), 1);
    expect(analytics.revenue, 3200);
    expect(analytics.movieViews['The Odyssey'], 2);
    expect(analytics.errors, isNotEmpty);
    expect(analytics.recent.first.name, isNotEmpty);

    analytics.reset();
    expect(analytics.count('view_movie'), 0);
  });

  testWidgets('Switching to Urdu redraws the running app', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MovieBoxApp(state: state));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Home'), findsWidgets);

    state.setLanguage('ur');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Home'), findsNothing);
    expect(find.text(tr('Home')), findsWidgets);
    expect(state.language, 'ur');

    await tester.pumpWidget(const SizedBox());
  });
}
