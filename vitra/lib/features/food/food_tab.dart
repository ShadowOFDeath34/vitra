import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/v_theme.dart';
import '../../shared/widgets/aurora_bg.dart';
import '../../shared/widgets/neon_ring.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/daily_log_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/models/meal_entry.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/fatsecret_service.dart';
import '../../core/services/open_food_facts_service.dart';
import '../../core/services/unified_food_search_service.dart';
import '../../core/providers/premium_provider.dart';
import '../../core/data/turkish_foods_db.dart';
import 'recipe_builder.dart';

final _recentMealsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return FirestoreService.instance.fetchRecentMeals();
});

// Dünkü öğünleri tip bazlı çeker
final _yesterdayMealsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final key = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  final history = await FirestoreService.instance.fetchLastNDays(2);
  final dayData = history[key];
  if (dayData == null) return [];
  return (dayData['meals'] as List<dynamic>? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
});

class FoodTab extends ConsumerWidget {
  const FoodTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc     = context.vt;
    final log     = ref.watch(dailyLogProvider);
    final profile = ref.watch(userProfileProvider);

    final consumed  = log.caloriesConsumed;
    final goal      = profile.calorieGoal;
    final remaining = goal > 0 ? (goal - consumed).clamp(0, goal) as int : 0;
    final progress  = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;

