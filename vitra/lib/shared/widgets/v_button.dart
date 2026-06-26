import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/v_theme.dart';

// ── VButton — Vitra Premium Buton ────────────────────────────────────────────
//
// Kullanım:
//   VButton(label: 'Kaydet', onTap: () {})
//   VButton.ghost(label: 'İptal', onTap: () {})
//   VButton.small(label: '+250 ml', icon: Icons.add, onTap: () {})
//   VButton.danger(label: 'Sil', onTap: () {})
//   VButton.loading(label: 'Kaydediliyor...')

class VButton extends StatefulWidget {
  const VButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.loading = false,
    this.height = 54,
    this.expand = true,
    this.customColors,
  }) : _variant = _VBtnVariant.primary;

  const VButton.ghost({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.loading = false,
    this.height = 54,
    this.expand = true,
    this.customColors,
  }) : _variant = _VBtnVariant.ghost;

  const VButton.small({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.loading = false,
    this.height = 40,
    this.expand = false,
    this.customColors,
  }) : _variant = _VBtnVariant.primary;

  const VButton.danger({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.loading = false,
    this.height = 54,
    this.expand = true,
    this.customColors,
  }) : _variant = _VBtnVariant.danger;

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;
  final double height;
  final bool expand;
  final _VBtnVariant _variant;
  final List<Color>? customColors;

  @override
  State<VButton> createState() => _VButtonState();
}

enum _VBtnVariant { primary, ghost, danger }

class _VButtonState extends State<VButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(_) {
    if (widget.onTap == null || widget.loading) return;
    HapticFeedback.lightImpact();
    _ctrl.forward();
  }

  void _up(_) {
    _ctrl.reverse();
    if (!widget.loading) widget.onTap?.call();
  }

  void _cancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final vc       = context.vt;
    final disabled = widget.onTap == null || widget.loading;

    final gradColors = widget.customColors ??
        (widget._variant == _VBtnVariant.danger
            ? [const Color(0xFFF87171), const Color(0xFFEF4444)]
            : [vc.primary, vc.primaryGlow]);

    return AnimatedBuilder(
      animation: _scale,
      builder: (ctx, child) => Transform.scale(
        scale: disabled ? 1.0 : _scale.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown:   _down,
        onTapUp:     _up,
        onTapCancel: _cancel,
        child: SizedBox(
          width:  widget.expand ? double.infinity : null,
          height: widget.height,
          child: _buildBody(vc, gradColors, disabled),
        ),
      ),
    );
  }

  Widget _buildBody(VColors vc, List<Color> gradColors, bool disabled) {
    if (widget._variant == _VBtnVariant.ghost) {
      return _GhostBody(
        label:    widget.label,
        icon:     widget.icon,
        loading:  widget.loading,
        height:   widget.height,
        borderColor: vc.border,
        textColor:   vc.text,
      );
    }

    return _GradientBody(
      label:      widget.label,
      icon:       widget.icon,
      loading:    widget.loading,
      height:     widget.height,
      gradColors: gradColors,
      disabled:   disabled,
    );
  }
}

// ── Gradient gövdesi ─────────────────────────────────────────────────────────

class _GradientBody extends StatelessWidget {
  const _GradientBody({
    required this.label,
    required this.icon,
    required this.loading,
    required this.height,
    required this.gradColors,
    required this.disabled,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final double height;
  final List<Color> gradColors;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: disabled && !loading ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradColors.first.withValues(alpha: 0.40),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: gradColors.first.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        // Üst kenar parlaması
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  height: height * 0.45,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: Colors.white, size: height < 48 ? 16 : 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: height < 48 ? 13 : 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ghost gövdesi ────────────────────────────────────────────────────────────

class _GhostBody extends StatelessWidget {
  const _GhostBody({
    required this.label,
    required this.icon,
    required this.loading,
    required this.height,
    required this.borderColor,
    required this.textColor,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final double height;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Center(
        child: loading
            ? SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: textColor, strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: textColor, size: height < 48 ? 16 : 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: height < 48 ? 13 : 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
