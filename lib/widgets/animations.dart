import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';
import '../l10n.dart';

/// Fades and slides a child into place, staggered by [index].
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Offset from;
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.from = const Offset(0, 0.12),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 480),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 45 * widget.index.clamp(0, 12));
    if (delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(begin: widget.from, end: Offset.zero).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// Moving highlight sweep. With an opaque [base] it paints skeletons; with a
/// transparent base it adds a shine over existing content (e.g. the logo).
class Shimmer extends StatefulWidget {
  final Widget child;
  final Color? base;
  final Color? highlight;
  final Duration period;
  const Shimmer({
    super.key,
    required this.child,
    this.base,
    this.highlight,
    this.period = const Duration(milliseconds: 1400),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) => LinearGradient(
          colors: [
            widget.base ?? AppColors.surface2,
            widget.highlight ?? AppColors.shimmer,
            widget.base ?? AppColors.surface2,
          ],
          stops: [0.35, 0.5, 0.65],
          transform: _SlideGradient(_c.value),
        ).createShader(rect),
        child: child,
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double progress;
  const _SlideGradient(this.progress);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (progress * 2 - 1), 0, 0);
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class PosterRowSkeleton extends StatelessWidget {
  const PosterRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        separatorBuilder: (_, _) => SizedBox(width: 14),
        itemBuilder: (_, _) => SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(height: 203, radius: 16),
              SizedBox(height: 8),
              SkeletonBox(width: 110, height: 12, radius: 6),
              SizedBox(height: 6),
              SkeletonBox(width: 70, height: 10, radius: 5),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 12),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SkeletonBox(width: 130, height: 28, radius: 8),
                Spacer(),
                SkeletonBox(width: 90, height: 34),
              ],
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: SkeletonBox(height: 230, radius: 22),
          ),
          SizedBox(height: 32),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SkeletonBox(width: 150, height: 18, radius: 6),
          ),
          SizedBox(height: 14),
          PosterRowSkeleton(),
        ],
      ),
    );
  }
}

class GridSkeleton extends StatelessWidget {
  const GridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: LayoutBuilder(
        builder: (context, c) {
          final w = (c.maxWidth - 54) / 2;
          return GridView.builder(
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 18,
              mainAxisExtent: w * 1.45 + 60,
            ),
            itemCount: 6,
            itemBuilder: (_, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: w * 1.45, radius: 16),
                SizedBox(height: 8),
                SkeletonBox(width: w * 0.7, height: 12, radius: 6),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int count;
  final double height;
  const ListSkeleton({super.key, this.count = 3, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SkeletonBox(height: height, radius: 16),
              ),
          ],
        ),
      ),
    );
  }
}

/// Gentle endless up-and-down bob.
class Floating extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration period;
  const Floating({
    super.key,
    required this.child,
    this.amplitude = 8,
    this.period = const Duration(milliseconds: 2800),
  });

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, sin(_c.value * 2 * pi) * widget.amplitude),
        child: child,
      ),
    );
  }
}

/// Price that rolls to its new value whenever it changes.
class AnimatedPrice extends StatelessWidget {
  final int amount;
  final TextStyle style;
  const AnimatedPrice({super.key, required this.amount, required this.style});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 260),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(
            begin: Offset(0, 0.45),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, ?current],
      ),
      child: Text(pkr(amount), key: ValueKey(amount), style: style),
    );
  }
}

/// Number that counts up from zero when first shown.
class CountUp extends StatelessWidget {
  final int value;
  final String prefix;
  final TextStyle? style;
  final Duration duration;
  const CountUp({
    super.key,
    required this.value,
    this.prefix = '',
    this.style,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text('$prefix${v.round()}', style: style),
    );
  }
}

/// Circular rating gauge that fills up when shown.
class RatingRing extends StatelessWidget {
  final double rating;
  final double size;
  const RatingRing({super.key, required this.rating, this.size = 58});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: rating / 10),
      duration: Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                backgroundColor: AppColors.border,
                color: AppColors.gold,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (v * 10).toStringAsFixed(1),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                Text(
                  'IMDb',
                  style: TextStyle(fontSize: 8.5, color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One-shot confetti celebration. Place it in a Positioned.fill.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static final _colors = [
    AppColors.primary,
    AppColors.gold,
    Colors.white,
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFA855F7),
  ];
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 3200),
  )..forward();
  late final List<_Particle> _particles = _make();

  List<_Particle> _make() {
    final r = Random();
    return List.generate(90, (_) {
      final angle = -pi / 2 + (r.nextDouble() - 0.5) * pi * 0.95;
      final speed = 0.55 + r.nextDouble() * 0.9;
      return _Particle(
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 5 + r.nextDouble() * 6,
        spin: (r.nextDouble() - 0.5) * 12,
        wobble: r.nextDouble() * 2 * pi,
        color: _colors[r.nextInt(_colors.length)],
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _c.value),
        ),
      ),
    );
  }
}

class _Particle {
  final double vx, vy, size, spin, wobble;
  final Color color;
  const _Particle({
    required this.vx,
    required this.vy,
    required this.size,
    required this.spin,
    required this.wobble,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;
    final t = progress * 3.2;
    final origin = Offset(size.width / 2, size.height * 0.2);
    final opacity = (1 - progress * progress).clamp(0.0, 1.0);
    final paint = Paint();
    for (final p in particles) {
      final x =
          origin.dx + p.vx * t * size.width * 0.42 + sin(t * 3 + p.wobble) * 12;
      final y =
          origin.dy + p.vy * t * size.height * 0.32 + 0.2 * t * t * size.height;
      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.55,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

/// Live days / hours / minutes / seconds countdown to a show.
class ShowCountdown extends StatefulWidget {
  final DateTime target;
  const ShowCountdown({super.key, required this.target});

  @override
  State<ShowCountdown> createState() => _ShowCountdownState();
}

class _ShowCountdownState extends State<ShowCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.target.difference(DateTime.now());
    if (d.isNegative) {
      return Text(
        tr('Showtime! Enjoy the movie 🍿'),
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      );
    }
    final parts = <(int, String)>[
      if (d.inDays > 0) (d.inDays, 'days'),
      (d.inHours % 24, 'hrs'),
      (d.inMinutes % 60, 'min'),
      (d.inSeconds % 60, 'sec'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (i, p) in parts.indexed) ...[
          if (i > 0)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                ':',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.muted,
                ),
              ),
            ),
          _TimeBox(value: p.$1, label: tr(p.$2)),
        ],
      ],
    );
  }
}

class _TimeBox extends StatelessWidget {
  final int value;
  final String label;
  const _TimeBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ClipRect(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween(
                  begin: Offset(0, -0.6),
                  end: Offset.zero,
                ).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Text(
                value.toString().padLeft(2, '0'),
                key: ValueKey(value),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }
}
