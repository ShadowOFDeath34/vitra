import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/v_theme.dart';

class OnboardingTargetWeightStep extends StatefulWidget {
  final double? currentWeightKg;
  final double? targetWeightKg;
  final double weeklyPaceFactor;
  final List<String> goals;
  final ValueChanged<double?> onTargetChanged;
  final ValueChanged<double> onPaceChanged;
  final VoidCallback onNext;

  const OnboardingTargetWeightStep({
    super.key,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.weeklyPaceFactor,
    required this.goals,
    required this.onTargetChanged,
    required this.onPaceChanged,
    required this.onNext,
  });

  @override
  State<OnboardingTargetWeightStep> createState() =>
      _OnboardingTargetWeightStepState();
}

class _OnboardingTargetWeightStepState
    extends State<OnboardingTargetWeightStep> {
  late final TextEditingController _ctrl;

  static const _paces = [
    _Pace(0.25, 'Yavaş', '0.25 kg/hafta', '-275 kcal/gün', '🐢'),
    _Pace(0.5,  'Normal', '0.5 kg/hafta',  '-550 kcal/gün', '🏃'),
    _Pace(0.75, 'Hızlı', '0.75 kg/hafta', '-825 kcal/gün', '⚡'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.targetWeightKg != null
          ? widget.targetWeightKg!.toStringAsFixed(1)
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTextChanged(String v) {
    final parsed = double.tryParse(v.replaceAll(',', '.'));
    widget.onTargetChanged(parsed);
  }

  String? _weeksToGoal() {
    final current = widget.currentWeightKg;
    final target  = widget.targetWeightKg;
    if (current == null || target == null) return null;
    final diff = (current - target).abs();
    if (diff < 0.1) return null;
    final weeks = (diff / widget.weeklyPaceFactor).ceil();
    return '~$weeks haftada hedefinize ulaşırsınız';
  }

  bool get _isLosing => widget.goals.contains('lose_weight');

  bool get _canContinue {
    if (widget.targetWeightKg == null) return false;
    if (widget.targetWeightKg! <= 0 || widget.targetWeightKg! > 300) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final eta = _weeksToGoal();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isLosing ? 'Hedef kilonu belirle' : 'Hedef ağırlığını belirle',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: vc.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kalori hedefini buna göre kişiselleştireceğiz.',
            style: TextStyle(fontSize: 15, color: vc.textSub),
          ),
          const SizedBox(height: 32),

          // Hedef kilo girişi
          Text(
            'Hedef kilo (kg)',
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
                    : vc.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              onChanged: _onTextChanged,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: vc.text,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: widget.currentWeightKg != null
                    ? (widget.currentWeightKg! * (_isLosing ? 0.9 : 1.05))
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
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),

          // Mevcut - Hedef farkı göstergesi
          if (widget.currentWeightKg != null && widget.targetWeightKg != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _DiffIndicator(
                current: widget.currentWeightKg!,
                target: widget.targetWeightKg!,
                isLosing: _isLosing,
              ),
            ),

          const SizedBox(height: 32),

          // Haftalık hız başlığı
          Text(
            'Haftalık hız',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: vc.textSub,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),

          // Hız kartları
          Row(
            children: _paces.map((pace) {
              final selected = widget.weeklyPaceFactor == pace.factor;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: pace == _paces.last ? 0 : 8,
                  ),
                  child: _PaceCard(
                    pace: pace,
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

          // ETA hesabı
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: eta != null
                ? Padding(
                    key: ValueKey(eta),
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: vc.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: vc.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🎯', style: const TextStyle(fontSize: 16)),
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
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 32),

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

class _DiffIndicator extends StatelessWidget {
  final double current;
  final double target;
  final bool isLosing;

  const _DiffIndicator({
    required this.current,
    required this.target,
    required this.isLosing,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final diff = (current - target).abs();
    final isGoingDown = target < current;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${current.toStringAsFixed(1)} kg',
          style: TextStyle(fontSize: 13, color: vc.textSub),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            isGoingDown
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            size: 14,
            color: isGoingDown ? const Color(0xFF22C55E) : vc.primary,
          ),
        ),
        Text(
          '${target.toStringAsFixed(1)} kg',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: vc.text,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '(${diff.toStringAsFixed(1)} kg)',
          style: TextStyle(fontSize: 12, color: vc.textSub),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(vertical: 14),
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
            const SizedBox(height: 6),
            Text(
              pace.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? vc.primary : vc.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              pace.speed,
              style: TextStyle(fontSize: 10, color: vc.textSub),
            ),
            const SizedBox(height: 2),
            Text(
              pace.deficit,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: selected ? vc.primary.withValues(alpha: 0.8) : vc.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pace {
  final double factor;
  final String label;
  final String speed;
  final String deficit;
  final String emoji;
  const _Pace(this.factor, this.label, this.speed, this.deficit, this.emoji);
}