    final totalProtein = log.meals.fold(0, (s, m) => s + m.proteinG);
    final totalCarbs   = log.meals.fold(0, (s, m) => s + m.carbsG);
    final totalFat     = log.meals.fold(0, (s, m) => s + m.fatG);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Aurora Hero ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _FoodHero(
              consumed:     consumed,
              goal:         goal,
              remaining:    remaining,
              progress:     progress,
              totalProtein: totalProtein,
              totalCarbs:   totalCarbs,
              totalFat:     totalFat,
            ),
          ),

          // ── AI Giriş ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _AiInputCard(
                onAdd:             (e) => ref.read(dailyLogProvider.notifier).addMeal(e),
                remainingCalories: remaining,
                consumedProtein:   totalProtein,
                calorieGoal:       goal,
              ),
            ),
          ),

          // ── Tariflerim ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _RecipesCard(
                onAdd: (entry) => ref.read(dailyLogProvider.notifier).addMeal(entry),
              ),
            ),
          ),

          // ── Son Yenenler ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: ref.watch(_recentMealsProvider).when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (recent) {
                  if (recent.isEmpty) return const SizedBox.shrink();
                  return _RecentMealsCard(
                    meals: recent,
                    onAdd: (data) {
                      final entry = MealEntry(
                        id: 'recent_${DateTime.now().millisecondsSinceEpoch}',
                        name: data['name'] as String,
                        type: MealType.values[(data['type'] as int?) ?? 0],
                        calories: data['calories'] as int,
                        proteinG: (data['proteinG'] as int?) ?? 0,
                        carbsG:   (data['carbsG']   as int?) ?? 0,
                        fatG:     (data['fatG']     as int?) ?? 0,
                        time: DateTime.now(),
                      );
                      ref.read(dailyLogProvider.notifier).addMeal(entry);
                    },
                  );
                },
              ),
            ),
          ),

          // ── Öğün Bölümleri ────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final mealType = MealType.values[i];
                  final yesterdayAsync = ref.watch(_yesterdayMealsProvider);
                  final yesterdayForType = yesterdayAsync.valueOrNull
                      ?.where((m) => (m['type'] as int?) == mealType.index)
                      .toList() ?? [];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MealSection(
                      type:  mealType,
                      meals: log.meals
                          .where((m) => m.type == mealType)
                          .toList(),
                      onAdd: () =>
                          _showAddSheet(context, ref, mealType),
                      onRemove: (id) =>
                          ref.read(dailyLogProvider.notifier).removeMeal(id),
                      onSuggest: () => _showSuggestionSheet(
                        context, ref, mealType,
                        remainingCalories: remaining,
                        consumedProtein:   totalProtein,
                        calorieGoal:       goal,
                      ),
                      onCopyYesterday: yesterdayForType.isEmpty ? null : () {
                        for (final m in yesterdayForType) {
                          ref.read(dailyLogProvider.notifier).addMeal(
                            MealEntry(
                              id:       DateTime.now().millisecondsSinceEpoch.toString() +
                                        m['name'].toString(),
                              name:     m['name'] as String? ?? '',
                              calories: m['calories'] as int? ?? 0,
                              proteinG: m['proteinG'] as int? ?? 0,
                              carbsG:   m['carbsG']   as int? ?? 0,
                              fatG:     m['fatG']     as int? ?? 0,
                              type:     mealType,
                              time:     DateTime.now(),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
                childCount: MealType.values.length,
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  Future<void> _showSuggestionSheet(
    BuildContext context,
    WidgetRef ref,
    MealType type, {
    required int remainingCalories,
    required int consumedProtein,
    required int calorieGoal,
  }) async {
    // Premium kontrolü
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      await Navigator.of(context).pushNamed('/premium');
      return;
    }
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SuggestionSheet(
        mealType:          type,
        remainingCalories: remainingCalories,
        consumedProtein:   consumedProtein,
        calorieGoal:       calorieGoal,
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, MealType initialType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMealSheet(
        initialType: initialType,
        onAdd: (entry) => ref.read(dailyLogProvider.notifier).addMeal(entry),
      ),
    );
  }
}

// ── Food Hero ─────────────────────────────────────────────────────────────────

class _FoodHero extends StatelessWidget {
  final int consumed;
  final int goal;
  final int remaining;
  final double progress;
  final int totalProtein;
  final int totalCarbs;
  final int totalFat;

  const _FoodHero({
    required this.consumed,
    required this.goal,
    required this.remaining,
    required this.progress,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final overGoal = goal > 0 && consumed > goal;

    return AuroraBg(
      primaryColor: AppColors.calories,
      secondaryColor: const Color(0xFFFF5722),
      accentColor: AppColors.gold,
      primaryOpacity: 0.17,
      duration: const Duration(seconds: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              vc.surfaceHigh.withValues(alpha: 0.55),
              vc.bg.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: Column(
          children: [
            // Başlık
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yemek Günlüğü',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: vc.text,
                          letterSpacing: -0.8,
                        ),
                      ),
                      Text(
                        goal > 0
                            ? 'Günlük hedef: $goal kcal'
                            : 'Ne yedin, kaydet',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.calories,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Durum badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: overGoal
                          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                          : remaining == 0
                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                              : [AppColors.calories, AppColors.caloriesDeep],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.calories.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    overGoal
                        ? '+${consumed - goal} kcal'
                        : remaining == 0
                            ? 'Hedef!'
                            : '$remaining kaldı',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Neon Ring + makrolar
            Row(
              children: [
                // Ring
                NeonRing(
                  progress: overGoal ? 1.0 : progress,
                  color: overGoal
                      ? const Color(0xFFEF4444)
                      : AppColors.calories,
                  trackColor: AppColors.calories.withValues(alpha: 0.10),
                  size: 160,
                  strokeWidth: 13,
                  glowRadius: 14,
                  animationDuration: const Duration(milliseconds: 1200),
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                            begin: 0, end: consumed.toDouble()),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => Text(
                          v.round().toString(),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: vc.text,
                            height: 1,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                      Text(
                        'kcal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: vc.textSub,
                        ),
                      ),
                      if (goal > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '/ $goal',
                          style: TextStyle(
                            fontSize: 10,
                            color: vc.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Makro dikey liste
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MacroBar(
                        label: 'Protein',
                        value: totalProtein,
                        color: const Color(0xFF3B82F6),
                        unit: 'g',
                      ),
                      const SizedBox(height: 10),
                      _MacroBar(
                        label: 'Karb',
                        value: totalCarbs,
                        color: const Color(0xFFF59E0B),
                        unit: 'g',
                      ),
                      const SizedBox(height: 10),
                      _MacroBar(
                        label: 'Yağ',
                        value: totalFat,
                        color: const Color(0xFFEF4444),
                        unit: 'g',
                      ),
                      if (totalProtein == 0 &&
                          totalCarbs == 0 &&
                          totalFat == 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Öğün eklenince\nmakrolar görünür',
                            style: TextStyle(
                              fontSize: 12,
                              color: vc.textMuted,
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
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

class _MacroBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final String unit;

  const _MacroBar({
    required this.label,
    required this.value,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: vc.textSub,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$value $unit',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Son Yenenler Kartı ────────────────────────────────────────────────────────

class _RecentMealsCard extends StatelessWidget {
  final List<Map<String, dynamic>> meals;
  final void Function(Map<String, dynamic> data) onAdd;

  const _RecentMealsCard({required this.meals, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: vc.border.withValues(alpha: 0.7), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 16, color: vc.textSub),
              const SizedBox(width: 8),
              Text(
                'Son yenenler',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: vc.textSub,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: meals.map((m) {
              final name = m['name'] as String;
              final kcal = m['calories'] as int;
              return GestureDetector(
                onTap: () => onAdd(m),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: vc.surfaceHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: vc.primary.withValues(alpha: 0.15),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: vc.text,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$kcal',
                        style: TextStyle(fontSize: 11, color: vc.textSub),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.add_rounded, size: 12, color: vc.primary),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Kalori Özet Kartı ─────────────────────────────────────────────────────────

class _CalorieSummaryCard extends StatelessWidget {
  final int consumed;
  final int goal;
  final int remaining;
  final double progress;
  final int totalProtein;
  final int totalCarbs;
  final int totalFat;

  const _CalorieSummaryCard({
    required this.consumed,
    required this.goal,
    required this.remaining,
    required this.progress,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final overGoal = goal > 0 && consumed > goal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vc.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$consumed',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: overGoal ? AppColors.calories : vc.text,
                  letterSpacing: -1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5, left: 4),
                child: Text('kcal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: vc.textSub,
                    )),
              ),
              const Spacer(),
              if (goal > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: overGoal
                        ? vc.calorieSurface
                        : remaining == 0
                            ? vc.calorieSurface
                            : vc.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    overGoal
                        ? '${consumed - goal} kcal FAZLA'
                        : remaining > 0
                            ? '$remaining KCAL KALDI'
                            : 'HEDEF DOLDU',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: overGoal || remaining == 0
                          ? AppColors.calories
                          : vc.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            goal > 0 ? 'Hedef: $goal kcal' : 'Hedef henüz belirlenmedi',
            style: TextStyle(fontSize: 13, color: vc.textSub),
          ),
          if (goal > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: vc.primarySurface,
                valueColor: AlwaysStoppedAnimation<Color>(
                  overGoal ? AppColors.calories : vc.primary,
                ),
              ),
            ),
          ],
          if (totalProtein > 0 || totalCarbs > 0 || totalFat > 0) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: vc.border),
            const SizedBox(height: 12),
            Row(
              children: [
                _MacroStat(label: 'Protein', value: totalProtein, unit: 'g',
                    color: const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _MacroStat(label: 'Karb', value: totalCarbs, unit: 'g',
                    color: const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _MacroStat(label: 'Yağ', value: totalFat, unit: 'g',
                    color: const Color(0xFFEF4444)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final Color color;
  const _MacroStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$value$unit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI Hızlı Giriş Kartı ─────────────────────────────────────────────────────

class _AiInputCard extends ConsumerStatefulWidget {
  final void Function(MealEntry) onAdd;
  final int remainingCalories;
  final int consumedProtein;
  final int calorieGoal;

  const _AiInputCard({
    required this.onAdd,
    required this.remainingCalories,
    required this.consumedProtein,
    required this.calorieGoal,
  });

  @override
  ConsumerState<_AiInputCard> createState() => _AiInputCardState();
}

class _AiInputCardState extends ConsumerState<_AiInputCard> {
  final _textCtrl = TextEditingController();
  bool _loading   = false;
  FoodAnalysisResult? _result;
  Uint8List? _lastPhotoBytes; // retry için saklanır

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<bool> _checkAndGate() async {
    final isPremium = ref.read(isPremiumProvider);
    final canUse    = await ref.read(aiUsageProvider.notifier).canUse(isPremium);
    if (canUse) return true;
    if (!mounted) return false;
    await Navigator.of(context).pushNamed('/premium');
    return false;
  }

  Future<void> _getSuggestion() async {
    // Sadece premium kullanıcılar
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      await Navigator.of(context).pushNamed('/premium');
      return;
    }
    if (!mounted) return;

    // Önce öğün seçtir, sonra _SuggestionSheet aç
    final MealType? picked = await showModalBottomSheet<MealType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MealTypePickerSheet(remaining: widget.remainingCalories),
    );
    if (picked == null || !mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SuggestionSheet(
        mealType:          picked,
        remainingCalories: widget.remainingCalories,
        consumedProtein:   widget.consumedProtein,
        calorieGoal:       widget.calorieGoal,
      ),
    );
  }

  Future<void> _analyzeText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    // 1. Yerel DB — anlık, loading gösterme
    final localHits = TurkishFoodsDB.search(text);
    if (localHits.isNotEmpty) {
      final item = localHits.first;
      setState(() {
        _lastPhotoBytes = null;
        _result = FoodAnalysisResult(
          foodName:   item.name,
          calories:   item.calories,
          proteinG:   item.proteinG,
          carbsG:     item.carbsG,
          fatG:       item.fatG,
          fiberG:     item.fiberG,
          sodiumMg:   item.sodiumMg,
          sugarG:     item.sugarG,
          confidence: 'high',
          note:       item.serving,
        );
      });
      return;
    }

    // 2. Yerel DB boşsa AI — önce gate kontrol, sonra loading
    if (!await _checkAndGate()) return;
    setState(() { _loading = true; _result = null; _lastPhotoBytes = null; });
    final r = await AIService.instance.analyzeFoodText(text);
    if (!mounted) return;
    if (!r.hasError && r.calories == 0) {
      setState(() {
        _loading = false;
        _result = FoodAnalysisResult.error('Besin değerleri bulunamadı. Manuel olarak girin.');
      });
      return;
    }
    setState(() { _loading = false; _result = r; });
    if (!r.hasError) ref.read(aiUsageProvider.notifier).increment();
  }

  Future<void> _scanBarcode() async {
    // Kamerayı aç, barkod oku
    final String? barcode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _BarcodeScannerSheet(),
    );
    if (barcode == null || !mounted) return;

    setState(() { _loading = true; _result = null; });

    // 1. FatSecret — küresel markalar (Coca-Cola, Lay's, Nutella vb.)
    FoodAnalysisResult? r = await FatSecretService.instance.lookupBarcode(barcode);

    // 2. Open Food Facts — Türk markaları + ek global kapsam
    r ??= await OpenFoodFactsService.instance.lookup(barcode);

    if (!mounted) return;

    if (r != null) {
      // Türkçe karakter içermiyorsa ismi Türkçeye çevir (branded isimler genelde korunur)
      final translatedName = await AIService.instance.translateFoodName(r.foodName);
      if (!mounted) return;
      if (translatedName != r.foodName) {
        // Orijinal isim note'a eklenir — kullanıcı ambalajdaki isimle karşılaştırabilsin
        final originalNote = r.note.isNotEmpty ? '${r.foodName} · ${r.note}' : r.foodName;
        r = FoodAnalysisResult(
          foodName:   translatedName,
          calories:   r.calories,
          proteinG:   r.proteinG,
          carbsG:     r.carbsG,
          fatG:       r.fatG,
          fiberG:     r.fiberG,
          sodiumMg:   r.sodiumMg,
          sugarG:     r.sugarG,
          confidence: r.confidence,
          note:       originalNote,
        );
      }
      _textCtrl.text = r.foodName;
      setState(() { _loading = false; _result = r; });
    } else {
      setState(() {
        _loading = false;
        _result = FoodAnalysisResult.error(
          'Ürün bulunamadı (barkod: $barcode).\nManuel olarak girebilirsiniz.',
        );
      });
    }
  }

  Future<void> _analyzePhoto(ImageSource source) async {
    final picker = ImagePicker();
    final xfile  = await picker.pickImage(
      source: source, imageQuality: 85, maxWidth: 1280,
    );
    if (xfile == null) return;
    if (!await _checkAndGate()) return;
    setState(() { _loading = true; _result = null; _lastPhotoBytes = null; });
    final bytes = await xfile.readAsBytes();
    final r = await AIService.instance.analyzeFoodPhoto(bytes);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result  = r;
      if (!r.hasError) _lastPhotoBytes = bytes;
    });
    if (!r.hasError) {
      _textCtrl.text = r.foodName;
      ref.read(aiUsageProvider.notifier).increment();
    }
  }

  void _addResult(MealType type, FoodAnalysisResult r) {
    if (r.hasError) return;
    widget.onAdd(MealEntry(
      id:       DateTime.now().millisecondsSinceEpoch.toString(),
      name:     r.foodName,
      type:     type,
      calories: r.calories,
      proteinG: r.proteinG,
      carbsG:   r.carbsG,
      fatG:     r.fatG,
      fiberG:   r.fiberG,
      sodiumMg: r.sodiumMg,
      sugarG:   r.sugarG,
      time:     DateTime.now(),
    ));
    setState(() { _result = null; _textCtrl.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    final vc        = context.vt;
    final isPremium = ref.watch(isPremiumProvider);
    final remaining = ref.watch(aiUsageProvider.notifier).remaining;
    final isLocked  = !isPremium && remaining == 0;

    // Limit doldu — lock kartı göster
    if (isLocked) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: vc.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded,
                  color: Colors.red, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              'Günlük AI limiti doldu',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: vc.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Günde 3 ücretsiz AI analiz hakkın var.\nYarın sıfırlanır veya Premium\'a geçerek sınırsız kullan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: vc.textSub,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/premium'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [vc.primary, vc.primaryGlow],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: vc.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.gold, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'Premium\'a Geç',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            vc.primary.withValues(alpha: 0.08),
            vc.primary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vc.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: vc.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    color: vc.primary, size: 15),
              ),
              const SizedBox(width: 8),
              Text('AI ile Analiz Et',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: vc.primary,
                  )),
              const Spacer(),
              if (!isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: remaining > 1
                        ? vc.primary.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    remaining == 1 ? '1 hak kaldı' : '$remaining analiz hakkı',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: remaining > 1 ? vc.primary : Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Metin girişi
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  onSubmitted: (_) => _analyzeText(),
                  style: TextStyle(fontSize: 14, color: vc.text),
                  decoration: InputDecoration(
                    hintText: 'Ne yediniz? (ör: 2 yumurtalı omlet, büyük ayran...)',
                    hintStyle: TextStyle(color: vc.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: vc.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    suffixIcon: _loading
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: vc.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _IconBtn(
                icon: Icons.send_rounded,
                onTap: _loading ? null : _analyzeText,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fotoğraf butonları + Barkod + Ne yesem?
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PillBtn(
                icon: Icons.camera_alt_rounded,
                label: 'Fotoğraf çek',
                onTap: _loading ? null : () => _analyzePhoto(ImageSource.camera),
              ),
              _PillBtn(
                icon: Icons.photo_library_rounded,
                label: 'Galeriden seç',
                onTap: _loading ? null : () => _analyzePhoto(ImageSource.gallery),
              ),
              _PillBtn(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Barkod tara',
                onTap: _loading ? null : _scanBarcode,
              ),
              _PillBtn(
                icon: Icons.lightbulb_outline_rounded,
                label: 'Ne yesem?',
                onTap: _loading ? null : _getSuggestion,
              ),
            ],
          ),

          // Analiz yükleniyor
          if (_loading) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: vc.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'Analiz ediliyor...',
                  style: TextStyle(
                    fontSize: 13,
                    color: vc.primary.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],

          // Analiz sonucu
          if (_result != null) ...[
            const SizedBox(height: 12),
            _result!.hasError
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_result!.errorMessage,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13)),
                        ),
                      ],
                    ),
                  )
                : _EditableResultCard(
                    initial: _result!,
                    onAdd: _addResult,
                    onRetry: (_lastPhotoBytes != null && ref.read(isPremiumProvider))
                        ? () => AIService.instance.retryFoodPhoto(_lastPhotoBytes!)
                        : null,
                  ),
          ],
        ],
      ),
    );
  }
}

// ── Düzenlenebilir Sonuç Kartı ────────────────────────────────────────────────

class _EditableResultCard extends StatefulWidget {
  final FoodAnalysisResult initial;
  final void Function(MealType type, FoodAnalysisResult r) onAdd;
  /// Fotoğraf analizi sonuçları için retry callback — null ise buton gösterilmez
  final Future<FoodAnalysisResult?> Function()? onRetry;

  const _EditableResultCard({
    required this.initial,
    required this.onAdd,
    this.onRetry,
  });

  @override
  State<_EditableResultCard> createState() => _EditableResultCardState();
}

class _EditableResultCardState extends State<_EditableResultCard> {
  late TextEditingController _nameCtrl;
  late TextEditingController _calCtrl;
  late TextEditingController _proCtrl;
  late TextEditingController _carbCtrl;
  late TextEditingController _fatCtrl;
  late TextEditingController _portionCtrl;
  bool _editing      = false;
  bool _retryLoading = false;
  bool _retryDone    = false;
  bool _showingRetry = false; // toggle: false=ilk, true=retry
  FoodAnalysisResult? _retryResult;

  late int _baseCal;
  late int _basePro;
  late int _baseCarb;
  late int _baseFat;
  late int _baseFiber;
  late int _baseSodium;
  late int _baseSugar;

  // Barkod kaynakları 100g bazlı değer döndürür — gram girişi kullan
  late bool _isBarcode;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _isBarcode  = r.note.contains('Open Food Facts') || r.note.contains('FatSecret');
    _baseCal    = r.calories;
    _basePro    = r.proteinG;
    _baseCarb   = r.carbsG;
    _baseFat    = r.fatG;
    _baseFiber  = r.fiberG;
    _baseSodium = r.sodiumMg;
    _baseSugar  = r.sugarG;
    _nameCtrl    = TextEditingController(text: r.foodName);
    _calCtrl     = TextEditingController(text: '${r.calories}');
    _proCtrl     = TextEditingController(text: '${r.proteinG}');
    _carbCtrl    = TextEditingController(text: '${r.carbsG}');
    _fatCtrl     = TextEditingController(text: '${r.fatG}');
    // Barkod → default 100g göster; AI → 1 porsiyon
    _portionCtrl = TextEditingController(text: _isBarcode ? '100' : '1');
    _portionCtrl.addListener(_onPortionChanged);
  }

  // Verilen sonucu kart kontrolörlerine yükler
  void _loadResult(FoodAnalysisResult r) {
    final isBarcode = r.note.contains('Open Food Facts') || r.note.contains('FatSecret');
    _isBarcode  = isBarcode;
    _baseCal    = r.calories;
    _basePro    = r.proteinG;
    _baseCarb   = r.carbsG;
    _baseFat    = r.fatG;
    _baseFiber  = r.fiberG;
    _baseSodium = r.sodiumMg;
    _baseSugar  = r.sugarG;
    _nameCtrl.text    = r.foodName;
    _calCtrl.text     = '${r.calories}';
    _proCtrl.text     = '${r.proteinG}';
    _carbCtrl.text    = '${r.carbsG}';
    _fatCtrl.text     = '${r.fatG}';
    _portionCtrl.text = isBarcode ? '100' : '1';
  }

  // Barkod için: factor = gram / 100  |  AI için: factor = x (çarpan)
  void _onPortionChanged() {
    final val = double.tryParse(_portionCtrl.text);
    if (val == null || val <= 0) return;
    final factor = _isBarcode ? val / 100.0 : val;
    setState(() {
      _calCtrl.text  = (_baseCal    * factor).round().toString();
      _proCtrl.text  = (_basePro    * factor).round().toString();
      _carbCtrl.text = (_baseCarb   * factor).round().toString();
      _fatCtrl.text  = (_baseFat    * factor).round().toString();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _proCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    _portionCtrl.dispose();
    super.dispose();
  }

  FoodAnalysisResult _current() {
    final val = double.tryParse(_portionCtrl.text) ?? 1.0;
    final factor = _isBarcode ? val / 100.0 : val;
    return FoodAnalysisResult(
      foodName:   _nameCtrl.text.trim(),
      calories:   int.tryParse(_calCtrl.text) ?? 0,
      proteinG:   int.tryParse(_proCtrl.text) ?? 0,
      carbsG:     int.tryParse(_carbCtrl.text) ?? 0,
      fatG:       int.tryParse(_fatCtrl.text) ?? 0,
      fiberG:     (_baseFiber  * factor).round(),
      sodiumMg:   (_baseSodium * factor).round(),
      sugarG:     (_baseSugar  * factor).round(),
      confidence: widget.initial.confidence,
      note:       widget.initial.note,
    );
  }

  Color get _confidenceColor {
    switch (widget.initial.confidence) {
      case 'high':   return const Color(0xFF10B981);
      case 'medium': return const Color(0xFFF59E0B);
      default:       return const Color(0xFFEF4444);
    }
  }

  String get _confidenceLabel {
    switch (widget.initial.confidence) {
      case 'high':   return 'Değerler güvenilir';
      case 'medium': return 'Yaklaşık değerler';
      default:       return 'Tahmini — düzenleyin';
    }
  }

  InputDecoration _editDeco(String hint, VColors vc) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: vc.textMuted),
        filled: true,
        fillColor: vc.bg,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      );

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık + güven + düzenle
          Row(
            children: [
              Expanded(
                child: _editing
                    ? TextField(
                        controller: _nameCtrl,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: vc.text,
                        ),
                        decoration: _editDeco('Yiyecek adı', vc),
                      )
                    : Text(
                        _nameCtrl.text,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: vc.text,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _editing = !_editing),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _editing
                        ? vc.primary.withValues(alpha: 0.1)
                        : vc.textMuted.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _editing ? 'Tamam' : 'Düzenle',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _editing ? vc.primary : vc.textSub,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Kalori + güven rozeti
          Row(
            children: [
              _editing
                  ? SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _calCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: vc.primary,
                        ),
                        decoration: _editDeco('kcal', vc),
                      ),
                    )
                  : RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _calCtrl.text,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: vc.primary,
                            ),
                          ),
                          TextSpan(
                            text: ' kcal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: vc.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
              const Spacer(),
              // Retry / toggle butonu — fotoğraf sonucu + premium
              if (widget.onRetry != null) ...[
                if (!_retryDone && !_retryLoading)
                  GestureDetector(
                    onTap: () async {
                      setState(() => _retryLoading = true);
                      final r = await widget.onRetry!();
                      if (!mounted) return;
                      if (r != null && !r.hasError) {
                        setState(() {
                          _retryResult   = r;
                          _retryDone     = true;
                          _showingRetry  = true;
                          _retryLoading  = false;
                        });
                        _loadResult(r);
                      } else {
                        setState(() => _retryLoading = false);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: vc.textMuted.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 11, color: vc.textSub),
                          const SizedBox(width: 3),
                          Text('Tekrar analiz et',
                              style: TextStyle(fontSize: 10, color: vc.textSub, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  )
                else if (_retryLoading)
                  SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: vc.textSub),
                  )
                else if (_retryDone && _retryResult != null) ...[
                  // Toggle: ilk ↔ tekrar
                  _ToggleChip(
                    label: '${widget.initial.calories} kcal',
                    active: !_showingRetry,
                    onTap: () {
                      if (_showingRetry) setState(() { _showingRetry = false; _loadResult(widget.initial); });
                    },
                  ),
                  const SizedBox(width: 4),
                  _ToggleChip(
                    label: '${_retryResult!.calories} kcal',
                    active: _showingRetry,
                    onTap: () {
                      if (!_showingRetry) setState(() { _showingRetry = true; _loadResult(_retryResult!); });
                    },
                  ),
                ],
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _confidenceColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _confidenceColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _confidenceLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _confidenceColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Makro satırı
          const SizedBox(height: 10),
          if (_editing)
            Row(
              children: [
                _MacroEditField('Protein', _proCtrl, const Color(0xFF3B82F6)),
                const SizedBox(width: 6),
                _MacroEditField('Karb', _carbCtrl, const Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                _MacroEditField('Yağ', _fatCtrl, const Color(0xFFEF4444)),
              ],
            )
          else
            Row(
              children: [
                _MacroBadge('P ${_proCtrl.text}g', const Color(0xFF3B82F6)),
                const SizedBox(width: 6),
                _MacroBadge('K ${_carbCtrl.text}g', const Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                _MacroBadge('Y ${_fatCtrl.text}g', const Color(0xFFEF4444)),
              ],
            ),

          // Not
          if (widget.initial.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 12,
                    color: vc.textSub.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.initial.note,
                    style: TextStyle(fontSize: 12, color: vc.textSub),
                  ),
                ),
              ],
            ),
          ],

          // Miktar — barkod için gram, AI için porsiyon çarpanı
          const SizedBox(height: 14),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isBarcode ? 'Miktar (g)' : 'Porsiyon',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: vc.textSub),
                  ),
                  if (!_isBarcode) ...[
                    const SizedBox(height: 2),
                    Builder(builder: (_) {
                      final raw = widget.initial.note.split('—').first.trim();
                      final hint = (raw.isNotEmpty && raw.length <= 25) ? raw : '1 servis';
                      return Text('1 = $hint',
                          style: TextStyle(fontSize: 10, color: vc.textMuted));
                    }),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text('100g = etiket değerleri',
                        style: TextStyle(fontSize: 10, color: vc.textMuted)),
                  ],
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _portionCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: vc.text),
                  decoration: _editDeco(_isBarcode ? '100' : '1', vc),
                ),
              ),
            ],
          ),

          // Sağlık değerlendirmesi (Premium)
          const SizedBox(height: 12),
          _HealthRatingSection(food: widget.initial),

          // Öğün seçimi
          const SizedBox(height: 14),
          Text('Hangi öğüne ekleyelim?',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: vc.textSub)),
          const SizedBox(height: 8),
          Row(
            children: MealType.values.map((type) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onAdd(type, _current()),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          vc.primary.withValues(alpha: 0.12),
                          vc.primary.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: vc.primary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Text(type.emoji,
                            style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(type.label,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: vc.primary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MacroEditField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final Color color;
  const _MacroEditField(this.label, this.ctrl, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: color),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.5)),
          filled: true,
          fillColor: color.withValues(alpha: 0.08),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 6, vertical: 8),
          suffix: Text('g',
              style: TextStyle(
                  fontSize: 11, color: color.withValues(alpha: 0.7))),
        ),
      ),
    );
  }
}

