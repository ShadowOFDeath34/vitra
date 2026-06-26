import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/weight_entry.dart';
import '../../core/models/exercise_entry.dart';
import '../../core/providers/daily_log_provider.dart';
import '../../core/providers/premium_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/v_theme.dart';
import '../../shared/widgets/aurora_bg.dart';

// Son N günün verisini Firestore'dan çeker
final _historyProvider = FutureProvider.autoDispose
    .family<Map<String, Map<String, dynamic>>, int>((ref, days) async {
  return FirestoreService.instance.fetchLastNDays(days);
});

// Kilo logu
final _weightLogProvider = FutureProvider.autoDispose<List<WeightEntry>>((ref) async {
  return FirestoreService.instance.fetchWeightLog(limit: 60);
});

// Bugün + son 7 günün egzersiz verileri
final _exerciseHistoryProvider = FutureProvider.autoDispose<List<ExerciseEntry>>((ref) async {
  final today = DateTime.now();
  final entries = <ExerciseEntry>[];
  for (int i = 0; i < 7; i++) {
    final day = today.subtract(Duration(days: i));
    entries.addAll(await FirestoreService.instance.fetchExercises(day));
  }
  return entries;
});

class StatsTab extends ConsumerStatefulWidget {
  const StatsTab({super.key});

  @override
  ConsumerState<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<StatsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc        = context.vt;
    final isPremium = ref.watch(isPremiumProvider);
    final profile   = ref.watch(userProfileProvider);
    final days      = isPremium ? 30 : 7;
    final history   = ref.watch(_historyProvider(days));

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aurora Hero
          _StatsHero(
            vc:        vc,
            log:       ref.watch(dailyLogProvider),
            profile:   profile,
            isPremium: isPremium,
          ),

