import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/meal_entry.dart';
import '../../../core/providers/daily_log_provider.dart';
import '../../../core/providers/exercise_provider.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/providers/premium_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/v_theme.dart';
import '../../../shared/widgets/aurora_bg.dart';
import '../../../shared/widgets/neon_ring.dart';

final _statsProvider = FutureProvider.autoDispose
    .family<Map<String, Map<String, dynamic>>, int>((ref, days) async {
  return FirestoreService.instance.fetchLastNDays(days);
});

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  static const _waterQuickAddMl = 250;

  late final PageController _pageController;
  int _currentPage = 0;
  int _statsDays = 7;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleAddWaterUndo() async {
    final entryId =
        await ref.read(dailyLogProvider.notifier).addWater(_waterQuickAddMl);

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: const Text('250 ml su eklendi'),
        action: SnackBarAction(
          label: 'Geri Al',
          onPressed: () {
            ref.read(dailyLogProvider.notifier).removeWaterEntry(entryId);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final log = ref.watch(dailyLogProvider);
    final exercise = ref.watch(exerciseProvider);
    final isPremium = ref.watch(isPremiumProvider);

    final calorieGoal = profile.calorieGoal;
    final caloriesConsumed = log.caloriesConsumed;
    final caloriesBurned = exercise.totalBurned;
    final caloriesNet = (caloriesConsumed - caloriesBurned).clamp(0, caloriesConsumed);
    final caloriesRemaining =
        calorieGoal > 0 ? (calorieGoal - caloriesNet).clamp(0, calorieGoal) : 0;
    final calorieProgress = calorieGoal > 0
        ? (caloriesNet / calorieGoal).clamp(0.0, 1.0)
        : 0.0;

    final waterGoalMl = profile.waterGoalMl;
    final waterGoalLiters = profile.waterGoalLiters;
    final waterConsumedMl = log.waterConsumedMl;
    final waterConsumedLiters = waterConsumedMl / 1000;
    final waterProgress = waterGoalMl > 0
        ? (waterConsumedMl / waterGoalMl).clamp(0.0, 1.0)
        : 0.0;

    final routines = log.routines;
    final routinesDone = log.routinesDoneCount;

    final vc = context.vt;

    void goPage(int idx) => _pageController.animateToPage(idx,
        duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);

    return DecoratedBox(
      decoration: BoxDecoration(color: vc.bg),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Aurora Hero ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _AuroraHeroSection(
                userName:          profile.userName,
                streakDays:        log.streakDays,
                caloriesConsumed:  caloriesConsumed,
                caloriesBurned:    caloriesBurned,
                caloriesNet:       caloriesNet,
                calorieGoal:       calorieGoal,
                caloriesRemaining: caloriesRemaining,
                calorieProgress:   calorieProgress,
                waterConsumedMl:   waterConsumedMl,
                waterGoalMl:       waterGoalMl,
                waterProgress:     waterProgress,
                routinesDone:      routinesDone,
                routinesTotal:     routines.length,
                onTapCalorie:  () => goPage(0),
                onTapWater:    () => goPage(1),
                onTapRoutine:  () => goPage(2),
                onTapSettings: () => ref.read(selectedTabIndexProvider.notifier).state = 6,
              ),
            ),

            // ── Detaylı Kartlar ─────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Detaylı Bakış',
                  subtitle: 'Kaydırarak geçiş yap',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 252,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _CalorieOverviewCard(
                          remaining: caloriesRemaining,
                          consumed: caloriesConsumed,
                          goal: calorieGoal,
                          progress: calorieProgress,
                          onAddMeal: () =>
                              ref.read(selectedTabIndexProvider.notifier).state = 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: _WaterOverviewCard(
                          litersConsumed: waterConsumedLiters,
                          litersGoal: waterGoalLiters,
                          waterConsumedMl: waterConsumedMl,
                          progress: waterProgress,
                          onAddWater: _handleAddWaterUndo,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: _RoutineOverviewCard(
                          completedCount: routinesDone,
                          totalCount: routines.length,
                          routines: routines,
                          onToggle: (id) =>
                              ref.read(dailyLogProvider.notifier).toggleRoutine(id),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: _CoachOverviewCard(
                          onOpenCoach: () =>
                              ref.read(selectedTabIndexProvider.notifier).state = 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _PageDots(currentIndex: _currentPage, count: 4),
              ),
            ),

            // ── Öğün Döküm ──────────────────────────────────────────────────
            if (log.meals.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Bugünkü Öğünler',
                    subtitle: '${log.meals.length} kayıt · ${log.caloriesConsumed} kcal',
                  ),
                ),
              ),
            if (log.meals.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _MealBreakdownSection(
                    meals: log.meals,
                    onAddMeal: () =>
                        ref.read(selectedTabIndexProvider.notifier).state = 1,
                  ),
                ),
              ),

            // ── İlerleme ────────────────────────────────────────────────────
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, log.meals.isNotEmpty ? 32 : 32, 20, 0),
              sliver: SliverToBoxAdapter(
                child: const _SectionHeader(
                  title: 'İlerleme',
                  subtitle: 'Son günlerdeki genel görünümün',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _StatsCard(
                  statsAsync: ref.watch(_statsProvider(_statsDays)),
                  calorieGoal: calorieGoal,
                  waterGoalMl: waterGoalMl,
                  isPremium: isPremium,
                  statsDays: _statsDays,
                  onDaysChanged: (d) {
                    if (d == 30 && !isPremium) {
                      Navigator.of(context).pushNamed('/premium');
                      return;
                    }
                    setState(() => _statsDays = d);
                  },
                ),
              ),
            ),

            if (!isPremium)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: const SliverToBoxAdapter(child: _PremiumBanner()),
              ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
    );
  }
}

