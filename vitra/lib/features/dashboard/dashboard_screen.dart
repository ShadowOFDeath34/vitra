import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/v_theme.dart';
import '../../core/providers/navigation_provider.dart';
import 'tabs/home_tab.dart';
import '../food/food_tab.dart';
import '../water/water_tab.dart';
import '../routine/routine_tab.dart';
import '../settings/settings_tab.dart';
import '../coach/coach_tab.dart';
import '../stats/stats_tab.dart';
import '../../shared/widgets/ad_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _tabs = [
    HomeTab(),
    FoodTab(),
    CoachTab(),
    WaterTab(),
    RoutineTab(),
    StatsTab(),
    SettingsTab(), // index 6 — alt navda yok, HomeTab header ikonuyla açılır
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(selectedTabIndexProvider);
    final vc = context.vt;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: vc.isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: vc.bg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: currentIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBannerWidget(),
          _VitraBottomNav(
            currentIndex: currentIndex,
            onTap: (i) =>
                ref.read(selectedTabIndexProvider.notifier).state = i,
          ),
        ],
      ),
    );
  }
}

// ── Frosted Glass Premium Bottom Nav ─────────────────────────────────────────

class _VitraBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _VitraBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(Icons.home_rounded,        Icons.home_outlined,        'Anasayfa'),
    _NavItem(Icons.restaurant_rounded,  Icons.restaurant_outlined,  'Yemek'),
    _NavItem(Icons.psychology_rounded,  Icons.psychology_outlined,  'Koç'),
    _NavItem(Icons.water_drop_rounded,  Icons.water_drop_outlined,  'Su'),
    _NavItem(Icons.checklist_rounded,   Icons.checklist_outlined,   'Rutin'),
    _NavItem(Icons.bar_chart_rounded,   Icons.bar_chart_outlined,   'İstatistik'),
    _NavItem(Icons.settings_rounded,    Icons.settings_outlined,    'Ayarlar'),
  ];

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            // Koyu cam rengi
            color: vc.bg.withValues(alpha: vc.isDark ? 0.82 : 0.90),
            border: Border(
              top: BorderSide(
                color: vc.primary.withValues(alpha: 0.18),
                width: 0.8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 32,
                offset: const Offset(0, -10),
              ),
              BoxShadow(
                color: vc.primary.withValues(alpha: 0.07),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 62,
              child: Row(
                children: List.generate(_items.length, (i) {
                  final active = i == currentIndex;
                  return Expanded(
                    child: _NavTile(
                      item: _items[i],
                      active: active,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(i);
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav Tile ─────────────────────────────────────────────────────────────────

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 160),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pill göstergesi + ikon
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: widget.active ? 44 : 28,
              height: 30,
              decoration: widget.active
                  ? BoxDecoration(
                      // Aktif: canlı teal pill + glow
                      gradient: LinearGradient(
                        colors: [
                          vc.primary.withValues(alpha: 0.28),
                          vc.primaryGlow.withValues(alpha: 0.16),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: vc.primary.withValues(alpha: 0.40),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: vc.primary.withValues(alpha: 0.30),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ],
                    )
                  : null,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    key: ValueKey(widget.active),
                    widget.active
                        ? widget.item.activeIcon
                        : widget.item.icon,
                    color: widget.active
                        ? vc.primary
                        : vc.textMuted.withValues(alpha: 0.7),
                    size: widget.active ? 21 : 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight:
                    widget.active ? FontWeight.w700 : FontWeight.w400,
                color: widget.active
                    ? vc.primary
                    : vc.textMuted.withValues(alpha: 0.65),
                letterSpacing: widget.active ? 0.2 : 0,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;

  const _NavItem(this.activeIcon, this.icon, this.label);
}
