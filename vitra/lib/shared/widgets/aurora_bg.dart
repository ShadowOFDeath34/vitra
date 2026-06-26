import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Yavaş nefes alan aurora gradient arka plan
class AuroraBg extends StatefulWidget {
  const AuroraBg({
    super.key,
    required this.child,
    required this.primaryColor,
    this.secondaryColor,
    this.accentColor,
    this.baseColor = Colors.transparent,
    this.duration = const Duration(seconds: 9),
    this.primaryOpacity = 0.22,
    this.height,
    this.width,
  });

  final Widget child;
  final Color primaryColor;
  final Color? secondaryColor;
  final Color? accentColor;
  final Color baseColor;
  final Duration duration;
  final double primaryOpacity;
  final double? height;
  final double? width;

  @override
  State<AuroraBg> createState() => _AuroraBgState();
}

class _AuroraBgState extends State<AuroraBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => CustomPaint(
          painter: _AuroraPainter(
            t: _ctrl.value,
            primary: widget.primaryColor,
            secondary: widget.secondaryColor ?? widget.primaryColor,
            accent: widget.accentColor,
            base: widget.baseColor,
            primaryOpacity: widget.primaryOpacity,
          ),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final Color primary;
  final Color secondary;
  final Color? accent;
  final Color base;
  final double primaryOpacity;

  const _AuroraPainter({
    required this.t,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.base,
    required this.primaryOpacity,
  });

  void _drawOrb(Canvas canvas, Size size, double cx, double cy,
      double radiusFactor, Color color, double opacity) {
    final px = cx * size.width;
    final py = cy * size.height;
    final r = radiusFactor * math.max(size.width, size.height);

    canvas.drawCircle(
      Offset(px, py),
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: opacity), Colors.transparent],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(px, py), radius: r)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (base != Colors.transparent) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..color = base);
    }

    final pi2 = 2 * math.pi;

    // Birincil orb — sekiz çizen hareket
    final px = 0.15 + 0.70 * (0.5 + 0.5 * math.sin(t * pi2));
    final py = 0.05 + 0.55 * (0.5 + 0.5 * math.cos(t * pi2 * 0.65));
    _drawOrb(canvas, size, px, py, 0.75, primary, primaryOpacity);

    // İkincil orb — karşı yön
    final sx = 0.85 - 0.65 * (0.5 + 0.5 * math.sin(t * pi2 * 0.80));
    final sy = 0.25 + 0.50 * (0.5 + 0.5 * math.cos(t * pi2 * 0.90));
    _drawOrb(canvas, size, sx, sy, 0.65, secondary, primaryOpacity * 0.75);

    // Küçük aksan orb
    if (accent != null) {
      final ax = 0.5 + 0.35 * math.sin(t * pi2 * 1.30);
      final ay = 0.5 + 0.30 * math.cos(t * pi2 * 1.55);
      _drawOrb(canvas, size, ax, ay, 0.40, accent!, primaryOpacity * 0.55);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter o) => o.t != t;
}