          // Sekme çubuğu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color:        vc.surface,
                borderRadius: BorderRadius.circular(16),
                border:       Border.all(color: vc.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabCtrl,
                labelColor:           vc.primary,
                unselectedLabelColor: vc.textMuted,
                indicatorColor:       Colors.transparent,
                dividerColor:         Colors.transparent,
                labelPadding:         EdgeInsets.zero,
                indicator: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    vc.primary.withValues(alpha: 0.20),
                    vc.primaryGlow.withValues(alpha: 0.12),
                  ]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: vc.primary.withValues(alpha: 0.35)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                tabs: const [
                  Tab(text: 'Kalori'),
                  Tab(text: 'Su'),
                  Tab(text: 'Rutin'),
                  Tab(text: 'Kilo'),
                  Tab(text: 'Egzersiz'),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _CalorieStatsPage(
                  history:     history,
                  calorieGoal: profile.calorieGoal,
                  isPremium:   isPremium,
                  days:        days,
                ),
                _WaterStatsPage(
                  history:    history,
                  waterGoal:  profile.waterGoalMl,
                  isPremium:  isPremium,
                  days:       days,
                ),
                _RoutineStatsPage(
                  history:   history,
                  isPremium: isPremium,
                  days:      days,
                ),
                _WeightStatsPage(
                  isPremium: isPremium,
                  profile:   profile,
                ),
                _ExerciseStatsPage(
                  isPremium: isPremium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Aurora Hero ─────────────────────────────────────────────────────────

class _StatsHero extends StatelessWidget {
  final VColors vc;
  final DailyLog log;
  final UserProfile profile;
  final bool isPremium;

  const _StatsHero({
    required this.vc,
    required this.log,
    required this.profile,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final calPct = profile.calorieGoal > 0
        ? log.caloriesConsumed / profile.calorieGoal
        : 0.0;
    final watPct = profile.waterGoalMl > 0
        ? log.waterConsumedMl / profile.waterGoalMl
        : 0.0;
    final rutPct = log.routines.isNotEmpty
        ? log.routinesDoneCount / log.routines.length
        : 0.0;

    return SizedBox(
      height: 176,
      child: AuroraBg(
        primaryColor:   vc.primary,
        secondaryColor: AppColors.calories,
        accentColor:    AppColors.water,
        primaryOpacity: vc.isDark ? 0.22 : 0.15,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.60, 1.0],
                  colors: [Colors.transparent, Colors.transparent, vc.bg],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İstatistikler',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: vc.text,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          isPremium ? 'Son 30 gün' : 'Son 7 gün',
                          style: TextStyle(fontSize: 12, color: vc.textSub),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!isPremium)
                      GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pushNamed('/premium'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.gold, Color(0xFFF59E0B)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded,
                                  size: 11, color: Colors.white),
                              SizedBox(width: 4),
                              Text('30 gün',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  )),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatsHeroChip(
                        label: 'Kalori',
                        pct: calPct,
                        color: vc.primary),
                    const SizedBox(width: 8),
                    _StatsHeroChip(
                        label: 'Su',
                        pct: watPct,
                        color: AppColors.water),
                    const SizedBox(width: 8),
                    _StatsHeroChip(
                        label: 'Rutin',
                        pct: rutPct,
                        color: AppColors.gold),
                    const SizedBox(width: 8),
                    _StatsHeroChip(
                        label: 'Seri',
                        value: '${log.streakDays}g',
                        pct: null,
                        color: AppColors.calories),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _StatsHeroChip extends StatelessWidget {
  final String label;
  final double? pct;
  final String? value;
  final Color color;

  const _StatsHeroChip({
    required this.label,
    required this.pct,
    required this.color,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final display = value ?? '${((pct ?? 0) * 100).clamp(0, 999).round()}%';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: vc.surface.withValues(alpha: vc.isDark ? 0.75 : 0.88),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              display,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: vc.textMuted),
            ),
            if (pct != null) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct!.clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Kalori İstatistikleri ─────────────────────────────────────────────────────

class _CalorieStatsPage extends ConsumerWidget {
  final AsyncValue<Map<String, Map<String, dynamic>>> history;
  final int calorieGoal;
  final bool isPremium;
  final int days;

  const _CalorieStatsPage({
    required this.history,
    required this.calorieGoal,
    required this.isPremium,
    required this.days,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc  = context.vt;
    final log = ref.watch(dailyLogProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bugünkü durum
          _SectionLabel('Bugün', vc),
          const SizedBox(height: 8),
          _StatRow3(
            items: [
              _StatItem('Tüketilen',
                  '${log.caloriesConsumed} kcal', vc.primary),
              _StatItem('Hedef',
                  calorieGoal > 0 ? '$calorieGoal kcal' : '—', vc.textSub),
              _StatItem('Kalan',
                  calorieGoal > 0
                      ? '${(calorieGoal - log.caloriesConsumed).clamp(0, calorieGoal)} kcal'
                      : '—',
                  const Color(0xFF10B981)),
            ],
            vc: vc,
          ),
          const SizedBox(height: 20),

          // Makro dağılımı — premium
          if (isPremium) ...[
            _SectionLabel('Makro Dağılımı', vc),
            const SizedBox(height: 8),
            _MacroCard(log: log, vc: vc),
            const SizedBox(height: 20),
          ],

          // Kalori trendi
          _SectionLabel('${days} Günlük Kalori Trendi', vc),
          const SizedBox(height: 8),
          history.when(
            loading: () => _LoadingBox(vc: vc),
            error:   (_, __) => _ErrorBox(vc: vc),
            data:    (data) => _CalorieTrendChart(
              data:        data,
              goal:        calorieGoal,
              days:        days,
              isPremium:   isPremium,
              vc:          vc,
            ),
          ),
          const SizedBox(height: 20),

          // En çok yenen 5 yemek
          _SectionLabel('En Çok Yenen Yemekler', vc),
          const SizedBox(height: 8),
          history.when(
            loading: () => _LoadingBox(vc: vc),
            error:   (_, __) => _ErrorBox(vc: vc),
            data:    (data) => _TopMealsCard(data: data, vc: vc),
          ),
        ],
      ),
    );
  }
}

// ── Su İstatistikleri ─────────────────────────────────────────────────────────

class _WaterStatsPage extends ConsumerWidget {
  final AsyncValue<Map<String, Map<String, dynamic>>> history;
  final int waterGoal;
  final bool isPremium;
  final int days;

  const _WaterStatsPage({
    required this.history,
    required this.waterGoal,
    required this.isPremium,
    required this.days,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc  = context.vt;
    final log = ref.watch(dailyLogProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Bugün', vc),
          const SizedBox(height: 8),
          _StatRow3(
            items: [
              _StatItem('İçilen',
                  '${(log.waterConsumedMl / 1000).toStringAsFixed(1)} L',
                  AppColors.water),
              _StatItem('Hedef',
                  waterGoal > 0
                      ? '${(waterGoal / 1000).toStringAsFixed(1)} L'
                      : '—',
                  vc.textSub),
              _StatItem('Kalan',
                  waterGoal > 0
                      ? '${((waterGoal - log.waterConsumedMl) / 1000).clamp(0, waterGoal / 1000).toStringAsFixed(1)} L'
                      : '—',
                  const Color(0xFF10B981)),
            ],
            vc: vc,
          ),
          const SizedBox(height: 20),
          _SectionLabel('${days} Günlük Su Trendi', vc),
          const SizedBox(height: 8),
          history.when(
            loading: () => _LoadingBox(vc: vc),
            error:   (_, __) => _ErrorBox(vc: vc),
            data:    (data) => _WaterTrendChart(
              data:      data,
              goal:      waterGoal,
              days:      days,
              vc:        vc,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rutin İstatistikleri ──────────────────────────────────────────────────────

class _RoutineStatsPage extends ConsumerWidget {
  final AsyncValue<Map<String, Map<String, dynamic>>> history;
  final bool isPremium;
  final int days;

  const _RoutineStatsPage({
    required this.history,
    required this.isPremium,
    required this.days,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc  = context.vt;
    final log = ref.watch(dailyLogProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Bugün', vc),
          const SizedBox(height: 8),
          _StatRow3(
            items: [
              _StatItem('Tamamlanan',
                  '${log.routinesDoneCount}', const Color(0xFF10B981)),
              _StatItem('Toplam',
                  '${log.routines.length}', vc.textSub),
              _StatItem('Seri',
                  '${log.streakDays} gün', AppColors.gold),
            ],
            vc: vc,
          ),
          const SizedBox(height: 20),

          // Streak Grid — premium
          if (isPremium) ...[
            _SectionLabel('Haftalık Tamamlama Oranı', vc),
            const SizedBox(height: 8),
            history.when(
              loading: () => _LoadingBox(vc: vc),
              error:   (_, __) => _ErrorBox(vc: vc),
              data:    (data) => _RoutineStreakGrid(data: data, days: days, vc: vc),
            ),
            const SizedBox(height: 20),
          ] else ...[
            _PremiumUpsell(
              icon:    Icons.grid_on_rounded,
              title:   'Haftalık Streak Grid',
              desc:    'Her günün rutin tamamlama oranını ısı haritasında gör.',
              vc:      vc,
            ),
            const SizedBox(height: 20),
          ],

          _SectionLabel('${days} Günlük Rutin Trendi', vc),
          const SizedBox(height: 8),
          history.when(
            loading: () => _LoadingBox(vc: vc),
            error:   (_, __) => _ErrorBox(vc: vc),
            data:    (data) => _RoutineTrendChart(data: data, days: days, vc: vc),
          ),
        ],
      ),
    );
  }
}

// ── En Çok Yenen 5 Yemek ──────────────────────────────────────────────────────

class _TopMealsCard extends StatelessWidget {
  final Map<String, Map<String, dynamic>> data;
  final VColors vc;

  const _TopMealsCard({required this.data, required this.vc});

  @override
  Widget build(BuildContext context) {
    // Tüm yemekleri topla, ada göre kcal'i biriktir
    final totals = <String, int>{};
    for (final dayData in data.values) {
      final meals = dayData['meals'] as List<dynamic>? ?? [];
      for (final m in meals) {
        final name = (m['name'] as String? ?? '').trim();
        if (name.isEmpty) continue;
        totals[name] = (totals[name] ?? 0) + ((m['calories'] as int?) ?? 0);
      }
    }

    if (totals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: vc.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: vc.border),
        ),
        child: Center(
          child: Text('Henüz yemek kaydı yok.',
              style: TextStyle(color: vc.textMuted, fontSize: 13)),
        ),
      );
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final maxKcal = top.first.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        children: top.asMap().entries.map((entry) {
          final idx  = entry.key;
          final name = entry.value.key;
          final kcal = entry.value.value;
          final pct  = maxKcal > 0 ? kcal / maxKcal : 0.0;
          final colors = [
            vc.primary,
            AppColors.calories,
            AppColors.water,
            const Color(0xFF8B5CF6),
            const Color(0xFFF59E0B),
          ];
          return Padding(
            padding: EdgeInsets.only(bottom: idx < top.length - 1 ? 12 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colors[idx].withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('${idx + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colors[idx],
                            )),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(name,
                          style: TextStyle(
                            fontSize: 13,
                            color: vc.text,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text('$kcal kcal',
                        style: TextStyle(
                          fontSize: 12,
                          color: vc.textSub,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor: colors[idx].withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(colors[idx]),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Kilo İstatistikleri ───────────────────────────────────────────────────────

class _WeightStatsPage extends ConsumerWidget {
  final bool isPremium;
  final UserProfile profile;

  const _WeightStatsPage({required this.isPremium, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc      = context.vt;
    final entries = ref.watch(_weightLogProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Özet satırı
          entries.when(
            loading: () => _LoadingBox(vc: vc),
            error:   (_, __) => _WeightRetryBox(vc: vc, onRetry: () => ref.invalidate(_weightLogProvider)),
            data:    (list) {
              if (list.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: vc.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: vc.border),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.monitor_weight_outlined,
                            size: 40, color: vc.textMuted),
                        const SizedBox(height: 8),
                        Text('Kilo kaydı yok.\nAyarlar\'dan kilo girişi yap.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: vc.textMuted, fontSize: 13, height: 1.5)),
                      ],
                    ),
                  ),
                );
              }

              // Başlangıç: onboarding_current kaydı (sabit), yoksa ilk kayıt
              // Şu an: korumalı olmayan son kayıt, yoksa onboarding_current
              final startEntry = list.firstWhere(
                (e) => e.dateKey == 'onboarding_current',
                orElse: () => list.first,
              );
              final realEntries = list.where((e) => !e.isProtected).toList();
              final current  = realEntries.isNotEmpty ? realEntries.last.weight : startEntry.weight;
              final first    = startEntry.weight;
              final diff     = current - first;
              final target   = LocalStorageService.instance.targetWeightKg;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatRow3(
                    items: [
                      _StatItem('Şu an',
                          '${current.toStringAsFixed(1)} kg',
                          vc.primary),
                      _StatItem('Başlangıç',
                          '${first.toStringAsFixed(1)} kg',
                          vc.textSub),
                      _StatItem(
                          diff < 0 ? 'Verilen' : 'Alınan',
                          '${diff.abs().toStringAsFixed(1)} kg',
                          diff < 0
                              ? const Color(0xFF10B981)
                              : AppColors.calories),
                    ],
                    vc: vc,
                  ),
                  if (target != null && target > 0) ...[
                    const SizedBox(height: 12),
                    _WeightTargetCard(
                      current:   current,
                      target:    target,
                      heightCm:  LocalStorageService.instance.profileHeightCm,
                      vc:        vc,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _SectionLabel('Kilo Grafiği', vc),
                  const SizedBox(height: 8),
                  _WeightChart(
                    entries: list.where((e) => e.dateKey != 'onboarding_target').toList(),
                    vc: vc,
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('Kayıtlar', vc),
                  const SizedBox(height: 8),
                  _WeightLogList(entries: list, vc: vc, ref: ref),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeightTargetCard extends StatelessWidget {
  final double current;
  final double target;
  final double? heightCm;
  final VColors vc;

  const _WeightTargetCard({
    required this.current,
    required this.target,
    required this.heightCm,
    required this.vc,
  });

  @override
  Widget build(BuildContext context) {
    final diff    = (target - current).abs();
    final reached = (current - target).abs() < 0.5;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: vc.border),
      ),
      child: Row(
        children: [
          Icon(
            reached
                ? Icons.check_circle_rounded
                : Icons.flag_rounded,
            color: reached
                ? const Color(0xFF10B981)
                : vc.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reached ? 'Hedefine ulaştın!' : 'Hedef: ${target.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: reached ? const Color(0xFF10B981) : vc.text,
                  ),
                ),
                if (!reached)
                  Text(
                    '${diff.toStringAsFixed(1)} kg kaldı',
                    style: TextStyle(fontSize: 12, color: vc.textSub),
                  ),
              ],
            ),
          ),
          // BMI badge
          if (current > 0 && heightCm != null) ...[
            _BmiBadge(
              weightKg: current,
              heightCm: heightCm!,
              vc:       vc,
            ),
          ],
        ],
      ),
    );
  }
}

class _BmiBadge extends StatelessWidget {
  final double weightKg;
  final double heightCm;
  final VColors vc;

  const _BmiBadge({
    required this.weightKg,
    required this.heightCm,
    required this.vc,
  });

  @override
  Widget build(BuildContext context) {
    final h = heightCm / 100;
    final bmi = weightKg / (h * h);
    final (label, color) = switch (bmi) {
      < 18.5 => ('Zayıf',   const Color(0xFF60A5FA)),
      < 25.0 => ('Normal',  const Color(0xFF10B981)),
      < 30.0 => ('Fazla',   const Color(0xFFF59E0B)),
      _      => ('Obez',    AppColors.calories),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            bmi.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final VColors vc;

  const _WeightChart({required this.entries, required this.vc});

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: vc.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: vc.border),
        ),
        child: Center(
          child: Text('Grafik için en az 2 kayıt gerekli.',
              style: TextStyle(color: vc.textMuted, fontSize: 13)),
        ),
      );
    }

    final weights = entries.map((e) => e.weight).toList();
    final minW    = weights.reduce(math.min);
    final maxW    = weights.reduce(math.max);

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
      ),
      child: CustomPaint(
        painter: _WeightChartPainter(
          entries: entries,
          minW:    minW,
          maxW:    maxW,
          color:   vc.primary,
          gridColor: vc.border,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<WeightEntry> entries;
  final double minW;
  final double maxW;
  final Color color;
  final Color gridColor;

  _WeightChartPainter({
    required this.entries,
    required this.minW,
    required this.maxW,
    required this.color,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;
    final range = (maxW - minW).clamp(1.0, double.infinity);
    final pad   = 4.0;
    final w     = size.width;
    final h     = size.height - pad * 2;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 3; i++) {
      final y = pad + h / 3 * i;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final fillPath = Path();
    final linePath = Path();
    final points   = <Offset>[];

    for (int i = 0; i < entries.length; i++) {
      final x = w * i / (entries.length - 1);
      final y = pad + h * (1 - (entries[i].weight - minW) / range);
      points.add(Offset(x, y));
    }

    fillPath.moveTo(points.first.dx, size.height);
    linePath.moveTo(points.first.dx, points.first.dy);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
      linePath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Nokta
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(points.last, 4, dotPaint);
    canvas.drawCircle(points.last, 4,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_WeightChartPainter old) =>
      old.entries != entries || old.color != color;
}

class _WeightLogList extends StatelessWidget {
  final List<WeightEntry> entries;
  final VColors vc;
  final WidgetRef ref;

  const _WeightLogList({
    required this.entries,
    required this.vc,
    required this.ref,
  });

  Future<void> _delete(WeightEntry entry) async {
    if (entry.isProtected) return;
    await FirestoreService.instance.deleteWeightEntry(entry.dateKey);
    ref.invalidate(_weightLogProvider);

    final realEntries = entries.where((e) => !e.isProtected && e.dateKey != entry.dateKey).toList();
    if (realEntries.isEmpty) {
      // Tüm gerçek kayıtlar silindi → onboarding başlangıç kilosuna dön
      final startEntry = entries.firstWhere(
        (e) => e.dateKey == 'onboarding_current',
        orElse: () => entries.first,
      );
      await ref.read(userProfileProvider.notifier).updateWeightKg(startEntry.weight);
    } else {
      final wasLastReal = entry.dateKey == entries.lastWhere((e) => !e.isProtected).dateKey;
      if (wasLastReal) {
        await ref.read(userProfileProvider.notifier).updateWeightKg(realEntries.last.weight);
      }
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    final vc = Theme.of(context).extension<VColors>()!;
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: vc.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Kaydı sil',
            style: TextStyle(
                color: vc.text, fontWeight: FontWeight.w700, fontSize: 17)),
        content: Text('Bu kilo kaydı silinecek.',
            style: TextStyle(color: vc.textSub, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('İptal', style: TextStyle(color: vc.textMuted, fontSize: 14)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil',
                style: TextStyle(
                    color: AppColors.calories,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _entryRow(WeightEntry entry, double diff, bool showDiff) {
    final label = entry.label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (entry.isProtected) ...[
            Icon(Icons.lock_outline_rounded, size: 13, color: vc.primary),
            const SizedBox(width: 5),
            Text(
              label ?? _formatDate(entry.date),
              style: TextStyle(fontSize: 13, color: vc.primary, fontWeight: FontWeight.w600),
            ),
          ] else
            Text(
              _formatDate(entry.date),
              style: TextStyle(fontSize: 13, color: vc.textSub),
            ),
          const Spacer(),
          Text(
            '${entry.weight.toStringAsFixed(1)} kg',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: entry.isProtected ? vc.primary : vc.text,
            ),
          ),
          if (showDiff && !entry.isProtected) ...[
            const SizedBox(width: 8),
            Icon(
              diff < 0 ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 12,
              color: diff < 0 ? const Color(0xFF10B981) : AppColors.calories,
            ),
            Text(
              '${diff.abs().toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 11,
                color: diff < 0 ? const Color(0xFF10B981) : AppColors.calories,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reversed = entries.reversed.take(10).toList();
    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        children: reversed.asMap().entries.map((e) {
          final idx    = e.key;
          final entry  = e.value;
          final isLast = idx == reversed.length - 1;
          final diff   = idx < reversed.length - 1
              ? entry.weight - reversed[idx + 1].weight
              : 0.0;
          return Column(
            children: [
              if (entry.isProtected)
                _entryRow(entry, diff, false)
              else
                Dismissible(
                  key: Key(entry.dateKey),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDelete(context),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: vc.surfaceHigh,
                      borderRadius: isLast
                          ? const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16))
                          : BorderRadius.zero,
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        color: vc.textSub, size: 22),
                  ),
                  onDismissed: (_) => _delete(entry),
                  child: _entryRow(entry, diff, idx < reversed.length - 1),
                ),
              if (!isLast) Divider(height: 1, color: vc.border),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

// ── Egzersiz İstatistikleri ───────────────────────────────────────────────────

class _ExerciseStatsPage extends ConsumerStatefulWidget {
  final bool isPremium;
  const _ExerciseStatsPage({required this.isPremium});

  @override
  ConsumerState<_ExerciseStatsPage> createState() => _ExerciseStatsPageState();
}

class _ExerciseStatsPageState extends ConsumerState<_ExerciseStatsPage> {
  static const _catColors = {
    'cardio':      Color(0xFFEF4444),
    'strength':    Color(0xFF8B5CF6),
    'flexibility': Color(0xFF10B981),
    'other':       Color(0xFF6B7280),
  };
  static const _catLabels = {
    'cardio':      'Kardiyo',
    'strength':    'Güç',
    'flexibility': 'Esneklik',
    'other':       'Diğer',
  };

  IconData _catIcon(String cat) => switch (cat) {
    'cardio'      => Icons.directions_run_rounded,
    'strength'    => Icons.fitness_center_rounded,
    'flexibility' => Icons.self_improvement_rounded,
    _             => Icons.sports_rounded,
  };

  String _fmtDate(DateTime d) {
    const m = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
        'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${d.day} ${m[d.month]}';
  }

  void _showAddSheet() {
    final profile  = ref.read(userProfileProvider);
    final weightKg = profile.weightKg ?? 70.0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 1.0,
        expand: false,
        builder: (_, scrollCtrl) => _ExerciseAddSheet(
          weightKg: weightKg,
          scrollController: scrollCtrl,
          onAdd: (entry) async {
            await FirestoreService.instance.saveExercise(entry);
            if (mounted) ref.invalidate(_exerciseHistoryProvider);
          },
          onCalorieBonus: (burned) async {
            final current = ref.read(userProfileProvider).calorieGoal;
            await ref.read(userProfileProvider.notifier)
                .updateCalorieGoal(current + burned);
          },
          onWaterBonus: (ml) async {
            final current = ref.read(userProfileProvider).waterGoalMl;
            await ref.read(userProfileProvider.notifier)
                .updateWaterGoal(current + ml);
          },
        ),
      ),
    );
  }

  Future<void> _delete(ExerciseEntry entry) async {
    final burned  = entry.caloriesBurned;
    final waterMl = entry.waterLossMl;

    await FirestoreService.instance.deleteExercise(entry);
    if (mounted) ref.invalidate(_exerciseHistoryProvider);

    if (!mounted) return;

    // Kalori hedefi rollback
    if (burned > 0) {
      final reduce = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ctx.vt.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Kalori Hedefini Azalt?',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ctx.vt.text)),
          content: Text(
            'Bu egzersiz için $burned kcal eklemiştin. Kalori hedefinden bu miktarı çıkaralım mı?',
            style: TextStyle(fontSize: 14, color: ctx.vt.textSub),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Hayır',
                  style: TextStyle(color: ctx.vt.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Evet, düşür',
                  style: TextStyle(
                      color: ctx.vt.primary,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (reduce == true && mounted) {
        final current = ref.read(userProfileProvider).calorieGoal;
        await ref
            .read(userProfileProvider.notifier)
            .updateCalorieGoal((current - burned).clamp(1200, 99999));
      }
    }

    if (!mounted) return;

    // Su hedefi rollback
    if (waterMl > 0) {
      final reduce = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ctx.vt.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Su Hedefini Azalt?',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ctx.vt.text)),
          content: Text(
            'Bu egzersiz için ~$waterMl ml su hedefi eklemiştin. Su hedefinden bu miktarı çıkaralım mı?',
            style: TextStyle(fontSize: 14, color: ctx.vt.textSub),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Hayır',
                  style: TextStyle(color: ctx.vt.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Evet, düşür',
                  style: TextStyle(
                      color: AppColors.water,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (reduce == true && mounted) {
        final current = ref.read(userProfileProvider).waterGoalMl;
        await ref
            .read(userProfileProvider.notifier)
            .updateWaterGoal((current - waterMl).clamp(1000, 99999));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc      = context.vt;
    final asyncEx = ref.watch(_exerciseHistoryProvider);

    return Stack(
      children: [
        asyncEx.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (_, __) => Center(child: _ErrorBox(vc: vc)),
          data:    (entries) => _buildContent(context, entries, vc),
        ),
        // FAB — egzersiz ekle
        Positioned(
          bottom: 100,
          right: 20,
          child: GestureDetector(
            onTap: _showAddSheet,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [vc.primary, vc.primaryGlow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: vc.primary.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
      BuildContext context, List<ExerciseEntry> entries, VColors vc) {
    final today = DateTime.now();
    final todayEntries = entries.where((e) =>
        e.time.year == today.year &&
        e.time.month == today.month &&
        e.time.day == today.day).toList();

    final totalKcal    = entries.fold<int>(0, (s, e) => s + e.caloriesBurned);
    final totalMin     = entries.fold<int>(0, (s, e) => s + e.durationMin);
    final totalWaterMl = entries.fold<int>(0, (s, e) => s + e.waterLossMl);
    final activeDaySet = <String>{};
    for (final e in entries) {
      activeDaySet.add('${e.time.year}-${e.time.month}-${e.time.day}');
    }

    // Kategori dağılımı
    final catKcal = <String, int>{};
    for (final e in entries) {
      catKcal[e.category] = (catKcal[e.category] ?? 0) + e.caloriesBurned;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Haftalık özet kartlar ─────────────────────────────────────
          _SectionLabel('Bu Hafta', vc),
          const SizedBox(height: 8),
          _StatRow3(
            items: [
              _StatItem('Aktif Gün', '${activeDaySet.length}/7',
                  const Color(0xFF10B981)),
              _StatItem('Yakılan', '$totalKcal kcal', AppColors.calories),
              _StatItem('Süre', '${(totalMin / 60).toStringAsFixed(1)} sa',
                  vc.primary),
            ],
            vc: vc,
          ),
          const SizedBox(height: 8),
          _StatRow3(
            items: [
              _StatItem('Su Kaybı',
                  totalWaterMl >= 1000
                      ? '${(totalWaterMl / 1000).toStringAsFixed(1)} L'
                      : '$totalWaterMl ml',
                  AppColors.water),
              _StatItem('Ort. Süre',
                  entries.isEmpty
                      ? '—'
                      : '${(totalMin / entries.length).round()} dk',
                  vc.textSub),
              _StatItem('Egzersiz', '${entries.length}', vc.primary),
            ],
            vc: vc,
          ),
          const SizedBox(height: 20),

          // ── 7 günlük aktivite heatmap ─────────────────────────────────
          _SectionLabel('Aktivite Haritası', vc),
          const SizedBox(height: 8),
          _ActivityHeatmap(entries: entries, vc: vc),
          const SizedBox(height: 20),

          // ── Günlük yakılan çubuğu ────────────────────────────────────
          _SectionLabel('Günlük Yakılan (7 gün)', vc),
          const SizedBox(height: 8),
          _ExerciseBarChart(entries: entries, days: 7, vc: vc),
          const SizedBox(height: 20),

          // ── Kategori dağılımı ────────────────────────────────────────
          if (entries.isNotEmpty) ...[
            _SectionLabel('Kategori Dağılımı', vc),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: vc.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: vc.border),
              ),
              child: Row(
                children: [
                  for (final cat in ['cardio', 'strength', 'flexibility', 'other'])
                    if ((catKcal[cat] ?? 0) > 0)
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _catColors[cat]!.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_catIcon(cat),
                                  size: 20, color: _catColors[cat]),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${catKcal[cat]!} kcal',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _catColors[cat],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              _catLabels[cat]!,
                              style: TextStyle(
                                fontSize: 10,
                                color: vc.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Bugünün egzersizleri ──────────────────────────────────────
          Row(
            children: [
              Expanded(child: _SectionLabel('Bugün', vc)),
              GestureDetector(
                onTap: _showAddSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: vc.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: vc.primary),
                      const SizedBox(width: 4),
                      Text('Egzersiz Ekle',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: vc.primary,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (todayEntries.isEmpty)
            _ExerciseEmptyCard(vc: vc, onAdd: _showAddSheet)
          else
            _ExerciseList(
              entries: todayEntries,
              vc: vc,
              catColors: _catColors,
              catIcon: _catIcon,
              fmtDate: _fmtDate,
              onDelete: _delete,
            ),
          const SizedBox(height: 20),

          // ── Son 7 günün geçmişi ───────────────────────────────────────
          if (entries.isNotEmpty) ...[
            _SectionLabel('Geçmiş (7 gün)', vc),
            const SizedBox(height: 8),
            _ExerciseList(
              entries: entries.where((e) =>
                !(e.time.year == today.year &&
                  e.time.month == today.month &&
                  e.time.day == today.day)).toList(),
              vc: vc,
              catColors: _catColors,
              catIcon: _catIcon,
              fmtDate: _fmtDate,
              onDelete: _delete,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Aktivite heatmap — 7 gün kare ─────────────────────────────────────────────

class _ActivityHeatmap extends StatelessWidget {
  final List<ExerciseEntry> entries;
  final VColors vc;
  const _ActivityHeatmap({required this.entries, required this.vc});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    const dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
      ),
      child: Row(
        children: List.generate(7, (i) {
          final day = today.subtract(Duration(days: 6 - i));
          final kcal = entries
              .where((e) =>
                  e.time.year == day.year &&
                  e.time.month == day.month &&
                  e.time.day == day.day)
              .fold<int>(0, (s, e) => s + e.caloriesBurned);
          final isToday = i == 6;
          final hasActivity = kcal > 0;
          final intensity = kcal > 500 ? 1.0 : kcal > 200 ? 0.65 : kcal > 0 ? 0.35 : 0.0;

          return Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasActivity
                        ? AppColors.calories.withValues(alpha: intensity)
                        : vc.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isToday
                          ? vc.primary
                          : hasActivity
                              ? AppColors.calories.withValues(alpha: 0.4)
                              : vc.border,
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: hasActivity
                      ? Center(
                          child: Icon(Icons.bolt_rounded,
                              size: 18, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  dayLabels[day.weekday - 1],
                  style: TextStyle(
                    fontSize: 10,
                    color: isToday ? vc.primary : vc.textMuted,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (hasActivity)
                  Text(
                    '${kcal}k',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.calories,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Egzersiz listesi — silme destekli ─────────────────────────────────────────

class _ExerciseList extends StatelessWidget {
  final List<ExerciseEntry> entries;
  final VColors vc;
  final Map<String, Color> catColors;
  final IconData Function(String) catIcon;
  final String Function(DateTime) fmtDate;
  final Future<void> Function(ExerciseEntry) onDelete;

  const _ExerciseList({
    required this.entries,
    required this.vc,
    required this.catColors,
    required this.catIcon,
    required this.fmtDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final shown = entries.reversed.take(20).toList();
    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        children: shown.asMap().entries.map((e) {
          final idx   = e.key;
          final entry = e.value;
          final color = catColors[entry.category] ?? vc.primary;
          final isLast = idx == shown.length - 1;
          return Column(
            children: [
              Dismissible(
                key: Key(entry.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => showDialog<bool>(
                  context: context,
                  builder: (_) {
                    final dvc = Theme.of(context).extension<VColors>()!;
                    return AlertDialog(
                      backgroundColor: dvc.surface,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: Text('Egzersizi sil',
                          style: TextStyle(
                              color: dvc.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 17)),
                      content: Text('Bu egzersiz kaydı silinecek.',
                          style: TextStyle(color: dvc.textSub, fontSize: 14)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('İptal',
                              style: TextStyle(
                                  color: dvc.textMuted, fontSize: 14)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Sil',
                              style: TextStyle(
                                  color: AppColors.calories,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ),
                      ],
                    );
                  },
                ),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: vc.surfaceHigh,
                    borderRadius: isLast
                        ? const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16))
                        : BorderRadius.zero,
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      color: vc.textSub, size: 22),
                ),
                onDismissed: (_) => onDelete(entry),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(catIcon(entry.category),
                            size: 18, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.name,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: vc.text)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.timer_outlined,
                                    size: 11, color: vc.textMuted),
                                const SizedBox(width: 3),
                                Text('${entry.durationMin} dk',
                                    style: TextStyle(
                                        fontSize: 11, color: vc.textMuted)),
                                const SizedBox(width: 8),
                                Icon(Icons.calendar_today_outlined,
                                    size: 11, color: vc.textMuted),
                                const SizedBox(width: 3),
                                Text(fmtDate(entry.time),
                                    style: TextStyle(
                                        fontSize: 11, color: vc.textMuted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${entry.caloriesBurned} kcal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.calories,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '~${entry.waterLossMl} ml',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.water,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast) Divider(height: 1, color: vc.border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Boş durum kartı ───────────────────────────────────────────────────────────

class _ExerciseEmptyCard extends StatelessWidget {
  final VColors vc;
  final VoidCallback onAdd;
  const _ExerciseEmptyCard({required this.vc, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: vc.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: vc.primary.withValues(alpha: 0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.calories.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.fitness_center_rounded,
                  size: 28, color: AppColors.calories),
            ),
            const SizedBox(height: 12),
            Text(
              'Bugün egzersiz kaydı yok',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: vc.text),
            ),
            const SizedBox(height: 4),
            Text(
              'Dokunarak egzersiz ekle',
              style: TextStyle(fontSize: 12, color: vc.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Egzersiz Ekleme Sheet ─────────────────────────────────────────────────────

class _ExerciseAddSheet extends StatefulWidget {
  final double weightKg;
  final ScrollController scrollController;
  final Future<void> Function(ExerciseEntry) onAdd;
  final Future<void> Function(int burned)? onCalorieBonus;
  final Future<void> Function(int waterMl)? onWaterBonus;

  const _ExerciseAddSheet({
    required this.weightKg,
    required this.scrollController,
    required this.onAdd,
    this.onCalorieBonus,
    this.onWaterBonus,
  });

  @override
  State<_ExerciseAddSheet> createState() => _ExerciseAddSheetState();
}

class _ExerciseAddSheetState extends State<_ExerciseAddSheet> {
  int? _selectedPreset;
  String _filterCat    = 'all';
  final _durationCtrl  = TextEditingController(text: '30');
  bool _saving         = false;

  static const _catLabels = {
    'all':         'Tümü',
    'cardio':      'Kardiyo',
    'strength':    'Güç',
    'flexibility': 'Esneklik',
    'other':       'Diğer',
  };
  static const _catEmoji = {
    'cardio': '🏃', 'strength': '💪', 'flexibility': '🧘', 'other': '⚡',
  };

  List<(int, ({String name, String category, double met}))> get _filtered {
    final all = ExerciseEntry.presets.asMap().entries
        .map((e) => (e.key, e.value))
        .toList();
    if (_filterCat == 'all') return all;
    return all.where((t) => t.$2.category == _filterCat).toList();
  }

  double get _met => _selectedPreset != null
      ? ExerciseEntry.presets[_selectedPreset!].met
      : 5.0;
  String get _name => _selectedPreset != null
      ? ExerciseEntry.presets[_selectedPreset!].name
      : '';
  String get _category => _selectedPreset != null
      ? ExerciseEntry.presets[_selectedPreset!].category
      : 'other';
  int get _duration => int.tryParse(_durationCtrl.text) ?? 30;
  int get _previewCalories => ExerciseEntry.calcCalories(
        met: _met, durationMin: _duration, weightKg: widget.weightKg);
  bool get _canSave => _selectedPreset != null && _duration > 0;

  Future<void> _submit() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final entry = ExerciseEntry(
      id:             DateTime.now().millisecondsSinceEpoch.toString(),
      name:           _name,
      category:       _category,
      met:            _met,
      durationMin:    _duration,
      caloriesBurned: _previewCalories,
      time:           DateTime.now(),
    );
    await widget.onAdd(entry);
    if (!mounted) return;

    // Kalori hedefi artırma sorusu
    final burned = entry.caloriesBurned;
    if (widget.onCalorieBonus != null && burned > 0) {
      final add = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.vt.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Kalori Hedefini Arttır?',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: context.vt.text,
            ),
          ),
          content: Text(
            'Bugün $burned kcal yaktın. Kalori hedefine bu miktarı ekleyelim mi? Böylece daha fazla yiyebilirsin.',
            style: TextStyle(fontSize: 14, color: context.vt.textSub),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Hayır', style: TextStyle(color: context.vt.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Evet, ekle',
                  style: TextStyle(color: context.vt.primary,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (add == true && mounted) {
        await widget.onCalorieBonus!(burned);
      }
    }

    if (!mounted) return;

    // Su hedefi artırma sorusu
    final waterMl = entry.waterLossMl;
    if (widget.onWaterBonus != null && waterMl > 0) {
      final addWater = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ctx.vt.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Su Hedefini Arttır?',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ctx.vt.text),
          ),
          content: Text(
            'Bu egzersizde yaklaşık $waterMl ml su kaybedersin. Su hedefine bu miktarı ekleyelim mi?',
            style: TextStyle(fontSize: 14, color: ctx.vt.textSub),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Hayır',
                  style: TextStyle(color: ctx.vt.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Evet, ekle',
                  style: TextStyle(
                      color: AppColors.water,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (addWater == true && mounted) {
        await widget.onWaterBonus!(waterMl);
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc     = context.vt;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final items  = _filtered;

    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: vc.textMuted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.calories,
                          AppColors.calories.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fitness_center_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Egzersiz Ekle',
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: vc.text,
                      )),
                ),
                // Canlı önizleme badge
                if (_canSave)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.calories.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.calories.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '$_previewCalories kcal',
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        color: AppColors.calories,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── Kategori filtresi ─────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: _catLabels.entries.map((e) {
                final sel = _filterCat == e.key;
                return GestureDetector(
                  onTap: () => setState(() {
                    _filterCat = e.key;
                    _selectedPreset = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? vc.primary : vc.bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? vc.primary : vc.border),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : vc.textSub,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // ── Egzersiz listesi (scrollable) ─────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              itemCount: items.length,
              itemBuilder: (_, idx) {
                final (i, preset) = items[idx];
                final sel         = _selectedPreset == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPreset = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? vc.primarySurface : vc.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? vc.primary : vc.border,
                          width: sel ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _catEmoji[preset.category] ?? '⚡',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            preset.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: sel ? vc.primary : vc.text,
                            ),
                          ),
                        ),
                        if (sel)
                          Icon(Icons.check_circle_rounded,
                              color: vc.primary, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // ── Süre + kaydet ─────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
            decoration: BoxDecoration(
              color: vc.surface,
              border: Border(top: BorderSide(color: vc.border)),
            ),
            child: Row(
              children: [
                // Süre girişi
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: vc.text),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '30',
                      hintStyle: TextStyle(color: vc.textMuted),
                      filled: true,
                      fillColor: vc.bg,
                      suffixText: 'dk',
                      suffixStyle: TextStyle(
                          fontSize: 13, color: vc.textSub),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _canSave && !_saving ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.calories,
                        disabledBackgroundColor:
                            AppColors.calories.withValues(alpha: 0.35),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(
                              _canSave
                                  ? 'Kaydet  ·  $_previewCalories kcal'
                                  : 'Aktivite Seç',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseBarChart extends StatelessWidget {
  final List<ExerciseEntry> entries;
  final int days;
  final VColors vc;

  const _ExerciseBarChart({
    required this.entries,
    required this.days,
    required this.vc,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dailyKcal = List.generate(days, (i) {
      final d = today.subtract(Duration(days: days - 1 - i));
      return entries
          .where((e) =>
              e.time.year == d.year &&
              e.time.month == d.month &&
              e.time.day == d.day)
          .fold<double>(0, (s, e) => s + e.caloriesBurned);
    });

    final maxVal = dailyKcal.reduce(math.max).clamp(1.0, double.infinity);
    final labels = List.generate(days, (i) {
      final d = today.subtract(Duration(days: days - 1 - i));
      const days2 = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      return days2[d.weekday - 1];
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyKcal.asMap().entries.map((e) {
                final pct = e.value / maxVal;
                final hasValue = e.value > 0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasValue)
                          Text(
                            '${e.value.round()}',
                            style: TextStyle(
                              fontSize: 9,
                              color: vc.textSub,
                            ),
                          ),
                        const SizedBox(height: 2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            height: math.max(4, 80 * pct),
                            color: hasValue
                                ? AppColors.calories
                                : vc.border,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: labels
                .map((l) => Expanded(
                      child: Text(l,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10, color: vc.textMuted)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Kalori Trend Grafiği (CustomPainter) ──────────────────────────────────────

class _CalorieTrendChart extends StatelessWidget {
  final Map<String, Map<String, dynamic>> data;
  final int goal;
  final int days;
  final bool isPremium;
  final VColors vc;

  const _CalorieTrendChart({
    required this.data,
    required this.goal,
    required this.days,
    required this.isPremium,
    required this.vc,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final points = List.generate(days, (i) {
      final d = today.subtract(Duration(days: days - 1 - i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final meals = (data[key]?['meals'] as List<dynamic>? ?? []);
      return meals.fold<int>(0, (s, m) => s + ((m['calories'] as int?) ?? 0));
    });

    final maxVal = math.max(
      goal.toDouble(),
      points.fold<int>(0, math.max).toDouble(),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: vc.primary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: vc.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 130,
            child: CustomPaint(
              size: const Size(double.infinity, 130),
              painter: _LinePainter(
                values:    points.map((v) => v.toDouble()).toList(),
                maxVal:    maxVal,
                goalVal:   goal.toDouble(),
                lineColor: vc.primary,
                goalColor: vc.primary.withValues(alpha: 0.25),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Tarih etiketleri — her 7 günde bir
          _DateLabels(days: days, today: today, vc: vc),
          const SizedBox(height: 8),
          Row(
            children: [
              _Legend(color: vc.primary, label: 'Günlük kalori'),
              const SizedBox(width: 14),
              if (goal > 0)
                _Legend(
                    color: vc.primary.withValues(alpha: 0.4),
                    label: 'Hedef $goal kcal',
                    dashed: true),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Su Trend Grafiği ──────────────────────────────────────────────────────────

class _WaterTrendChart extends StatelessWidget {
  final Map<String, Map<String, dynamic>> data;
  final int goal;
  final int days;
  final VColors vc;

  const _WaterTrendChart({
    required this.data,
    required this.goal,
    required this.days,
    required this.vc,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final points = List.generate(days, (i) {
      final d = today.subtract(Duration(days: days - 1 - i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return ((data[key]?['waterConsumedMl'] as num?)?.toInt() ?? 0).toDouble();
    });

    final maxVal = math.max(
      goal.toDouble(),
      points.fold<double>(0, math.max),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.water.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: AppColors.water.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 130,
            child: CustomPaint(
              size: const Size(double.infinity, 130),
              painter: _LinePainter(
                values:    points,
                maxVal:    maxVal,
                goalVal:   goal.toDouble(),
                lineColor: AppColors.water,
                goalColor: AppColors.water.withValues(alpha: 0.25),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _DateLabels(days: days, today: today, vc: vc),
          const SizedBox(height: 8),
          Row(
            children: [
              _Legend(color: AppColors.water, label: 'Su (ml)'),
              const SizedBox(width: 14),
              if (goal > 0)
                _Legend(
                    color: AppColors.water.withValues(alpha: 0.4),
                    label: 'Hedef ${(goal / 1000).toStringAsFixed(1)} L',
                    dashed: true),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Rutin Trend Grafiği ───────────────────────────────────────────────────────

class _RoutineTrendChart extends StatelessWidget {
  final Map<String, Map<String, dynamic>> data;
  final int days;
  final VColors vc;

  const _RoutineTrendChart({
    required this.data,
    required this.days,
    required this.vc,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final points = List.generate(days, (i) {
      final d = today.subtract(Duration(days: days - 1 - i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final routines = (data[key]?['routines'] as List<dynamic>? ?? []);
      if (routines.isEmpty) return 0.0;
      final done  = routines.where((r) => r['isDone'] == true).length;
      return (done / routines.length * 100).clamp(0, 100).toDouble();
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 130,
            child: CustomPaint(
              size: const Size(double.infinity, 130),
              painter: _LinePainter(
                values:    points,
                maxVal:    100,
                goalVal:   80,
                lineColor: const Color(0xFFF59E0B),
                goalColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _DateLabels(days: days, today: today, vc: vc),
          const SizedBox(height: 8),
          Row(
            children: [
              _Legend(color: const Color(0xFFF59E0B), label: 'Tamamlama oranı (%)'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Rutin Streak Grid (premium) ───────────────────────────────────────────────

class _RoutineStreakGrid extends StatelessWidget {
  final Map<String, Map<String, dynamic>> data;
  final int days;
  final VColors vc;

  const _RoutineStreakGrid({
    required this.data,
    required this.days,
    required this.vc,
  });

  @override
  Widget build(BuildContext context) {
    final today  = DateTime.now();
    final cells  = List.generate(days, (i) {
      final d = today.subtract(Duration(days: days - 1 - i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final routines = (data[key]?['routines'] as List<dynamic>? ?? []);
      if (routines.isEmpty) return -1.0;
      final done = routines.where((r) => r['isDone'] == true).length;
      return done / routines.length;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(days, (i) {
              final rate  = cells[i];
              final color = rate < 0
                  ? vc.border
                  : rate >= 0.8
                      ? const Color(0xFF10B981)
                      : rate >= 0.5
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444);
              final d = today.subtract(Duration(days: days - 1 - i));
              final isToday = i == days - 1;
              return Tooltip(
                message: rate < 0
                    ? 'Veri yok'
                    : '${d.day}/${d.month}: %${(rate * 100).round()} tamamlandı',
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isToday ? 1.0 : 0.6),
                    borderRadius: BorderRadius.circular(4),
                    border: isToday
                        ? Border.all(color: vc.primary, width: 1.5)
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _GridLegend(color: const Color(0xFF10B981), label: '≥80%'),
              const SizedBox(width: 10),
              _GridLegend(color: const Color(0xFFF59E0B), label: '50–80%'),
              const SizedBox(width: 10),
              _GridLegend(color: const Color(0xFFEF4444), label: '<50%'),
              const SizedBox(width: 10),
              _GridLegend(color: Colors.grey, label: 'Veri yok'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Makro Dağılımı (premium) ──────────────────────────────────────────────────

class _MacroCard extends StatelessWidget {
  final DailyLog log;
  final VColors vc;

  const _MacroCard({required this.log, required this.vc});

  @override
  Widget build(BuildContext context) {
    final protein = log.meals.fold(0, (s, m) => s + m.proteinG);
    final carbs   = log.meals.fold(0, (s, m) => s + m.carbsG);
    final fat     = log.meals.fold(0, (s, m) => s + m.fatG);
    final total   = protein + carbs + fat;

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: vc.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: vc.border),
        ),
        child: Center(
          child: Text('Henüz makro veri yok',
              style: TextStyle(fontSize: 13, color: vc.textMuted)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        children: [
          // Makro bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Flexible(
                    flex: protein,
                    child: Container(color: const Color(0xFF3B82F6)),
                  ),
                  Flexible(
                    flex: carbs,
                    child: Container(color: const Color(0xFFF59E0B)),
                  ),
                  Flexible(
                    flex: fat,
                    child: Container(color: const Color(0xFFEF4444)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MacroItem('Protein', protein, total, const Color(0xFF3B82F6)),
              _MacroItem('Karb', carbs, total, const Color(0xFFF59E0B)),
              _MacroItem('Yağ', fat, total, const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _MacroItem(this.label, this.value, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (value / total * 100).round() : 0;
    return Expanded(
      child: Column(
        children: [
          Text('${value}g',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              )),
          const SizedBox(height: 2),
          Text('$label ($pct%)',
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

// ── Line Painter ──────────────────────────────────────────────────────────────

class _LinePainter extends CustomPainter {
  final List<double> values;
  final double maxVal;
  final double goalVal;
  final Color lineColor;
  final Color goalColor;

  const _LinePainter({
    required this.values,
    required this.maxVal,
    required this.goalVal,
    required this.lineColor,
    required this.goalColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || maxVal <= 0) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final goalPaint = Paint()
      ..color = goalColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final n = values.length;
    final w = size.width;
    final h = size.height;

    // Hedef çizgisi (kesikli)
    if (goalVal > 0) {
      final gy = h - (goalVal / maxVal * h).clamp(0, h);
      final dash = 6.0;
      var x = 0.0;
      while (x < w) {
        canvas.drawLine(Offset(x, gy), Offset((x + dash).clamp(0, w), gy), goalPaint);
        x += dash * 2;
      }
    }

    // Veri noktaları
    Offset point(int i) {
      final x = n == 1 ? w / 2 : i / (n - 1) * w;
      final y = h - (values[i] / maxVal * h).clamp(0.0, h);
      return Offset(x, y);
    }

    // Dolgu alanı
    if (n > 1) {
      final path = Path();
      path.moveTo(point(0).dx, h);
      path.lineTo(point(0).dx, point(0).dy);
      for (var i = 1; i < n; i++) {
        final prev = point(i - 1);
        final curr = point(i);
        final cx = (prev.dx + curr.dx) / 2;
        path.cubicTo(cx, prev.dy, cx, curr.dy, curr.dx, curr.dy);
      }
      path.lineTo(point(n - 1).dx, h);
      path.close();
      canvas.drawPath(path, fillPaint);

      // Çizgi
      final line = Path();
      line.moveTo(point(0).dx, point(0).dy);
      for (var i = 1; i < n; i++) {
        final prev = point(i - 1);
        final curr = point(i);
        final cx = (prev.dx + curr.dx) / 2;
        line.cubicTo(cx, prev.dy, cx, curr.dy, curr.dx, curr.dy);
      }
      canvas.drawPath(line, paint);
    }

    // Son nokta (vurgulu)
    if (n > 0) {
      canvas.drawCircle(point(n - 1), 4, dotPaint);
      canvas.drawCircle(
          point(n - 1), 4,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values || old.maxVal != maxVal;
}

// ── Yardımcı widgetlar ────────────────────────────────────────────────────────

class _DateLabels extends StatelessWidget {
  final int days;
  final DateTime today;
  final VColors vc;

  const _DateLabels({
    required this.days,
    required this.today,
    required this.vc,
  });

  @override
  Widget build(BuildContext context) {
    final step = days <= 7 ? 1 : days <= 14 ? 2 : 7;
    return Row(
      children: List.generate(days, (i) {
        if (i % step != 0 && i != days - 1) return const Expanded(child: SizedBox());
        final d = today.subtract(Duration(days: days - 1 - i));
        return Expanded(
          child: Text(
            '${d.day}/${d.month}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: i == days - 1 ? vc.primary : vc.textMuted,
              fontWeight: i == days - 1 ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        );
      }),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final VColors vc;
  const _SectionLabel(this.text, this.vc);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: vc.text,
          letterSpacing: -0.2,
        ),
      );
}

class _StatRow3 extends StatelessWidget {
  final List<_StatItem> items;
  final VColors vc;
  const _StatRow3({required this.items, required this.vc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vc.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: Column(
              children: [
                Text(item.value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: item.color,
                    )),
                const SizedBox(height: 2),
                Text(item.label,
                    style: TextStyle(fontSize: 10, color: vc.textMuted)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final Color color;
  const _StatItem(this.label, this.value, this.color);
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _Legend({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            border: dashed ? Border(bottom: BorderSide(color: color, width: 1.5)) : null,
            borderRadius: dashed ? null : BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}

class _GridLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _GridLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 9, color: color)),
      ],
    );
  }
}

class _PremiumUpsell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VColors vc;

  const _PremiumUpsell({
    required this.icon,
    required this.title,
    required this.desc,
    required this.vc,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/premium'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: vc.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.gold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: vc.text,
                          )),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Premium',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gold,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: TextStyle(fontSize: 11, color: vc.textSub)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  final VColors vc;
  const _LoadingBox({required this.vc});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vc.border),
      ),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: vc.primary),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final VColors vc;
  const _ErrorBox({required this.vc});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
      ),
      child: Center(
        child: Text('Veri yüklenemedi',
            style: TextStyle(fontSize: 12, color: vc.textMuted)),
      ),
    );
  }
}

class _WeightRetryBox extends StatelessWidget {
  final VColors vc;
  final VoidCallback onRetry;
  const _WeightRetryBox({required this.vc, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 32, color: vc.textMuted),
          const SizedBox(height: 8),
          Text('Kilo verisi yüklenemedi',
              style: TextStyle(color: vc.textMuted, fontSize: 13)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: vc.primarySurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: vc.primary.withValues(alpha: 0.3)),
              ),
              child: Text('Tekrar Dene',
                  style: TextStyle(
                      color: vc.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