// ── Aurora Hero Section ───────────────────────────────────────────────────────

class _AuroraHeroSection extends StatelessWidget {
  final String userName;
  final int streakDays;
  final int caloriesConsumed;
  final int caloriesBurned;
  final int caloriesNet;
  final int calorieGoal;
  final int caloriesRemaining;
  final double calorieProgress;
  final int waterConsumedMl;
  final int waterGoalMl;
  final double waterProgress;
  final int routinesDone;
  final int routinesTotal;
  final VoidCallback onTapCalorie;
  final VoidCallback onTapWater;
  final VoidCallback onTapRoutine;
  final VoidCallback onTapSettings;

  const _AuroraHeroSection({
    required this.userName,
    required this.streakDays,
    required this.caloriesConsumed,
    required this.caloriesBurned,
    required this.caloriesNet,
    required this.calorieGoal,
    required this.caloriesRemaining,
    required this.calorieProgress,
    required this.waterConsumedMl,
    required this.waterGoalMl,
    required this.waterProgress,
    required this.routinesDone,
    required this.routinesTotal,
    required this.onTapCalorie,
    required this.onTapWater,
    required this.onTapRoutine,
    required this.onTapSettings,
  });

  static const _days = [
    'Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar',
  ];
  static const _months = [
    'Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
    'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık',
  ];

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Günaydın';
    if (h >= 12 && h < 17) return 'İyi günler';
    if (h >= 17 && h < 22) return 'İyi akşamlar';
    return 'İyi geceler';
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final now = DateTime.now();
    final greeting = _greeting();
    final name = userName.trim();
    final dateStr =
        '${_days[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';
    final routineProgress =
        routinesTotal > 0 ? (routinesDone / routinesTotal) : 0.0;

