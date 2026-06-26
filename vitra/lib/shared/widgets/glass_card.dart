import 'dart:ui';
import 'package:flutter/material.dart';

/// Gerçek glassmorphism kart: BackdropFilter blur + gradient kenarlık
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24.0,
    this.blur = 18.0,
    this.backgroundColor,
    this.borderColor,
    this.shadows,
    this.gradient,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(borderRadius);
    final bg = backgroundColor ?? Colors.white.withValues(alpha: 0.06);
    final bc = borderColor ?? Colors.white.withValues(alpha: 0.12);

    Widget card = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: gradient == null ? bg : null,
        gradient: gradient,
        borderRadius: br,
        boxShadow: shadows,
      ),
      padding: padding,
      child: child,
    );

    // Kenarlık overlay (gradient üstünde bile görünür)
    card = Stack(
      children: [
        card,
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: br,
                border: Border.all(color: bc, width: 0.8),
              ),
            ),
          ),
        ),
      ],
    );

    Widget result = ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: card,
      ),
    );

    if (onTap != null) {
      result = GestureDetector(onTap: onTap, child: result);
    }

    return result;
  }
}

/// Sade, blur'suz premium kart (performans kritik yerlerde)
class PCard extends StatelessWidget {
  const PCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24.0,
    this.color,
    this.gradient,
    this.border,
    this.shadows,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}
