import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/v_theme.dart';

// ── VCard — Vitra Premium Kart Sistemi ───────────────────────────────────────
//
// Kullanım:
//   VCard(child: ...)                         — standart kart
//   VCard.glass(child: ...)                   — cam/glassmorphism kart
//   VCard.accent(child: ..., color: ...)      — renkli accent kart
//   VCard.flat(child: ...)                    — gölgesiz düz kart

class VCard extends StatelessWidget {
  const VCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.accentColor,
    this.onTap,
    this.width,
    this.height,
  }) : _variant = _VCardVariant.standard;

  const VCard.glass({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.accentColor,
    this.onTap,
    this.width,
    this.height,
  }) : _variant = _VCardVariant.glass;

  const VCard.accent({
    super.key,
    required this.child,
    required Color color,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.onTap,
    this.width,
    this.height,
  })  : _variant = _VCardVariant.accent,
        accentColor = color;

  const VCard.flat({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.accentColor,
    this.onTap,
    this.width,
    this.height,
  }) : _variant = _VCardVariant.flat;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final _VCardVariant _variant;
  final Color? accentColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;

    Widget card;
    switch (_variant) {
      case _VCardVariant.glass:
        card = _GlassCard(
          vc: vc,
          borderRadius: borderRadius,
          padding: padding,
          width: width,
          height: height,
          child: child,
        );
      case _VCardVariant.accent:
        card = _AccentCard(
          vc: vc,
          accentColor: accentColor ?? vc.primary,
          borderRadius: borderRadius,
          padding: padding,
          width: width,
          height: height,
          child: child,
        );
      case _VCardVariant.flat:
        card = _FlatCard(
          vc: vc,
          borderRadius: borderRadius,
          padding: padding,
          width: width,
          height: height,
          child: child,
        );
      case _VCardVariant.standard:
        card = _StandardCard(
          vc: vc,
          borderRadius: borderRadius,
          padding: padding,
          width: width,
          height: height,
          child: child,
        );
    }

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}

enum _VCardVariant { standard, glass, accent, flat }

// ── Standard Card ─────────────────────────────────────────────────────────────

class _StandardCard extends StatelessWidget {
  const _StandardCard({
    required this.vc,
    required this.borderRadius,
    required this.child,
    this.padding,
    this.width,
    this.height,
  });

  final VColors vc;
  final double borderRadius;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: vc.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

// ── Glass Card ────────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.vc,
    required this.borderRadius,
    required this.child,
    this.padding,
    this.width,
    this.height,
  });

  final VColors vc;
  final double borderRadius;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: vc.surfaceHigh.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: vc.isDark ? 0.08 : 0.40),
              width: 1,
            ),
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── Accent Card ───────────────────────────────────────────────────────────────

class _AccentCard extends StatelessWidget {
  const _AccentCard({
    required this.vc,
    required this.accentColor,
    required this.borderRadius,
    required this.child,
    this.padding,
    this.width,
    this.height,
  });

  final VColors vc;
  final Color accentColor;
  final double borderRadius;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Sol kenar renk çizgisi
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    bottomLeft: Radius.circular(3),
                  ),
                ),
              ),
            ),
            // İçerik (sol çizgi için padding)
            Padding(
              padding: padding ?? const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Flat Card ─────────────────────────────────────────────────────────────────

class _FlatCard extends StatelessWidget {
  const _FlatCard({
    required this.vc,
    required this.borderRadius,
    required this.child,
    this.padding,
    this.width,
    this.height,
  });

  final VColors vc;
  final double borderRadius;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: vc.surfaceHigh,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: vc.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}