class _MacroBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MacroBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}

// ── Toggle chip: ilk / retry sonuç seçimi ────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? vc.primary.withValues(alpha: 0.15)
              : vc.textMuted.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? vc.primary.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: active ? vc.primary : vc.textMuted,
          ),
        ),
      ),
    );
  }
}

// ── Sağlık Değerlendirmesi (Premium) ─────────────────────────────────────────

class _HealthRatingSection extends ConsumerStatefulWidget {
  final FoodAnalysisResult food;
  const _HealthRatingSection({required this.food});

  @override
  ConsumerState<_HealthRatingSection> createState() => _HealthRatingSectionState();
}

class _HealthRatingSectionState extends ConsumerState<_HealthRatingSection> {
  FoodHealthRating? _rating;
  bool _loading = false;
  bool _fetched = false;

  Future<void> _fetch() async {
    if (_fetched || _loading) return;
    setState(() { _loading = true; _fetched = true; });
    final r = await AIService.instance.analyzeHealth(
      foodName: widget.food.foodName,
      calories: widget.food.calories,
      proteinG: widget.food.proteinG,
      carbsG:   widget.food.carbsG,
      fatG:     widget.food.fatG,
      fiberG:   widget.food.fiberG,
      sodiumMg: widget.food.sodiumMg,
      sugarG:   widget.food.sugarG,
    );
    if (mounted) setState(() { _rating = r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final vc = context.vt;

    if (!isPremium) {
      return GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/premium'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: vc.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: vc.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 13, color: vc.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sağlık değerlendirmesi — Premium',
                  style: TextStyle(
                    fontSize: 12,
                    color: vc.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: vc.primary),
            ],
          ),
        ),
      );
    }

    // Premium — ilk renderda getir
    if (!_fetched) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
    }

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 12, height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: vc.primary),
            ),
            const SizedBox(width: 8),
            Text('Sağlık değerlendiriliyor...',
                style: TextStyle(fontSize: 12, color: vc.textSub)),
          ],
        ),
      );
    }

    final r = _rating;
    if (r == null) return const SizedBox.shrink();

    final (color, icon) = switch (r.level) {
      'healthy'  => (const Color(0xFF10B981), Icons.favorite_rounded),
      'moderate' => (const Color(0xFFF59E0B), Icons.balance_rounded),
      _          => (const Color(0xFFEF4444), Icons.warning_amber_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                if (r.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(r.note,
                      style: TextStyle(fontSize: 11, color: vc.textSub)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _IconBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap == null
              ? vc.textMuted.withValues(alpha: 0.3)
              : vc.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _PillBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _PillBtn({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: vc.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: vc.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: vc.primary),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: vc.primary,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Öğün Bölümü ───────────────────────────────────────────────────────────────

class _MealSection extends StatelessWidget {
  final MealType type;
  final List<MealEntry> meals;
  final VoidCallback onAdd;
  final void Function(String id) onRemove;
  final VoidCallback? onSuggest;
  final VoidCallback? onCopyYesterday;

  const _MealSection({
    required this.type,
    required this.meals,
    required this.onAdd,
    required this.onRemove,
    this.onSuggest,
    this.onCopyYesterday,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final total         = meals.fold(0, (s, m) => s + m.calories);
    final totalProtein  = meals.fold(0, (s, m) => s + m.proteinG);
    final totalCarbs    = meals.fold(0, (s, m) => s + m.carbsG);
    final totalFat      = meals.fold(0, (s, m) => s + m.fatG);
    final hasMacros     = totalProtein > 0 || totalCarbs > 0 || totalFat > 0;

    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vc.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Text(type.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(type.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: vc.text,
                    )),
                const Spacer(),
                if (total > 0) ...[
                  if (hasMacros)
                    Text(
                      'P${totalProtein} K${totalCarbs} Y${totalFat}  ',
                      style: TextStyle(fontSize: 11, color: vc.textMuted),
                    ),
                  Text('$total kcal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: vc.primary,
                      )),
                ],
              ],
            ),
          ),
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 32,
                    decoration: BoxDecoration(
                      color: vc.textMuted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Henüz eklenmedi',
                      style: TextStyle(
                        fontSize: 13,
                        color: vc.textMuted,
                        fontStyle: FontStyle.italic,
                      )),
                ],
              ),
            )
          else
            ...meals.map(
              (meal) => _MealRow(meal: meal, onRemove: () => onRemove(meal.id)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onAdd,
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: vc.primarySurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add_rounded, size: 18, color: vc.primary),
                      ),
                      const SizedBox(width: 10),
                      Text('Manuel ekle',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: vc.primary,
                          )),
                    ],
                  ),
                ),
                if (onCopyYesterday != null || onSuggest != null) ...[
                  const Spacer(),
                  if (onCopyYesterday != null)
                    GestureDetector(
                      onTap: onCopyYesterday,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: vc.primarySurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: vc.primary.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy_rounded, size: 12, color: vc.primary),
                            const SizedBox(width: 4),
                            Text('Dünkü kopyala',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: vc.primary,
                                )),
                          ],
                        ),
                      ),
                    ),
                  if (onSuggest != null && onCopyYesterday == null)
                    GestureDetector(
                      onTap: onSuggest,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.habits.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.habits.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, size: 13, color: AppColors.habits),
                            const SizedBox(width: 4),
                            Text('Ne yesem?',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.habits,
                                )),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback onRemove;

  const _MealRow({required this.meal, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final timeStr = '${meal.time.hour.toString().padLeft(2, '0')}:'
        '${meal.time.minute.toString().padLeft(2, '0')}';

    final hasDetail = meal.fiberG > 0 || meal.sodiumMg > 0 || meal.sugarG > 0;

    return GestureDetector(
      onTap: hasDetail
          ? () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => _MealDetailSheet(meal: meal, vc: vc),
              )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: vc.primary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.name,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: vc.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(timeStr,
                      style: TextStyle(fontSize: 11, color: vc.textMuted)),
                  if (meal.proteinG > 0 || meal.carbsG > 0 || meal.fatG > 0)
                    Text(
                      'P: ${meal.proteinG}g · K: ${meal.carbsG}g · Y: ${meal.fatG}g',
                      style: TextStyle(fontSize: 11, color: vc.textMuted),
                    ),
                ],
              ),
            ),
            Text('${meal.calories} kcal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: vc.textSub,
                )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close_rounded,
                  size: 18, color: vc.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Öğün Detay Sheet ──────────────────────────────────────────────────────────

