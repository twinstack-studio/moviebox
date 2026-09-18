import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../l10n.dart';

/// Smooth fade + slide page transition used throughout the app.
Route<T> appRoute<T>(Widget page, {String? name}) {
  return PageRouteBuilder<T>(
    settings: RouteSettings(name: name),
    transitionDuration: Duration(milliseconds: 320),
    reverseTransitionDuration: Duration(milliseconds: 260),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Future<void> showCityPicker(BuildContext context) {
  final state = AppScope.read(context);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              tr('Select your city'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final city in MockCinemaRepository.cities)
                  ListTile(
                    leading: Icon(Icons.location_city_outlined),
                    title: Text(city),
                    subtitle: Text(
                      tr('{0} cinema(s)', [
                        MockCinemaRepository.cinemasIn(city).length,
                      ]),
                    ),
                    trailing: state.city == city
                        ? Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                    onTap: () {
                      state.setCity(city);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showCinemaPicker(BuildContext context) {
  final state = AppScope.read(context);
  final cinemas = MockCinemaRepository.cinemasIn(state.city);
  return showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              tr('Your cinema in {0}', [state.city]),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          ListTile(
            leading: Icon(Icons.all_inclusive),
            title: Text(tr('All cinemas')),
            trailing: state.cinemaId == null
                ? Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            onTap: () {
              state.setCinema(null);
              Navigator.pop(ctx);
            },
          ),
          for (final c in cinemas)
            ListTile(
              leading: Icon(Icons.theaters_outlined),
              title: Text('MovieBox ${c.name}'),
              subtitle: Text(
                c.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: state.cinemaId == c.id
                  ? Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                state.setCinema(c);
                Navigator.pop(ctx);
              },
            ),
          SizedBox(height: 8),
        ],
      ),
    ),
  );
}
