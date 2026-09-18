import 'package:flutter/material.dart';

import '../l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';

String themeLabel(String pref) => switch (pref) {
  'light' => tr('Light'),
  'system' => tr('System'),
  _ => tr('Dark'),
};

Future<void> showLanguagePicker(BuildContext context) {
  final state = AppScope.read(context);
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              tr('Choose language'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          _option(
            ctx,
            icon: Icons.language_rounded,
            title: tr('English'),
            subtitle: tr('English'),
            selected: state.language == 'en',
            onTap: () => state.setLanguage('en'),
          ),
          _option(
            ctx,
            icon: Icons.translate_rounded,
            title: 'اردو',
            subtitle: tr('Urdu'),
            selected: state.language == 'ur',
            onTap: () => state.setLanguage('ur'),
          ),
          SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> showThemePicker(BuildContext context) {
  final state = AppScope.read(context);
  const options = [
    ('system', Icons.brightness_auto_rounded),
    ('dark', Icons.dark_mode_rounded),
    ('light', Icons.light_mode_rounded),
  ];
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              tr('Choose appearance'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          for (final (pref, icon) in options)
            _option(
              ctx,
              icon: icon,
              title: tr(themeLabel(pref)),
              subtitle: pref == 'system' ? tr('Follow phone setting') : null,
              selected: state.themePref == pref,
              onTap: () => state.setTheme(pref),
            ),
          SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Widget _option(
  BuildContext ctx, {
  required IconData icon,
  required String title,
  String? subtitle,
  required bool selected,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: selected ? AppColors.primary : AppColors.muted),
    title: Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
    subtitle: subtitle == null
        ? null
        : Text(
            subtitle,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
    trailing: selected
        ? Icon(Icons.check_circle, color: AppColors.primary)
        : null,
    onTap: () {
      Navigator.pop(ctx);
      onTap();
    },
  );
}

/// Small "اردو / English" switch, shown during onboarding.
class LanguageChip extends StatelessWidget {
  const LanguageChip({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final urdu = state.language == 'ur';
    return Material(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => state.setLanguage(urdu ? 'en' : 'ur'),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.translate_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                urdu ? tr('English') : 'اردو',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
