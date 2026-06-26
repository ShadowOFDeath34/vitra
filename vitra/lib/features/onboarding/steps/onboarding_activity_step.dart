import 'package:flutter/material.dart';
import '../../../core/theme/v_theme.dart';

class OnboardingActivityStep extends StatefulWidget {
  final String? selectedActivity;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  // Canlı hesap için profil verisi
  final double? weightKg;
  final double? heightCm;
  final int? age;
  final String? gender;
  final List<String> goals;
  final double weeklyPaceFactor;

  const OnboardingActivityStep({
    super.key,
    required this.selectedActivity,
    required this.onChanged,
    required this.onNext,
    this.weightKg,
    this.heightCm,
    this.age,
    this.gender,
    this.goals = const [],
    this.weeklyPaceFactor = 0.5,
  });

  @override
  State<OnboardingActivityStep> createState() => _OnboardingActivityStepState();
}

class _OnboardingActivityStepState extends State<OnboardingActivityStep> {
  static const _levels = [
    _Level('sedentary', '🪑', 'Hareketsiz', 'Masabaşı çalışıyorum, az hareket', 1.2),
    _Level('light', '🚶', 'Hafif aktif', 'Haftada 1–3 gün egzersiz', 1.375),
    _Level('moderate', '🏃', 'Orta aktif', 'Haftada 3–5 gün egzersiz', 1.55),
    _Level('very', '⚡', 'Çok aktif', 'Haftada 6–7 gün yoğun antrenman', 1.725),
  ];

  // Seçili aktiviteye göre canlı hesap
  _CalcResult? _calculate(String activityId) {
    if (widget.weightKg == null || widget.heightCm == null ||
        widget.age == null || widget.gender == null) { return null; }

    final w = widget.weightKg!;
    final h = widget.heightCm!;
    final a = widget.age!;
    final isMale = widget.gender == 'male';

    final bmr = isMale
        ? 10 * w + 6.25 * h - 5 * a + 5
        : 10 * w + 6.25 * h - 5 * a - 161;

    final multiplier = _levels.firstWhere((l) => l.id == activityId).multiplier;
    final tdee = bmr * multiplier;

    final deficit = (widget.weeklyPaceFactor * 7700 / 7).round();
    double calories = tdee;
    if (widget.goals.contains('lose_weight'))      calories = (tdee - deficit).clamp(1200, 9999);
    else if (widget.goals.contains('gain_muscle')) calories = tdee + 300;
    else if (widget.goals.contains('eat_better'))  calories = (tdee - 200).clamp(1200, 9999);

    final activityBonus = activityId == 'very' ? 500 : activityId == 'moderate' ? 300 : 0;
    final drinkBonus    = widget.goals.contains('drink_more') ? 500 : 0;
    final waterMl       = (w * 33).round() + activityBonus + drinkBonus;

    return _CalcResult(calories.round(), waterMl);
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final calc = widget.selectedActivity != null
        ? _calculate(widget.selectedActivity!)
        : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yaşam tarzın nasıl?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: vc.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Su ve kalori hedefini buna göre ayarlayalım.',
            style: TextStyle(fontSize: 15, color: vc.textSub),
          ),
          const SizedBox(height: 24),

          // Aktivite kartları
          ...(_levels.map((level) {
            final selected = widget.selectedActivity == level.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActivityCard(
                level: level,
                selected: selected,
                onTap: () => widget.onChanged(level.id),
              ),
            );
          })),

          const SizedBox(height: 8),

          // Canlı hesap sonucu — sadece veri varsa göster
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: calc != null
                ? _LiveCalcCard(key: ValueKey(widget.selectedActivity), result: calc)
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: widget.selectedActivity != null ? widget.onNext : null,
              child: const Text('Devam'),
            ),
          ),
        ],
      ),
    );
  }
}

// Canlı hesap kartı — kullanıcının "aha" anı
class _LiveCalcCard extends StatelessWidget {
  final _CalcResult result;
  const _LiveCalcCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: vc.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatChip(
              icon: '🔥',
              label: 'Kalori hedefin',
              value: '${result.calories} kcal',
            ),
          ),
          Container(width: 1, height: 40, color: vc.primary.withValues(alpha: 0.15)),
          Expanded(
            child: _StatChip(
              icon: '💧',
              label: 'Su hedefin',
              value: '${(result.waterMl / 1000).toStringAsFixed(1)} litre',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _StatChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: vc.textSub)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: vc.primary,
            )),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final _Level level;
  final bool selected;
  final VoidCallback onTap;
  const _ActivityCard({required this.level, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? vc.primarySurface : vc.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? vc.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(level.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? vc.primary : vc.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    level.description,
                    style: TextStyle(fontSize: 12, color: vc.textSub),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: vc.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Level {
  final String id;
  final String emoji;
  final String label;
  final String description;
  final double multiplier;
  const _Level(this.id, this.emoji, this.label, this.description, this.multiplier);
}

class _CalcResult {
  final int calories;
  final int waterMl;
  const _CalcResult(this.calories, this.waterMl);
}
