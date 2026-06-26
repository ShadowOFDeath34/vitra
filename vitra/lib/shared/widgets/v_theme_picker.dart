import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/v_theme.dart';
import '../../core/providers/theme_provider.dart';

// ── VThemePicker — Tema Seçici Bottom Sheet ───────────────────────────────────
//
// Kullanım:
//   VThemePicker.show(context);

class VThemePicker extends ConsumerWidget {
  const VThemePicker({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VThemePicker(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc          = context.vt;
    final current     = ref.watch(themeProvider);

    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: vc.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle çubuğu
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: vc.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Başlık
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: Row(
              children: [
                Text(
                  'Tema Seç',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: vc.text,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: vc.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: vc.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${VitraTheme.values.length} tema',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: vc.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
            child: Text(
              'Uygulamanin görünümünü kişiselleştir',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: vc.textMuted,
              ),
            ),
          ),
          // Tema grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemCount: VitraTheme.values.length,
              itemBuilder: (context, i) {
                final theme = VitraTheme.values[i];
                final isSelected = theme == current;
                return _ThemeCard(
                  theme: theme,
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(themeProvider.notifier).setTheme(theme);
                    // Küçük gecikme sonrası kapat — animasyonu görsün
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (context.mounted) Navigator.pop(context);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tema Kartı ────────────────────────────────────────────────────────────────

class _ThemeCard extends StatefulWidget {
  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  final VitraTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc      = context.vt;
    final colors  = widget.theme.colors;
    final preview = widget.theme.previewColors;
    final label   = widget.theme.displayName;
    final isLight = !colors.isDark;

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? preview.last
                  : vc.border,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: preview.last.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                // Arka plan gradyanı
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: preview,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                // Üst parlaklık
                Positioned(
                  top: 0, left: 0, right: 0,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // İçerik
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Renk swatch'ları
                          _Swatch(color: colors.primary),
                          const SizedBox(width: 4),
                          _Swatch(color: colors.accent),
                          const Spacer(),
                          if (widget.isSelected)
                            Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isLight ? const Color(0xFF1A1A2E) : Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        colors.isDark ? 'Koyu' : 'Açık',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: (isLight
                                  ? const Color(0xFF1A1A2E)
                                  : Colors.white)
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14, height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
