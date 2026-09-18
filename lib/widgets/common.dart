import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../theme.dart';
import '../l10n.dart';

final _pkr = NumberFormat.decimalPattern('en_US');
String pkr(int amount) => 'Rs. ${_pkr.format(amount)}';
String fmtTime(DateTime d) => DateFormat('h:mm a').format(d);
String fmtDate(DateTime d) => DateFormat('EEE, d MMM').format(d);
String fmtDateLong(DateTime d) => DateFormat('EEEE, d MMMM y').format(d);

/// Opens a phone dialer / map / web link, with a friendly fallback message.
Future<void> openLink(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) throw Exception();
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(tr('Could not open. Please try again.'))),
    );
  }
}

Uri telUri(String phone) => Uri(scheme: 'tel', path: phone);
Uri mapsUri(String query) =>
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size * 1.35,
          height: size * 1.35,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(size * 0.35),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: size * 0.6,
              ),
            ],
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: size * 1.1,
          ),
        ),
        SizedBox(width: size * 0.45),
        Text(
          'MOVIEBOX',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: size * 0.18,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

/// Poster: bundled image when available, otherwise generated art.
class PosterArt extends StatelessWidget {
  final Movie movie;
  final bool showTitle;
  final double radius;
  const PosterArt({
    super.key,
    required this.movie,
    this.showTitle = true,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final art = _GeneratedPoster(movie: movie, showTitle: showTitle);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      // Generated art shows underneath while loading or if the image is
      // missing, so a poster slot is never blank.
      child: Stack(
        fit: StackFit.expand,
        children: [
          art,
          Image(
            image: AssetImage(movie.posterAsset),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            gaplessPlayback: true,
            frameBuilder: (_, child, frame, sync) => sync
                ? child
                : AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: Duration(milliseconds: 300),
                    child: child,
                  ),
            errorBuilder: (_, _, _) => SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Blurred, full-bleed poster used as a cinematic background.
class BlurredBackdrop extends StatelessWidget {
  final Movie movie;
  const BlurredBackdrop({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Transform.scale(
          scale: 1.2,
          child: PosterArt(movie: movie, showTitle: false, radius: 0),
        ),
      ),
    );
  }
}

class _GeneratedPoster extends StatelessWidget {
  final Movie movie;
  final bool showTitle;
  const _GeneratedPoster({required this.movie, required this.showTitle});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth.isFinite ? c.maxWidth : 140.0;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: movie.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: -w * 0.2,
                top: w * 0.1,
                child: Icon(
                  movie.icon,
                  size: w * 1.0,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: [0.4, 1],
                  ),
                ),
              ),
              if (showTitle)
                Positioned(
                  left: w * 0.08,
                  right: w * 0.08,
                  bottom: w * 0.08,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie.title.toUpperCase(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: (w * 0.11).clamp(11, 30).toDouble(),
                          height: 1.05,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: w * 0.03),
                      Text(
                        movie.genres.take(2).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: (w * 0.065).clamp(9, 16).toDouble(),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class RatingBadge extends StatelessWidget {
  final double rating;
  const RatingBadge(this.rating, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: AppColors.gold, size: 14),
          SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  const InfoChip(this.label, {super.key, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.muted;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c),
            SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 12, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                action!,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Loads a future with proper loading, error + retry and empty states, so a
/// slow or failed network call never leaves the user on a blank screen.
class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final Widget? loading;

  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.isEmpty,
    this.empty,
    this.loading,
  });

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future = widget.load();

  void _retry() => setState(() => _future = widget.load());

  @override
  void didUpdateWidget(covariant AsyncView<T> old) {
    super.didUpdateWidget(old);
    if (old.key != widget.key) _future = widget.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return widget.loading ??
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
        }
        if (snap.hasError) {
          return ErrorState(
            message: tr('Something went wrong. Check your connection.'),
            onRetry: _retry,
          );
        }
        final data = snap.data as T;
        if (widget.isEmpty?.call(data) ?? false) {
          return widget.empty ?? EmptyState(message: tr('Nothing here yet'));
        }
        return widget.builder(context, data);
      },
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.muted),
            SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh),
              label: Text(tr('Try again')),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.movie_filter_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.muted.withValues(alpha: 0.6)),
            SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 15),
            ),
            if (action != null) ...[SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Bottom action bar used across the booking flow.
class BottomActionBar extends StatelessWidget {
  final Widget leading;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const BottomActionBar({
    super.key,
    required this.leading,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(child: leading),
            SizedBox(width: 12),
            FilledButton(
              onPressed: loading ? null : onPressed,
              child: loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const PressableScale({super.key, required this.child, this.onTap});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}
