import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Neon ışıltılı yay progress ring — çok katmanlı glow efekti
class NeonRing extends StatefulWidget {
  const NeonRing({
    super.key,
    required this.progress,
    required this.color,
    this.trackColor,
    this.size = 200,
    this.strokeWidth = 14,
    this.center,
    this.glowRadius = 14,
    this.animationDuration = const Duration(milliseconds: 1200),
  });

  final double progress;
  final Color color;
  final Color? trackColor;
  final double size;
  final double strokeWidth;
  final Widget? center;
  final double glowRadius;
  final Duration animationDuration;

  @override
  State<NeonRing> createState() => _NeonRingState();
}

class _NeonRingState extends State<NeonRing>
    with TickerProviderStateMixin {
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  bool get _isEmpty => widget.progress <= 0;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this, duration: widget.animationDuration);
    _progressAnim = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic),
    );
    _progressCtrl.forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (_isEmpty) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(NeonRing old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      final from = _progressAnim.value;
      _progressAnim = Tween<double>(begin: from, end: widget.progress).animate(
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic),
      );
      _progressCtrl.forward(from: 0);

      if (_isEmpty) {
        if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
      } else {
        _pulseCtrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressAnim, _pulseAnim]),
      builder: (_, child) {
        final ringOpacity = _isEmpty ? _pulseAnim.value : 1.0;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: ringOpacity,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _NeonRingPainter(
                    progress: _progressAnim.value.clamp(0.0, 1.0),
                    color: widget.color,
                    trackColor: widget.trackColor ?? widget.color.withValues(alpha: 0.10),
                    strokeWidth: widget.strokeWidth,
                    glowRadius: widget.glowRadius,
                  ),
                ),
              ),
              if (child != null) child,
            ],
          ),
        );
      },
      child: widget.center,
    );
  }
}

class _NeonRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final double glowRadius;

  const _NeonRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.glowRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawArc(
      rect, -math.pi / 2, 2 * math.pi, false,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress.clamp(0.001, 1.0);

    // Dış glow — en geniş, en düşük opaklık
    canvas.drawArc(
      rect, -math.pi / 2, sweep, false,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..strokeWidth = strokeWidth + glowRadius * 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 1.2),
    );

    // Orta glow
    canvas.drawArc(
      rect, -math.pi / 2, sweep, false,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = strokeWidth + glowRadius * 0.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 0.5),
    );

    // Ana yay — sweep gradient
    canvas.drawArc(
      rect, -math.pi / 2, sweep, false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweep,
          colors: [color.withValues(alpha: 0.55), color],
        ).createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Endpoint parlak nokta
    final endAngle = -math.pi / 2 + sweep;
    final ex = center.dx + radius * math.cos(endAngle);
    final ey = center.dy + radius * math.sin(endAngle);
    final ep = Offset(ex, ey);

    canvas.drawCircle(
      ep, strokeWidth * 1.1,
      Paint()
        ..color = color.withValues(alpha: 0.40)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawCircle(ep, strokeWidth * 0.45, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_NeonRingPainter o) =>
      o.progress != progress || o.color != color;
}