class _MealDetailSheet extends StatelessWidget {
  final MealEntry meal;
  final VColors vc;

  const _MealDetailSheet({required this.meal, required this.vc});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(meal.name,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: vc.text)),
              ),
              Text('${meal.calories} kcal',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: vc.primary)),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(label: 'Protein', value: '${meal.proteinG} g', vc: vc),
          _DetailRow(label: 'Karbonhidrat', value: '${meal.carbsG} g', vc: vc),
          _DetailRow(label: 'Yağ', value: '${meal.fatG} g', vc: vc),
          if (meal.fiberG > 0)
            _DetailRow(label: 'Lif', value: '${meal.fiberG} g', vc: vc),
          if (meal.sugarG > 0)
            _DetailRow(label: 'Şeker', value: '${meal.sugarG} g', vc: vc),
          if (meal.sodiumMg > 0)
            _DetailRow(label: 'Sodyum', value: '${meal.sodiumMg} mg', vc: vc),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final VColors vc;

  const _DetailRow({required this.label, required this.value, required this.vc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: vc.textMuted)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: vc.text)),
        ],
      ),
    );
  }
}

// ── Manuel Ekleme Sheet (AI destekli) ─────────────────────────────────────────

class _AddMealSheet extends ConsumerStatefulWidget {
  final MealType initialType;
  final void Function(MealEntry entry) onAdd;