    return AuroraBg(
      primaryColor: vc.primary,
      secondaryColor: AppColors.coach,
      accentColor: AppColors.gold,
      primaryOpacity: 0.20,
      duration: const Duration(seconds: 11),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              vc.surfaceHigh.withValues(alpha: 0.60),
              vc.bg.withValues(alpha: 0.80),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Selamlama + Profil + Seri ─────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (name.isNotEmpty)
                        Text(
                          greeting,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: vc.textSub,
                            letterSpacing: 0.1,
                          ),
                        ),
                      Text(
                        name.isEmpty ? '$greeting!' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: vc.text,
                          letterSpacing: -1.0,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            width: 5, height: 5,
                            decoration: BoxDecoration(
                              color: vc.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: vc.primary.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: vc.textSub,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: onTapSettings,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: vc.surface.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: vc.border.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: vc.textSub,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StreakBadge(streakDays: streakDays),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Neon Ring Hero — Kalori ───────────────────────────
            Center(
              child: NeonRing(
                progress: calorieProgress,
                color: AppColors.calories,
                trackColor: AppColors.calories.withValues(alpha: 0.10),
                size: 210,
                strokeWidth: 15,
                glowRadius: 16,
                animationDuration: const Duration(milliseconds: 1400),
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Küçük etiket
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.calories.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.calories.withValues(alpha: 0.25),
                          width: 0.7,
                        ),
                      ),
                      child: Text(
                        'BUGÜN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.calories,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Büyük kalori sayısı
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                          begin: 0, end: caloriesRemaining.toDouble()),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(
                        v.round().toString(),
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          color: vc.text,
                          height: 0.95,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'kcal kaldı',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: vc.textSub,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      calorieGoal > 0
                          ? '$caloriesNet / $calorieGoal'
                          : '$caloriesNet kcal',
                      style: TextStyle(
                        fontSize: 11,
                        color: vc.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Net Kalori Üçlüsü ─────────────────────────────────
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: vc.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: vc.border.withValues(alpha: 0.4),
                    width: 0.7,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NetCalorieItem(
                      label: 'Yenen',
                      value: caloriesConsumed,
                      color: AppColors.calories,
                    ),
                    Container(width: 1, height: 28, color: vc.border.withValues(alpha: 0.5)),
                    _NetCalorieItem(
                      label: 'Yakılan',
                      value: caloriesBurned,
                      color: const Color(0xFF22C55E),
                    ),
                    Container(width: 1, height: 28, color: vc.border.withValues(alpha: 0.5)),
                    _NetCalorieItem(
                      label: 'Net',
                      value: caloriesNet,
                      color: vc.primary,
                      bold: true,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // ── Hızlı Stat Şeridi ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _QuickStatChip(
                    icon: Icons.water_drop_rounded,
                    color: AppColors.water,
                    value: (waterConsumedMl / 1000).toStringAsFixed(1),
                    unit: 'L',
                    label: 'su içtim',
                    progress: waterProgress,
                    onTap: onTapWater,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickStatChip(
                    icon: Icons.task_alt_rounded,
                    color: vc.primary,
                    value: '$routinesDone',
                    unit: '/ $routinesTotal',
                    label: 'rutin',
                    progress: routineProgress,
                    onTap: onTapRoutine,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickStatChip(
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.streak,
                    value: '$caloriesConsumed',
                    unit: 'kcal',
                    label: 'yedim',
                    progress: calorieProgress,
                    onTap: onTapCalorie,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NetCalorieItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool bold;

  const _NetCalorieItem({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value.toDouble()),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Text(
            '${v.round()}',
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              color: bold ? color : vc.text,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: vc.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _QuickStatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String unit;
  final String label;
  final double progress;
  final VoidCallback onTap;

  const _QuickStatChip({
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
    required this.label,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.22), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: vc.text,
                      height: 1,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: vc.textSub,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: vc.textMuted),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Eski Header (artık kullanılmıyor, _AuroraHeroSection aldı) ───────────────

class _HeaderSection extends StatelessWidget {
  final String userName;
  final int streakDays;

  const _HeaderSection({required this.userName, required this.streakDays});

  static const _days = [
    'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar',
  ];
  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Günaydın';
    if (h >= 12 && h < 17) return 'İyi günler';
    if (h >= 17 && h < 22) return 'İyi akşamlar';
    return 'İyi geceler';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greeting();
    final title = userName.trim().isEmpty ? '$greeting!' : '$greeting, ${userName.trim()}!';
    final dateStr = '${_days[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';

    final vc = context.vt;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: vc.text,
                  letterSpacing: -0.9,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: vc.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 13,
                      color: vc.textSub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _StreakBadge(streakDays: streakDays),
      ],
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streakDays;
  const _StreakBadge({required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFBB6E), Color(0xFFFF7A45), Color(0xFFFF5722)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7A45).withValues(alpha: 0.38),
            blurRadius: 22,
            spreadRadius: -3,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFFFF5722).withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$streakDays',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'gün serisi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Overview Card Base ────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;

  const _OverviewCard({required this.colors, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.38),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: colors.last.withValues(alpha: 0.16),
            blurRadius: 44,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              left: -30,
              child: Container(
                width: 180,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(80),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card Title ────────────────────────────────────────────────────────────────

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;

  const _CardTitle({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.1,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Calorie Card ──────────────────────────────────────────────────────────────

class _CalorieOverviewCard extends StatelessWidget {
  final int remaining;
  final int consumed;
  final int goal;
  final double progress;
  final VoidCallback onAddMeal;

  const _CalorieOverviewCard({
    required this.remaining,
    required this.consumed,
    required this.goal,
    required this.progress,
    required this.onAddMeal,
  });

  @override
  Widget build(BuildContext context) {
    return _OverviewCard(
      colors: const [Color(0xFFFFAB6E), Color(0xFFFF6B6B), Color(0xFFE84343)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.local_fire_department_rounded,
            title: 'Kalori',
            trailing: goal > 0 ? '$consumed / $goal kcal' : null,
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: remaining.toDouble()),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Text(
                        value.round().toString(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 0.92,
                          letterSpacing: -2.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'kcal kaldı',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AnimatedProgressBar(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.20),
                      fillColors: const [Colors.white, Color(0xFFFFF2E8)],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: progress),
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => SizedBox(
                  width: 86,
                  height: 86,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size.square(86),
                        painter: _RingPainter(progress: value, color: Colors.white),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(value * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            'dolu',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          _PrimaryGhostButton(
            label: 'Öğün Ekle',
            icon: Icons.add_rounded,
            onPressed: onAddMeal,
          ),
        ],
      ),
    );
  }
}

// ── Water Card ────────────────────────────────────────────────────────────────

class _WaterOverviewCard extends StatelessWidget {
  final double litersConsumed;
  final double litersGoal;
  final int waterConsumedMl;
  final double progress;
  final Future<void> Function() onAddWater;

  const _WaterOverviewCard({
    required this.litersConsumed,
    required this.litersGoal,
    required this.waterConsumedMl,
    required this.progress,
    required this.onAddWater,
  });

  @override
  Widget build(BuildContext context) {
    final cups = (waterConsumedMl / 250).floor();
    return _OverviewCard(
      colors: const [Color(0xFF7DC8FF), Color(0xFF4A90D9), Color(0xFF2C6FBF)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.water_drop_rounded,
            title: 'Su',
            trailing: litersGoal > 0 ? 'Hedef ${litersGoal.toStringAsFixed(1)} L' : null,
          ),
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: litersConsumed),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              '${value.toStringAsFixed(1)} L',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 0.92,
                letterSpacing: -1.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                litersGoal > 0
                    ? '${(progress * 100).round()}% tamamlandı'
                    : 'Günlük su takibi aktif',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              if (cups > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$cups bardak',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _AnimatedProgressBar(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.20),
            fillColors: const [Colors.white, Color(0xFFD8EEFF)],
          ),
          const Spacer(),
          _PrimaryGhostButton(
            label: '+250 ml',
            icon: Icons.add_rounded,
            prominent: true,
            onTap: onAddWater,
          ),
        ],
      ),
    );
  }
}

// ── Routine Card ──────────────────────────────────────────────────────────────

class _RoutineOverviewCard extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final List<RoutineEntry> routines;
  final void Function(String id) onToggle;

  const _RoutineOverviewCard({
    required this.completedCount,
    required this.totalCount,
    required this.routines,
    required this.onToggle,
  });

  bool get _allDone => totalCount > 0 && completedCount >= totalCount;

  @override
  Widget build(BuildContext context) {
    return _OverviewCard(
      colors: _allDone
          ? const [Color(0xFF48C98A), Color(0xFF1A9E65), Color(0xFF0E7A4E)]
          : const [Color(0xFF68D1A6), Color(0xFF14C2A8), Color(0xFF0F5E54)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: _allDone ? Icons.celebration_rounded : Icons.task_alt_rounded,
            title: 'Rutin',
            trailing: totalCount > 0 ? '$completedCount / $totalCount' : null,
          ),
          const SizedBox(height: 10),
          if (_allDone)
            _AllDoneState(completedCount: completedCount)
          else
            _RoutineList(routines: routines, onToggle: onToggle),
        ],
      ),
    );
  }
}

class _AllDoneState extends StatelessWidget {
  final int completedCount;
  const _AllDoneState({required this.completedCount});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Harika!',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 0.95,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bugün $completedCount rutini tamamladın.',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Hepsini bitirdin, devam et!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineList extends StatelessWidget {
  final List<RoutineEntry> routines;
  final void Function(String id) onToggle;

  const _RoutineList({required this.routines, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    if (routines.isEmpty) {
      return const Expanded(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Rutin sekmesinden ekleyebilirsin.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: routines.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final r = routines[index];
          return _RoutineToggleRow(routine: r, onTap: () => onToggle(r.id));
        },
        separatorBuilder: (context2, i2) => const SizedBox(height: 7),
      ),
    );
  }
}

class _RoutineToggleRow extends StatelessWidget {
  final RoutineEntry routine;
  final VoidCallback onTap;

  const _RoutineToggleRow({required this.routine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: routine.done
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: routine.done
                  ? Colors.white.withValues(alpha: 0.40)
                  : Colors.white.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: routine.done ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: routine.done ? 0 : 0.7),
                    width: 1.5,
                  ),
                ),
                child: routine.done
                    ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  routine.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: routine.done ? FontWeight.w700 : FontWeight.w500,
                    color: Colors.white.withValues(alpha: routine.done ? 1.0 : 0.85),
                    decoration: routine.done ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.white60,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Coach Card ────────────────────────────────────────────────────────────────

class _CoachOverviewCard extends StatefulWidget {
  final VoidCallback onOpenCoach;

  const _CoachOverviewCard({required this.onOpenCoach});

  @override
  State<_CoachOverviewCard> createState() => _CoachOverviewCardState();
}

class _CoachOverviewCardState extends State<_CoachOverviewCard> {
  static const _fallbackMessages = <(String, String)>[
    ('Harika gidiyorsun!', 'Küçük adımların birikiyor. Ritmini koru, akşam kendine teşekkür edeceksin.'),
    ('Tutarlılık güçtür.', 'Motivasyon gelir geçer, ama düzen kalır. Bugün de doğru yoldasın.'),
    ('Küçük adımlar,\nbüyük değişimler.', 'En iyi yatırım kendine yaptığındır. Bugünkü çaban yarını şekillendiriyor.'),
    ('Sağlık bir maraton.', 'Sprint değil, uzun soluk ister. Bugün de bir adım öne geçtin.'),
    ('Her gün biraz\ndaha iyi.', 'Mükemmel olmak zorunda değilsin, sadece dünden iyi olman yeterli.'),
  ];

  String? _briefing;

  @override
  void initState() {
    super.initState();
    _briefing = LocalStorageService.instance.cachedBriefing;
  }

  @override
  Widget build(BuildContext context) {
    // Briefing varsa ilk cümle headline, geri kalanı body olarak böl
    String headline;
    String body;
    if (_briefing != null && _briefing!.trim().isNotEmpty) {
      final parts = _briefing!.trim().split(RegExp(r'(?<=[.!?])\s+'));
      headline = parts.first.replaceAll('"', '').trim();
      body = parts.length > 1 ? parts.sublist(1).join(' ').trim() : '';
    } else {
      (headline, body) = _fallbackMessages[DateTime.now().day % _fallbackMessages.length];
    }

    return _OverviewCard(
      colors: const [Color(0xFFAC6CF8), AppColors.habits, Color(0xFF5B3DC8)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(icon: Icons.auto_awesome_rounded, title: 'Vitra Koç'),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.4,
                  ),
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          _PrimaryGhostButton(
            label: 'Koça Sor',
            icon: Icons.arrow_forward_rounded,
            onPressed: widget.onOpenCoach,
          ),
        ],
      ),
    );
  }
}

// ── Ghost Button ──────────────────────────────────────────────────────────────

class _PrimaryGhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Future<void> Function()? onTap;
  final VoidCallback? onPressed;
  final bool prominent;

  const _PrimaryGhostButton({
    required this.label,
    required this.icon,
    this.onTap,
    this.onPressed,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    final callback = onTap != null ? () { onTap!(); } : onPressed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: callback,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: prominent ? 52 : 48,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: prominent ? Colors.white : Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: prominent ? 0.0 : 0.30),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: prominent ? AppColors.water : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  color: prominent ? AppColors.water : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Progress Bar ──────────────────────────────────────────────────────────────

class _AnimatedProgressBar extends StatelessWidget {
  final double value;
  final Color backgroundColor;
  final List<Color> fillColors;

  const _AnimatedProgressBar({
    required this.value,
    required this.backgroundColor,
    required this.fillColors,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 12,
        color: backgroundColor,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 460),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: v,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: fillColors),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: fillColors.first.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Page Dots ─────────────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  final int currentIndex;
  final int count;

  const _PageDots({required this.currentIndex, required this.count});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active
                ? vc.primary
                : vc.textMuted.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [vc.primaryGlow, vc.primary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: vc.text,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: vc.textSub,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Stats Card ────────────────────────────────────────────────────────────────

class _StatsCard extends StatefulWidget {
  final AsyncValue<Map<String, Map<String, dynamic>>> statsAsync;
  final int calorieGoal;
  final int waterGoalMl;
  final bool isPremium;
  final int statsDays;
  final void Function(int days) onDaysChanged;

  const _StatsCard({
    required this.statsAsync,
    required this.calorieGoal,
    required this.waterGoalMl,
    required this.isPremium,
    required this.statsDays,
    required this.onDaysChanged,
  });

  @override
  State<_StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<_StatsCard> {
  bool _showWater = false;

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${widget.statsDays} Günlük Özet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: vc.text,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              _DaysToggle(
                days: widget.statsDays,
                isPremium: widget.isPremium,
                onChanged: widget.onDaysChanged,
                vc: vc,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Metrik toggle
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: vc.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _StatsToggleTab(
                  label: 'Kalori',
                  icon: Icons.local_fire_department_rounded,
                  active: !_showWater,
                  activeColor: const Color(0xFFE84343),
                  onTap: () => setState(() => _showWater = false),
                  vc: vc,
                ),
                _StatsToggleTab(
                  label: 'Su',
                  icon: Icons.water_drop_rounded,
                  active: _showWater,
                  activeColor: AppColors.water,
                  onTap: () => setState(() => _showWater = true),
                  vc: vc,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          widget.statsAsync.when(
            loading: () => SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: vc.primary)),
            ),
            error: (e2, s2) => SizedBox(
              height: 40,
              child: Center(
                child: Text('Veri yüklenemedi', style: TextStyle(fontSize: 12, color: vc.textMuted)),
              ),
            ),
            data: (logs) {
              if (_showWater) return widget.statsDays == 30 ? _build30DayWaterChart(logs, vc) : _buildWaterBars(logs, vc);
              return widget.statsDays == 30 ? _build30DayChart(logs, vc) : _buildBars(logs, vc);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBars(Map<String, Map<String, dynamic>> logs, VColors vc) {
    final today = DateTime.now();
    final days = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });
    const weekLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    // Weekly summary
    final totalKcal = days.fold<int>(0, (sum, key) {
      final meals = (logs[key]?['meals'] as List<dynamic>? ?? []);
      return sum + meals.fold<int>(0, (s, m) => s + ((m['calories'] as int?) ?? 0));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (totalKcal > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: vc.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Bu hafta toplam $totalKcal kcal aldın',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: vc.primary,
                ),
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: days.map((dateKey) {
            final meals = (logs[dateKey]?['meals'] as List<dynamic>? ?? []);
            final kcal = meals.fold<int>(0, (s, m) => s + ((m['calories'] as int?) ?? 0));
            final barH = widget.calorieGoal > 0 ? (kcal / widget.calorieGoal).clamp(0.0, 1.0) * 64.0 : 0.0;
            final isToday = dateKey == days.last;
            final d = DateTime.parse(dateKey);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  children: [
                    if (isToday && kcal > 0)
                      Text(
                        'bugün',
                        style: TextStyle(fontSize: 8, color: vc.primary, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      )
                    else if (kcal > 0)
                      Text(
                        '$kcal',
                        style: TextStyle(fontSize: 8, color: vc.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 420),
                      height: barH.clamp(4.0, 64.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isToday
                              ? [vc.primaryGlow, vc.primary]
                              : [
                                  vc.primary.withValues(alpha: 0.25),
                                  vc.primary.withValues(alpha: 0.45),
                                ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      weekLabels[d.weekday - 1],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isToday ? vc.primary : vc.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [vc.primaryGlow, vc.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text('Günlük kalori', style: TextStyle(fontSize: 11, color: vc.textSub)),
            if (widget.calorieGoal > 0) ...[
              const Spacer(),
              Text('Hedef: ${widget.calorieGoal} kcal',
                  style: TextStyle(fontSize: 11, color: vc.textMuted)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _build30DayChart(Map<String, Map<String, dynamic>> logs, VColors vc) {
    final today = DateTime.now();
    final days = List.generate(30, (i) {
      final d = today.subtract(Duration(days: 29 - i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final meals = (logs[key]?['meals'] as List<dynamic>? ?? []);
      final kcal  = meals.fold<int>(0, (s, m) => s + ((m['calories'] as int?) ?? 0));
      return (key: key, kcal: kcal, date: d);
    });

    final goal   = widget.calorieGoal;
    final maxVal = days.fold<int>(0, (m, d) => math.max(m, d.kcal));
    final barMax = math.max(goal, maxVal).toDouble();

    final metDays  = days.where((d) => d.kcal > 0 && d.kcal >= goal * 0.85).length;
    final hadDays  = days.where((d) => d.kcal > 0).length;
    final totalKcal = days.fold<int>(0, (s, d) => s + d.kcal);
    final avgKcal  = hadDays > 0 ? totalKcal ~/ hadDays : 0;
    final rate     = hadDays > 0 ? (metDays * 100 ~/ hadDays) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Özet istatistik satırı ─────────────────────────────────────
        Row(
          children: [
            _MiniStat(
              label: 'Hedef tutma',
              value: '$rate%',
              color: rate >= 70 ? const Color(0xFF10B981) : AppColors.calories,
              vc: vc,
            ),
            const SizedBox(width: 8),
            _MiniStat(
              label: 'Günlük ort.',
              value: avgKcal > 0 ? '${avgKcal}k' : '—',
              color: vc.primary,
              vc: vc,
            ),
            const SizedBox(width: 8),
            _MiniStat(
              label: 'Aktif gün',
              value: '$hadDays/30',
              color: vc.textSub,
              vc: vc,
            ),
          ],
        ),
        const SizedBox(height: 14),
        // ── 30 mini bar ────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: days.map((d) {
            final isEmpty  = d.kcal == 0;
            final metGoal  = !isEmpty && d.kcal >= goal * 0.85;
            final isToday  = d.key == days.last.key;
            final barH     = barMax > 0 && !isEmpty ? (d.kcal / barMax) * 60.0 : 3.0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: barH.clamp(3.0, 60.0),
                  decoration: BoxDecoration(
                    gradient: isEmpty
                        ? null
                        : LinearGradient(
                            colors: isToday
                                ? [vc.primaryGlow, vc.primary]
                                : metGoal
                                    ? [vc.primary.withValues(alpha: 0.7), vc.primary]
                                    : [AppColors.calories.withValues(alpha: 0.3),
                                       AppColors.calories.withValues(alpha: 0.5)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                    color: isEmpty ? vc.surfaceHigh : null,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        // ── Tarih etiketleri: sadece 1. ve 30. gün ───────────────────
        Row(
          children: [
            Text(
              '${days.first.date.day} ${_shortMonth(days.first.date.month)}',
              style: TextStyle(fontSize: 9, color: vc.textMuted),
            ),
            const Spacer(),
            Text(
              '${days.last.date.day} ${_shortMonth(days.last.date.month)}',
              style: TextStyle(fontSize: 9, color: vc.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // ── Gösterge ──────────────────────────────────────────────────
        Row(
          children: [
            _LegendDot(color: vc.primary, vc: vc),
            const SizedBox(width: 4),
            Text('Hedef tuttu', style: TextStyle(fontSize: 10, color: vc.textSub)),
            const SizedBox(width: 12),
            _LegendDot(color: AppColors.calories.withValues(alpha: 0.5), vc: vc),
            const SizedBox(width: 4),
            Text('Eksik kaldı', style: TextStyle(fontSize: 10, color: vc.textSub)),
            if (goal > 0) ...[
              const Spacer(),
              Text('Hedef: ${goal}k kcal/gün',
                  style: TextStyle(fontSize: 10, color: vc.textMuted)),
            ],
          ],
        ),
      ],
    );
  }

  static String _shortMonth(int m) => const [
    '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
  ][m];

  Widget _build30DayWaterChart(Map<String, Map<String, dynamic>> logs, VColors vc) {
    final today = DateTime.now();
    final days = List.generate(30, (i) {
      final d = today.subtract(Duration(days: 29 - i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final entries = (logs[key]?['waterLog'] as List<dynamic>? ?? []);
      final ml = entries.fold<int>(0, (s, w) => s + ((w['ml'] as int?) ?? 0));
      return (key: key, ml: ml, date: d);
    });

    final goal   = widget.waterGoalMl;
    final maxVal = days.fold<int>(0, (m, d) => math.max(m, d.ml));
    final barMax = math.max(goal, maxVal).toDouble();

    final metDays  = days.where((d) => d.ml > 0 && d.ml >= goal).length;
    final hadDays  = days.where((d) => d.ml > 0).length;
    final totalMl  = days.fold<int>(0, (s, d) => s + d.ml);
    final avgL     = hadDays > 0 ? (totalMl / hadDays / 1000) : 0.0;
    final rate     = hadDays > 0 ? (metDays * 100 ~/ hadDays) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Özet istatistik satırı ─────────────────────────────────────
        Row(
          children: [
            _MiniStat(
              label: 'Hedef tutma',
              value: '$rate%',
              color: rate >= 70 ? const Color(0xFF10B981) : AppColors.water,
              vc: vc,
            ),
            const SizedBox(width: 8),
            _MiniStat(
              label: 'Günlük ort.',
              value: hadDays > 0 ? '${avgL.toStringAsFixed(1)}L' : '—',
              color: AppColors.water,
              vc: vc,
            ),
            const SizedBox(width: 8),
            _MiniStat(
              label: 'Aktif gün',
              value: '$hadDays/30',
              color: vc.textSub,
              vc: vc,
            ),
          ],
        ),
        const SizedBox(height: 14),
        // ── 30 mini bar ────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: days.map((d) {
            final isEmpty = d.ml == 0;
            final metGoal = !isEmpty && d.ml >= goal;
            final isToday = d.key == days.last.key;
            final barH    = barMax > 0 && !isEmpty ? (d.ml / barMax) * 60.0 : 3.0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: barH.clamp(3.0, 60.0),
                  decoration: BoxDecoration(
                    gradient: isEmpty
                        ? null
                        : LinearGradient(
                            colors: isToday
                                ? [const Color(0xFF7DC8FF), AppColors.water]
                                : metGoal
                                    ? [AppColors.water.withValues(alpha: 0.7), AppColors.water]
                                    : [AppColors.water.withValues(alpha: 0.2),
                                       AppColors.water.withValues(alpha: 0.35)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                    color: isEmpty ? vc.surfaceHigh : null,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              '${days.first.date.day} ${_shortMonth(days.first.date.month)}',
              style: TextStyle(fontSize: 9, color: vc.textMuted),
            ),
            const Spacer(),
            Text(
              '${days.last.date.day} ${_shortMonth(days.last.date.month)}',
              style: TextStyle(fontSize: 9, color: AppColors.water, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _LegendDot(color: AppColors.water, vc: vc),
            const SizedBox(width: 4),
            Text('Hedef tuttu', style: TextStyle(fontSize: 10, color: vc.textSub)),
            const SizedBox(width: 12),
            _LegendDot(color: AppColors.water.withValues(alpha: 0.3), vc: vc),
            const SizedBox(width: 4),
            Text('Eksik kaldı', style: TextStyle(fontSize: 10, color: vc.textSub)),
            if (goal > 0) ...[
              const Spacer(),
              Text(
                'Hedef: ${(goal / 1000).toStringAsFixed(1)}L/gün',
                style: TextStyle(fontSize: 10, color: vc.textMuted),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildWaterBars(Map<String, Map<String, dynamic>> logs, VColors vc) {
    final today = DateTime.now();
    final days = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });
    const weekLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    final totalMl = days.fold<int>(0, (sum, key) {
      final entries = (logs[key]?['waterLog'] as List<dynamic>? ?? []);
      return sum + entries.fold<int>(0, (s, w) => s + ((w['ml'] as int?) ?? 0));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (totalMl > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.water.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Bu hafta toplam ${(totalMl / 1000).toStringAsFixed(1)} L su içtin',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.water,
                ),
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: days.map((dateKey) {
            final entries = (logs[dateKey]?['waterLog'] as List<dynamic>? ?? []);
            final ml = entries.fold<int>(0, (s, w) => s + ((w['ml'] as int?) ?? 0));
            final barH = widget.waterGoalMl > 0
                ? (ml / widget.waterGoalMl).clamp(0.0, 1.0) * 64.0
                : 0.0;
            final isToday = dateKey == days.last;
            final d = DateTime.parse(dateKey);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  children: [
                    if (isToday && ml > 0)
                      Text(
                        'bugün',
                        style: const TextStyle(
                            fontSize: 8,
                            color: AppColors.water,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      )
                    else if (ml > 0)
                      Text(
                        '${(ml / 1000).toStringAsFixed(1)}L',
                        style: TextStyle(fontSize: 8, color: vc.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 420),
                      height: ml > 0 ? barH.clamp(4.0, 64.0) : 4.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isToday
                              ? [const Color(0xFF7DC8FF), AppColors.water]
                              : [
                                  AppColors.water.withValues(alpha: 0.25),
                                  AppColors.water.withValues(alpha: 0.45),
                                ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      weekLabels[d.weekday - 1],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isToday ? AppColors.water : vc.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7DC8FF), AppColors.water],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text('Günlük su', style: TextStyle(fontSize: 11, color: vc.textSub)),
            if (widget.waterGoalMl > 0) ...[
              const Spacer(),
              Text(
                'Hedef: ${(widget.waterGoalMl / 1000).toStringAsFixed(1)} L',
                style: TextStyle(fontSize: 11, color: vc.textMuted),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Stats Toggle Tab ───────────────────────────────────────────────────────────

class _StatsToggleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  final VColors vc;

  const _StatsToggleTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
    required this.vc,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: active ? vc.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: active ? activeColor : vc.textMuted),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? vc.text : vc.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Days Toggle (7G / 30G) ────────────────────────────────────────────────────

class _DaysToggle extends StatelessWidget {
  final int days;
  final bool isPremium;
  final void Function(int) onChanged;
  final VColors vc;

  const _DaysToggle({
    required this.days,
    required this.isPremium,
    required this.onChanged,
    required this.vc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: vc.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DayBtn(label: '7G', selected: days == 7, onTap: () => onChanged(7), vc: vc),
          _DayBtn(
            label: '30G',
            selected: days == 30,
            locked: !isPremium,
            onTap: () => onChanged(30),
            vc: vc,
          ),
        ],
      ),
    );
  }
}

class _DayBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  final VColors vc;

  const _DayBtn({
    required this.label,
    required this.selected,
    this.locked = false,
    required this.onTap,
    required this.vc,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? vc.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (locked)
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Icon(Icons.lock_rounded, size: 9,
                    color: selected ? Colors.white : vc.textMuted),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : vc.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ring Painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 9.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.20)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
      const start = -math.pi / 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..strokeWidth = strokeWidth + 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..color = Colors.white
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Card Wrapper ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: vc.border.withValues(alpha: 0.7),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: vc.primary.withValues(alpha: 0.04),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Premium Banner ────────────────────────────────────────────────────────────

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFBB33), Color(0xFFFF9800), Color(0xFFFF6F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.38),
            blurRadius: 18,
            spreadRadius: -3,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFFF6F00).withValues(alpha: 0.18),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('✦', style: TextStyle(fontSize: 14, color: Colors.white)),
                    SizedBox(width: 7),
                    Text(
                      'Vitra Premium',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  'Sınırsız AI · Egzersiz & kilo takibi · 30 gün grafik',
                  style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/premium'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Dene',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF6F00),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Meal Breakdown Section ────────────────────────────────────────────────────

class _MealBreakdownSection extends StatelessWidget {
  final List<MealEntry> meals;
  final VoidCallback onAddMeal;

  const _MealBreakdownSection({
    required this.meals,
    required this.onAddMeal,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;

    // Öğün tipine göre grupla, sıra: kahvaltı → öğle → akşam → ara
    final grouped = <MealType, List<MealEntry>>{};
    for (final m in meals) {
      grouped.putIfAbsent(m.type, () => []).add(m);
    }
    final orderedTypes = MealType.values.where(grouped.containsKey).toList();

    return Column(
      children: [
        for (final type in orderedTypes) ...[
          _MealTypeRow(
            type: type,
            entries: grouped[type]!,
          ),
          const SizedBox(height: 8),
        ],
        // Öğün ekle butonu
        GestureDetector(
          onTap: onAddMeal,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: vc.primarySurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: vc.primary.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 16, color: vc.primary),
                const SizedBox(width: 6),
                Text(
                  'Öğün ekle',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: vc.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MealTypeRow extends StatelessWidget {
  final MealType type;
  final List<MealEntry> entries;

  const _MealTypeRow({required this.type, required this.entries});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final totalKcal = entries.fold(0, (s, e) => s + e.calories);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border.withValues(alpha: 0.5), width: 0.7),
      ),
      child: Column(
        children: [
          // Başlık satırı
          Row(
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                type.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: vc.textSub,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Text(
                '$totalKcal kcal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: vc.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Yemek satırları
          for (final entry in entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: vc.textMuted.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: vc.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.calories} kcal',
                    style: TextStyle(fontSize: 12, color: vc.textSub),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Daily Summary Strip ───────────────────────────────────────────────────────

class _DailySummaryStrip extends StatelessWidget {
  final int caloriesConsumed;
  final int calorieGoal;
  final int waterConsumedMl;
  final int waterGoalMl;
  final int routinesDone;
  final int routinesTotal;
  final VoidCallback onTapCalorie;
  final VoidCallback onTapWater;
  final VoidCallback onTapRoutine;

  const _DailySummaryStrip({
    required this.caloriesConsumed,
    required this.calorieGoal,
    required this.waterConsumedMl,
    required this.waterGoalMl,
    required this.routinesDone,
    required this.routinesTotal,
    required this.onTapCalorie,
    required this.onTapWater,
    required this.onTapRoutine,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final calorieProgress = calorieGoal > 0
        ? (caloriesConsumed / calorieGoal).clamp(0.0, 1.0)
        : 0.0;
    final waterProgress = waterGoalMl > 0
        ? (waterConsumedMl / waterGoalMl).clamp(0.0, 1.0)
        : 0.0;
    final routineProgress = routinesTotal > 0
        ? (routinesDone / routinesTotal).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _SummaryChip(
            color: AppColors.calories,
            icon: Icons.local_fire_department_rounded,
            value: '$caloriesConsumed',
            unit: 'kcal',
            label: 'yedim',
            progress: calorieProgress,
            onTap: onTapCalorie,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryChip(
            color: AppColors.water,
            icon: Icons.water_drop_rounded,
            value: (waterConsumedMl / 1000).toStringAsFixed(1),
            unit: 'L',
            label: 'içtim',
            progress: waterProgress,
            onTap: onTapWater,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryChip(
            color: vc.primary,
            icon: Icons.task_alt_rounded,
            value: '$routinesDone',
            unit: '/ $routinesTotal',
            label: 'rutin',
            progress: routineProgress,
            onTap: onTapRoutine,
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final double progress;
  final VoidCallback onTap;

  const _SummaryChip({
    required this.color,
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: vc.text,
                    height: 1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: vc.textSub,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: vc.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini Stat ──────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VColors vc;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.vc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: vc.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Legend Dot ─────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final VColors vc;

  const _LegendDot({required this.color, required this.vc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
