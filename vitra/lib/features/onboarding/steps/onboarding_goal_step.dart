import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/v_theme.dart';

class OnboardingGoalStep extends StatefulWidget {
  final List<String> selectedGoals;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final double weeklyPaceFactor;
  final ValueChanged<List<String>> onChanged;
  final ValueChanged<double?> onTargetChanged;
  final ValueChanged<double> onPaceChanged;
  final VoidCallback onNext;

  const OnboardingGoalStep({
    super.key,
    required this.selectedGoals,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.weeklyPaceFactor,
    required this.onChanged,
    required this.onTargetChanged,
    required this.onPaceChanged,
    required this.onNext,
  });

  @override
  State<OnboardingGoalStep> createState() => _OnboardingGoalStepState();
}

class _OnboardingGoalStepState extends State<OnboardingGoalStep> {
  static const _goals = [
    _Goal('lose_weight',   '🏃', 'Kilo vermek'),
    _Goal('gain_muscle',   '💪', 'Kas kazanmak'),
    _Goal('stay_healthy',  '🌿', 'Sağlıklı kalmak'),
    _Goal('eat_better',    '🥗', 'Daha iyi beslenme'),
    _Goal('drink_more',    '💧', 'Daha fazla su'),
    _Goal('build_habits',  '✅', 'Alışkanlık oluşturmak'),
  ];

  static const _paces = [
    _Pace(0.25, 'Yavaş',  '0.25 kg/hafta', '🐢'),
    _Pace(0.5,  'Normal', '0.5 kg/hafta',  '🏃'),
    _Pace(0.75, 'Hızlı',  '0.75 kg/hafta', '⚡'),
  ];

  late final TextEditingController _targetCtrl;

  @override
  void initState() {
    super.initState();
    _targetCtrl = TextEditingController(
      text: widget.targetWeightKg != null
          ? widget.targetWeightKg!.toStringAsFixed(1)
          : '',
    );
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    super.dispose();
  }

  bool get _needsTarget =>
      widget.selectedGoals.contains('lose_weight') ||
      widget.selectedGoals.contains('gain_muscle');

  bool get _canContinue {
    if (widget.selectedGoals.isEmpty) return false;
    if (_needsTarget) {
      final t = widget.targetWeightKg;
      return t != null && t > 0 && t < 300;
    }
    return true;
  }

  String? _eta() {
    final current = widget.currentWeightKg;
    final target  = widget.targetWeightKg;
    if (current == null || target == null) return null;
    final diff = (current - target).abs();
    if (diff < 0.1) return null;
    final weeks = (diff / widget.weeklyPaceFactor).ceil();
    return '~$weeks haftada hedefinize ulaşırsınız';
  }

  void _toggle(String id) {
    final current = List<String>.from(widget.selectedGoals);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    widget.onChanged(current);
    // Hedef kilo gerektirmeyen hedef seçilince hedef kiloyu sıfırla
    if (!current.contains('lose_weight') && !current.contains('gain_muscle')) {
      widget.onTargetChanged(null);
      _targetCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc  = context.vt;
    final eta = _eta();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hedefin ne?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: vc.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Birden fazla seçebilirsin.',
            style: TextStyle(fontSize: 15, color: vc.textSub, height: 1.4),
          ),
          const SizedBox(height: 24),

          // ── Hedef kartları 2x3 ────────────────────────────────────────
          for (int row = 0; row < 3; row++) ...[
            Row(
              children: [
                for (int col = 0; col < 2; col++) ...[
                  Expanded(
                    child: Builder(builder: (_) {
                      final goal    = _goals[row * 2 + col];
                      final selected = widget.selectedGoals.contains(goal.id);
                      return _GoalCard(
                        goal:     goal,
                        selected: selected,
                        onTap:    () => _toggle(goal.id),
                      );
                    }),
                  ),
                  if (col == 0) const SizedBox(width: 12),
                ],
              ],
            ),
            if (row < 2) const SizedBox(height: 12),
          ],

          // ── Hedef kilo + haftalık hız (koşullu) ───────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _needsTarget
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),
                      Divider(color: vc.border),
                      const SizedBox(height: 20),

                      // Hedef kilo
                      Text(
                        'Hedef Kilo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: vc.textSub,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: vc.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: widget.targetWeightKg != null
                                ? vc.primary
                                : vc.primary.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _targetCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.,]')),
                          ],
                          onChanged: (v) {
                            final parsed =
                                double.tryParse(v.replaceAll(',', '.'));
                            widget.onTargetChanged(parsed);
                          },
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: vc.text,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: widget.currentWeightKg != null
                                ? (widget.currentWeightKg! *
                                        (widget.selectedGoals
                                                .contains('lose_weight')
                                            ? 0.9
                                            : 1.05))
                                    .toStringAsFixed(1)
                                : '70.0',
                            hintStyle: TextStyle(
                              color: vc.textMuted.withValues(alpha: 0.4),
                              fontWeight: FontWeight.w400,
                              fontSize: 22,
                            ),
                            suffixText: 'kg',
                            suffixStyle: TextStyle(
                              fontSize: 16,
                              color: vc.textSub,
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Haftalık hız
                      Text(
                        'Haftalık Hız',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: vc.textSub,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: _paces.map((pace) {
                          final selected =
                              widget.weeklyPaceFactor == pace.factor;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: pace == _paces.last ? 0 : 8,
                              ),
                              child: _PaceCard(
                                pace:     pace,
                                selected: selected,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  widget.onPaceChanged(pace.factor);
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // ETA
                      if (eta != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: vc.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: vc.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🎯',
                                  style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                eta,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: vc.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _canContinue ? widget.onNext : null,
              child: const Text('Devam'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final _Goal goal;
  final bool selected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 90,
        decoration: BoxDecoration(
          color: selected ? vc.primarySurface : vc.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? vc.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: selected ? 0.04 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(goal.emoji,
                style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              goal.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? vc.primary : vc.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaceCard extends StatelessWidget {
  final _Pace pace;
  final bool selected;
  final VoidCallback onTap;

  const _PaceCard({
    required this.pace,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? vc.primarySurface : vc.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? vc.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.03 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(pace.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              pace.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? vc.primary : vc.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              pace.speed,
              style: TextStyle(fontSize: 10, color: vc.textSub),
            ),
          ],
        ),
      ),
    );
  }
}

class _Goal {
  final String id;
  final String emoji;
  final String label;
  const _Goal(this.id, this.emoji, this.label);
}

class _Pace {
  final double factor;
  final String label;
  final String speed;
  final String emoji;
  const _Pace(this.factor, this.label, this.speed, this.emoji);
}