  const _AddMealSheet({required this.initialType, required this.onAdd});

  @override
  ConsumerState<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends ConsumerState<_AddMealSheet> {
  late MealType _selectedType;
  final _nameFocus  = FocusNode();
  final _nameCtrl   = TextEditingController();
  final _calCtrl    = TextEditingController();
  final _proCtrl    = TextEditingController();
  final _carbCtrl   = TextEditingController();
  final _fatCtrl    = TextEditingController();
  final _fiberCtrl  = TextEditingController();
  final _sodiumCtrl = TextEditingController();
  final _sugarCtrl  = TextEditingController();
  final _portionCtrl = TextEditingController(text: '1');
  bool _aiLoading   = false;
  bool _showMacros  = false;
  bool _showDetails = false;
  PortionUnit _portionUnit = PortionUnit.none;
  List<SearchSuggestion> _suggestions = [];
  Timer? _suggestionDebounce;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _nameCtrl.addListener(_onNameChanged);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _nameFocus.requestFocus());
  }

  void _onNameChanged() {
    final q = _nameCtrl.text.trim();
    if (q.length < 2) {
      _suggestionDebounce?.cancel();
      setState(() { _suggestions = []; });
      return;
    }
    // Yerel DB anlık göster (max 5 — suggest() ile tutarlı)
    final local = TurkishFoodsDB.search(q)
        .take(5)
        .map((item) => SearchSuggestion(
              result: UnifiedFoodSearchService.instance.localResult(item),
              source: SuggestionSource.local,
            ))
        .toList();
    setState(() { _suggestions = local; });

    // Debounce ile UnifiedFoodSearchService.suggest() çağır — local dışı sonuç varsa güncelle
    _suggestionDebounce?.cancel();
    _suggestionDebounce = Timer(const Duration(milliseconds: 400), () {
      UnifiedFoodSearchService.instance.suggest(q).then((all) {
        if (!mounted || _nameCtrl.text.trim() != q) return;
        final hasExternal = all.any((s) => s.source != SuggestionSource.local);
        if (hasExternal) setState(() { _suggestions = all; });
      });
    });
  }

  void _fillFromSuggestion(SearchSuggestion s) {
    final r = s.result;
    _nameCtrl.text   = r.foodName;
    _calCtrl.text    = '${r.calories}';
    _proCtrl.text    = '${r.proteinG}';
    _carbCtrl.text   = '${r.carbsG}';
    _fatCtrl.text    = '${r.fatG}';
    if (r.fiberG > 0)   _fiberCtrl.text  = '${r.fiberG}';
    if (r.sodiumMg > 0) _sodiumCtrl.text = '${r.sodiumMg}';
    if (r.sugarG > 0)   _sugarCtrl.text  = '${r.sugarG}';
    setState(() { _showMacros = true; _suggestions = []; });
    _nameFocus.unfocus();
  }

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    _nameFocus.dispose();
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _proCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    _fiberCtrl.dispose();
    _sodiumCtrl.dispose();
    _sugarCtrl.dispose();
    _portionCtrl.dispose();
    super.dispose();
  }

  Future<void> _aiFill() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    // Gate kontrolü loading'den önce — premium ekranında spinner görünmesin
    final isPremium = ref.read(isPremiumProvider);
    final canUse    = await ref.read(aiUsageProvider.notifier).canUse(isPremium);
    if (!mounted) return;
    if (!canUse) {
      await Navigator.of(context).pushNamed('/premium');
      return;
    }

    setState(() { _aiLoading = true; _suggestions = []; });

    final r = await AIService.instance.analyzeFoodText(name);
    if (!mounted) return;

    if (!r.hasError) {
      _calCtrl.text  = '${r.calories}';
      _proCtrl.text  = '${r.proteinG}';
      _carbCtrl.text = '${r.carbsG}';
      _fatCtrl.text  = '${r.fatG}';
      if (r.fiberG > 0)   _fiberCtrl.text  = '${r.fiberG}';
      if (r.sodiumMg > 0) _sodiumCtrl.text = '${r.sodiumMg}';
      if (r.sugarG > 0)   _sugarCtrl.text  = '${r.sugarG}';
      setState(() { _aiLoading = false; _showMacros = true; });
      ref.read(aiUsageProvider.notifier).increment();
    } else {
      setState(() => _aiLoading = false);
    }
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final cal  = int.tryParse(_calCtrl.text.trim()) ?? 0;
    if (name.isEmpty || cal <= 0) return;

    widget.onAdd(MealEntry(
      id:          DateTime.now().millisecondsSinceEpoch.toString(),
      name:        name,
      type:        _selectedType,
      calories:    cal,
      proteinG:    int.tryParse(_proCtrl.text) ?? 0,
      carbsG:      int.tryParse(_carbCtrl.text) ?? 0,
      fatG:        int.tryParse(_fatCtrl.text) ?? 0,
      fiberG:      int.tryParse(_fiberCtrl.text) ?? 0,
      sodiumMg:    int.tryParse(_sodiumCtrl.text) ?? 0,
      sugarG:      int.tryParse(_sugarCtrl.text) ?? 0,
      portionUnit: _portionUnit,
      portionSize: double.tryParse(_portionCtrl.text) ?? 1.0,
      time:        DateTime.now(),
    ));
    Navigator.of(context).pop();
  }

  InputDecoration _fieldDeco(String hint, VColors vc) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: vc.textMuted, fontSize: 14),
        filled: true,
        fillColor: vc.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: vc.textMuted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Manuel Ekle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: vc.text,
              )),
          const SizedBox(height: 20),

          // Öğün tipi
          Row(
            children: MealType.values.map((type) {
              final sel = type == _selectedType;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? vc.primary : vc.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(type.emoji,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(type.label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : vc.primary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // İsim + AI butonu
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(fontSize: 15, color: vc.text),
                  decoration: _fieldDeco('Yiyecek adı (ör: mercimek çorbası)', vc),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _aiLoading ? null : _aiFill,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _aiLoading
                        ? vc.textMuted.withValues(alpha: 0.3)
                        : vc.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: vc.primary.withValues(alpha: 0.3)),
                  ),
                  child: _aiLoading
                      ? Padding(
                          padding: const EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: vc.primary),
                        )
                      : Icon(Icons.auto_awesome_rounded,
                          color: vc.primary, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'AI ikonuna bas → kalori ve makrolar otomatik dolsun',
            style: TextStyle(
              fontSize: 11,
              color: vc.textMuted.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
            ),
          ),

          // DB Önerileri
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: vc.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: vc.border),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: vc.border),
                itemBuilder: (_, i) {
                  final s = _suggestions[i];
                  final r = s.result;
                  return InkWell(
                    onTap: () => _fillFromSuggestion(s),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.foodName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: vc.text,
                                    )),
                                const SizedBox(height: 2),
                                Text(
                                  r.note.isNotEmpty ? r.note : '100g',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: vc.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (s.sourceLabel.isNotEmpty) ...[
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: vc.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(s.sourceLabel,
                                  style: TextStyle(fontSize: 9, color: vc.textMuted,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: vc.primarySurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${r.calories} kcal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: vc.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Kalori
          TextField(
            controller: _calCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(fontSize: 15, color: vc.text),
            decoration: _fieldDeco('Kalori (kcal) *', vc),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),

          // Porsiyon birimi seçici
          Row(
            children: [
              Text('Porsiyon:',
                  style: TextStyle(
                      fontSize: 12,
                      color: vc.textSub,
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: PortionUnit.values.map((u) {
                      final sel = u == _portionUnit;
                      final label = u == PortionUnit.none ? 'Yok' : u.label;
                      return GestureDetector(
                        onTap: () => setState(() => _portionUnit = u),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: sel
                                ? vc.primary
                                : vc.primarySurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? vc.primary
                                  : vc.border,
                            ),
                          ),
                          child: Text(label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : vc.primary,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          // Porsiyon miktarı — sadece birim seçiliyse göster
          if (_portionUnit != PortionUnit.none) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _portionCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 14, color: vc.text),
              decoration: _fieldDeco(
                  'Miktar (${_portionUnit.label})', vc),
            ),
          ],

          // Makro satırı
          if (_showMacros) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _proCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF3B82F6)),
                    decoration: _fieldDeco('Protein (g)', vc).copyWith(
                      fillColor: const Color(0xFF3B82F6).withValues(alpha: 0.06),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _carbCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFFF59E0B)),
                    decoration: _fieldDeco('Karb (g)', vc).copyWith(
                      fillColor: const Color(0xFFF59E0B).withValues(alpha: 0.06),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _fatCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFFEF4444)),
                    decoration: _fieldDeco('Yağ (g)', vc).copyWith(
                      fillColor: const Color(0xFFEF4444).withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _showMacros = true),
              child: Text(
                '+ Protein / Karb / Yağ ekle (isteğe bağlı)',
                style: TextStyle(
                  fontSize: 12,
                  color: vc.primary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],

          // Detaylı besin bilgisi (fiber, sodyum, şeker)
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showDetails = !_showDetails),
            child: Row(
              children: [
                Icon(
                  _showDetails
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: vc.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  _showDetails
                      ? 'Detaylı bilgiyi gizle'
                      : '+ Lif / Sodyum / Şeker (isteğe bağlı)',
                  style: TextStyle(
                    fontSize: 12,
                    color: vc.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_showDetails) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fiberCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF10B981)),
                    decoration: _fieldDeco('Lif (g)', vc).copyWith(
                      fillColor: const Color(0xFF10B981).withValues(alpha: 0.06),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _sodiumCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF8B5CF6)),
                    decoration: _fieldDeco('Sodyum (mg)', vc).copyWith(
                      fillColor: const Color(0xFF8B5CF6).withValues(alpha: 0.06),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _sugarCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFFEC4899)),
                    decoration: _fieldDeco('Şeker (g)', vc).copyWith(
                      fillColor: const Color(0xFFEC4899).withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: vc.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text('Ekle',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Yemek Öneri Sheet'i ───────────────────────────────────────────────────────

class _SuggestionSheet extends ConsumerStatefulWidget {
  final MealType mealType;
  final int remainingCalories;
  final int consumedProtein;
  final int calorieGoal;

  const _SuggestionSheet({
    required this.mealType,
    required this.remainingCalories,
    required this.consumedProtein,
    required this.calorieGoal,
  });

  @override
  ConsumerState<_SuggestionSheet> createState() => _SuggestionSheetState();
}

class _SuggestionSheetState extends ConsumerState<_SuggestionSheet> {
  String? _text;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final proteinGoal      = ((widget.calorieGoal * 0.25) / 4).round();
      final remainingProtein = (proteinGoal - widget.consumedProtein).clamp(0, proteinGoal);
      final result = await AIService.instance.getMealSuggestion(
        remainingCalories: widget.remainingCalories.clamp(0, 9999),
        remainingProtein:  remainingProtein,
        mealLabel:         widget.mealType.label,
      );
      if (mounted) setState(() { _loading = false; _text = result; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _text = 'Öneri alınamadı, tekrar dene.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.mealType.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text('${widget.mealType.label} Önerisi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: vc.text)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close_rounded, color: vc.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Kalan ${widget.remainingCalories} kcal bütçene göre',
            style: TextStyle(fontSize: 12, color: vc.textMuted),
          ),
          const SizedBox(height: 16),
          if (_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    CircularProgressIndicator(strokeWidth: 2, color: vc.primary),
                    const SizedBox(height: 12),
                    Text('Öneri hazırlanıyor...', style: TextStyle(fontSize: 13, color: vc.textSub)),
                  ],
                ),
              ),
            )
          else
            Text(_text ?? '', style: TextStyle(fontSize: 14, color: vc.text, height: 1.7)),
          if (!_loading) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () { setState(() { _loading = true; _text = null; }); _load(); },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, size: 15, color: vc.primary),
                  const SizedBox(width: 6),
                  Text('Yeniden oluştur', style: TextStyle(fontSize: 13, color: vc.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Barkod Tarayıcı Sheet ─────────────────────────────────────────────────────

class _BarcodeScannerSheet extends StatefulWidget {
  const _BarcodeScannerSheet();

  @override
  State<_BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<_BarcodeScannerSheet> {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool    _detected    = false;
  String? _pendingCode;
  Timer?  _confirmTimer;

  @override
  void dispose() {
    _confirmTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    // Aynı barkod zaten sayılıyorsa tekrar sayma
    if (code == _pendingCode) return;

    // Farklı barkod geldi — önceki sayacı iptal et, yenisini başlat
    _confirmTimer?.cancel();
    setState(() => _pendingCode = code);

    _confirmTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted || _detected) return;
      _detected = true;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: screenH * 0.82,
        child: Stack(
          children: [
            // Kamera önizlemesi
            MobileScanner(
              controller: _ctrl,
              onDetect: _onDetect,
            ),

            // Koyu üst şerit — başlık
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Barkod Tara',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tarama çerçevesi (görsel kılavuz)
            Center(
              child: Container(
                width: 260,
                height: 110,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    // Köşe vurgular
                    ..._corners(),
                  ],
                ),
              ),
            ),

            // Alt ipucu veya algılama onayı
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: _pendingCode != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Algılandı — onaylanıyor...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Ürün paketinin barkodunu çerçeve içine alın',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Köşe vurgu çizgileri — tarama alanını netleştirir.
  List<Widget> _corners() {
    const size  = 20.0;
    const thick = 3.0;
    const color = Color(0xFF1A7A6E);

    Widget h() => _CornerLine(horizontal: true,  size: size, thick: thick, color: color);
    Widget v() => _CornerLine(horizontal: false, size: size, thick: thick, color: color);

    return [
      Positioned(top: 0,    left: 0,  child: h()),
      Positioned(top: 0,    left: 0,  child: v()),
      Positioned(top: 0,    right: 0, child: h()),
      Positioned(top: 0,    right: 0, child: v()),
      Positioned(bottom: 0, left: 0,  child: h()),
      Positioned(bottom: 0, left: 0,  child: v()),
      Positioned(bottom: 0, right: 0, child: h()),
      Positioned(bottom: 0, right: 0, child: v()),
    ];
  }
}

class _CornerLine extends StatelessWidget {
  final bool horizontal;
  final double size;
  final double thick;
  final Color color;

  const _CornerLine({
    required this.horizontal,
    required this.size,
    required this.thick,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  horizontal ? size : thick,
      height: horizontal ? thick : size,
      color:  color,
    );
  }
}

// ── Öğün Tipi Seçici Sheet ────────────────────────────────────────────────────

class _MealTypePickerSheet extends StatelessWidget {
  final int remaining;
  const _MealTypePickerSheet({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hangi öğün için?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: vc.text)),
          const SizedBox(height: 4),
          Text('Kalan $remaining kcal bütçene göre öneri oluşturulacak',
              style: TextStyle(fontSize: 12, color: vc.textMuted)),
          const SizedBox(height: 16),
          ...MealType.values.map((type) => GestureDetector(
            onTap: () => Navigator.pop(context, type),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: vc.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: vc.border),
              ),
              child: Row(
                children: [
                  Text(type.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(type.label,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: vc.text)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: vc.textMuted),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// ── Tariflerim Kart ───────────────────────────────────────────────────────────

class _RecipesCard extends StatelessWidget {
  final void Function(MealEntry) onAdd;

  const _RecipesCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RecipesPage(
          onAddToLog: (recipe, type) {
            onAdd(MealEntry(
              id:       'recipe_${DateTime.now().millisecondsSinceEpoch}',
              name:     recipe.name,
              type:     type,
              calories: recipe.caloriesPerServing,
              proteinG: recipe.proteinGPerServing,
              carbsG:   recipe.carbsGPerServing,
              fatG:     recipe.fatGPerServing,
              fiberG:   recipe.fiberGPerServing,
              sodiumMg: recipe.sodiumMgPerServing,
              sugarG:   recipe.sugarGPerServing,
              time:     DateTime.now(),
            ));
          },
        ),
      )),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:        vc.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: vc.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color:        const Color(0xFF3B82F6).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Color(0xFF3B82F6),
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tariflerim',
                    style: TextStyle(
                      fontSize:   15,
                      fontWeight: FontWeight.w700,
                      color:      vc.text,
                    ),
                  ),
                  Text(
                    'Kendi tarifini oluştur, bir kez hesapla',
                    style: TextStyle(fontSize: 12, color: vc.textSub),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: vc.textSub),
          ],
        ),
      ),
    );
  }
}
