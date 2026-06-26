import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/v_theme.dart';

class OnboardingLifestyleStep extends StatefulWidget {
  final String? gender;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String? selectedActivity;
  final List<String> goals;
  final double weeklyPaceFactor;
  final double? targetWeightKg;

  final ValueChanged<String> onGenderChanged;
  final ValueChanged<int> onAgeChanged;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<String> onActivityChanged;
  final VoidCallback onNext;

  const OnboardingLifestyleStep({
    super.key,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.selectedActivity,
    required this.goals,
    required this.weeklyPaceFactor,
    this.targetWeightKg,
    required this.onGenderChanged,
    required this.onAgeChanged,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onActivityChanged,
    required this.onNext,
  });

  @override
  State<OnboardingLifestyleStep> createState() =>
      _OnboardingLifestyleStepState();
}

class _OnboardingLifestyleStepState extends State<OnboardingLifestyleStep> {
  static const _levels = [
    _Level('sedentary', '🪑', 'Hareketsiz',   'Masabaşı çalışıyorum, az hareket', 1.2),
    _Level('light',     '🚶', 'Hafif aktif',   'Haftada 1–3 gün egzersiz',         1.375),
    _Level('moderate',  '🏃', 'Orta aktif',    'Haftada 3–5 gün egzersiz',         1.55),
    _Level('very',      '⚡', 'Çok aktif',     'Haftada 6–7 gün yoğun antrenman',  1.725),
  ];

  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;

  @override
  void initState() {
    super.initState();
    _heightCtrl = TextEditingController(
        text: widget.heightCm?.toStringAsFixed(0) ?? '');
    _weightCtrl = TextEditingController(
        text: widget.weightKg?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  bool get _isComplete =>
      widget.gender != null &&
      widget.age != null &&
      widget.heightCm != null &&
      widget.weightKg != null &&
      widget.selectedActivity != null;

  String? _eta() {
    final current = widget.weightKg;
    final target  = widget.targetWeightKg;
    if (current == null || target == null) return null;
    if (!widget.goals.contains('lose_weight') && !widget.goals.contains('gain_muscle')) return null;
    final diff = (current - target).abs();
    if (diff < 0.1) return null;
    final weeks = (diff / widget.weeklyPaceFactor).ceil();
    return '~$weeks haftada hedefinize ulaşırsınız';
  }

  _CalcResult? _calculate() {
    if (!_isComplete) return null;
    final w       = widget.weightKg!;
    final h       = widget.heightCm!;
    final a       = widget.age!;
    final isMale  = widget.gender == 'male';
    final bmr     = isMale
        ? 10 * w + 6.25 * h - 5 * a + 5
        : 10 * w + 6.25 * h - 5 * a - 161;
    final mult    = _levels.firstWhere((l) => l.id == widget.selectedActivity!).multiplier;
    final tdee    = bmr * mult;
    final deficit = (widget.weeklyPaceFactor * 7700 / 7).round();

    double calories = tdee;
    if (widget.goals.contains('lose_weight'))
      calories = (tdee - deficit).clamp(1200, 9999);
    else if (widget.goals.contains('gain_muscle'))
      calories = tdee + 300;
    else if (widget.goals.contains('eat_better'))
      calories = (tdee - 200).clamp(1200, 9999);

    final actBonus   = widget.selectedActivity == 'very' ? 500 : widget.selectedActivity == 'moderate' ? 300 : 0;
    final drinkBonus = widget.goals.contains('drink_more') ? 500 : 0;
    final waterMl    = (w * 33).round() + actBonus + drinkBonus;

    return _CalcResult(calories.round(), waterMl);
  }

  @override
  Widget build(BuildContext context) {
    final vc   = context.vt;
    final calc = _calculate();
    final eta  = _eta();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yaşam tarzın',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: vc.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sana özel hedefler hesaplayalım.',
            style: TextStyle(fontSize: 15, color: vc.textSub, height: 1.4),
          ),
          const SizedBox(height: 24),

          // ── Cinsiyet ──────────────────────────────────────────────────
          _Label('Cinsiyet'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _GenderButton(
                  label:    'Erkek',
                  emoji:    '👨',
                  selected: widget.gender == 'male',
                  onTap:    () => widget.onGenderChanged('male'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GenderButton(
                  label:    'Kadın',
                  emoji:    '👩',
                  selected: widget.gender == 'female',
                  onTap:    () => widget.onGenderChanged('female'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Yaş ──────────────────────────────────────────────────────
          _Label('Yaşın'),
          const SizedBox(height: 8),
          _AgeStepper(
            value:     widget.age ?? 25,
            onChanged: widget.onAgeChanged,
          ),

          const SizedBox(height: 20),

          // ── Boy + Kilo ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Boyun'),
                    const SizedBox(height: 8),
                    _MeasureField(
                      controller: _heightCtrl,
                      unit:       'cm',
                      hint:       '175',
                      min:        100,
                      max:        250,
                      onChanged:  widget.onHeightChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Kilonuz'),
                    const SizedBox(height: 8),
                    _MeasureField(
                      controller: _weightCtrl,
                      unit:       'kg',
                      hint:       '70',
                      min:        30,
                      max:        300,
                      onChanged:  widget.onWeightChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: vc.border),
          const SizedBox(height: 16),

          // ── Aktivite seviyesi ─────────────────────────────────────────
          _Label('Aktivite Seviyesi'),
          const SizedBox(height: 12),
          ...(_levels.map((level) {
            final selected = widget.selectedActivity == level.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActivityCard(
                level:    level,
                selected: selected,
                onTap:    () => widget.onActivityChanged(level.id),
              ),
            );
          })),

          // ── Canlı hesap kartı ──────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: calc != null
                ? _LiveCalcCard(
                    key:    ValueKey(widget.selectedActivity),
                    result: calc,
                  )
                : const SizedBox.shrink(),
          ),

          // ── Hedef ETA ──────────────────────────────────────────────────
          if (eta != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: vc.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: vc.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Text('🎯', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Text(
                    eta,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: vc.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Gizlilik notu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: vc.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('🔒', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Verilerini yalnızca sana özel hesaplamalar için kullanıyoruz.',
                    style: TextStyle(
                        fontSize: 12, color: vc.textSub, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isComplete ? widget.onNext : null,
              child: const Text('Devam'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Yardımcı widgetlar ──────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: vc.textSub,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.emoji,
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
        height: 52,
        decoration: BoxDecoration(
          color: selected ? vc.primary : vc.surface,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: selected ? vc.primary : vc.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : vc.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeStepper extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _AgeStepper({required this.value, required this.onChanged});

  @override
  State<_AgeStepper> createState() => _AgeStepperState();
}

class _AgeStepperState extends State<_AgeStepper> {
  bool _editing = false;
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl  = TextEditingController(text: '${widget.value}');
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _commit();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _editing   = true;
      _ctrl.text = '${widget.value}';
      _ctrl.selection =
          TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _commit() {
    final parsed = int.tryParse(_ctrl.text);
    if (parsed != null && parsed >= 10 && parsed <= 120) {
      widget.onChanged(parsed);
    } else {
      _ctrl.text = '${widget.value}';
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(12),
        border: _editing
            ? Border.all(color: vc.primary, width: 1.5)
            : null,
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
          _StepBtn(
            icon:  Icons.remove,
            onTap: widget.value > 10
                ? () {
                    if (_editing) _focus.unfocus();
                    widget.onChanged(widget.value - 1);
                  }
                : null,
          ),
          Expanded(
            child: _editing
                ? TextField(
                    controller: _ctrl,
                    focusNode:  _focus,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: vc.primary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _commit(),
                  )
                : GestureDetector(
                    onTap: _startEditing,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      '${widget.value}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: vc.text,
                      ),
                    ),
                  ),
          ),
          _StepBtn(
            icon:  Icons.add,
            onTap: widget.value < 120
                ? () {
                    if (_editing) _focus.unfocus();
                    widget.onChanged(widget.value + 1);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: onTap != null ? vc.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            size:  20,
            color: onTap != null ? vc.primary : vc.textMuted),
      ),
    );
  }
}

class _MeasureField extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final String hint;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _MeasureField({
    required this.controller,
    required this.unit,
    required this.hint,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(12),
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
          Expanded(
            child: TextField(
              controller:   controller,
              keyboardType: TextInputType.number,
              textAlign:    TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize:   22,
                fontWeight: FontWeight.w700,
                color:      vc.text,
              ),
              decoration: InputDecoration(
                hintText:  hint,
                hintStyle: TextStyle(color: vc.textMuted),
                border:    InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null && parsed >= min && parsed <= max) {
                  onChanged(parsed);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Text(
              unit,
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color:      vc.textSub,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final _Level level;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.level,
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
                      fontSize:   15,
                      fontWeight: FontWeight.w600,
                      color:      selected ? vc.primary : vc.text,
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
              Icon(Icons.check_circle_rounded,
                  color: vc.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LiveCalcCard extends StatelessWidget {
  final _CalcResult result;
  const _LiveCalcCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color:        vc.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: vc.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Chip(
              icon:  '🔥',
              label: 'Kalori hedefin',
              value: '${result.calories} kcal',
            ),
          ),
          Container(
              width: 1,
              height: 40,
              color: vc.primary.withValues(alpha: 0.15)),
          Expanded(
            child: _Chip(
              icon:  '💧',
              label: 'Su hedefin',
              value:
                  '${(result.waterMl / 1000).toStringAsFixed(1)} litre',
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _Chip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: vc.textSub)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              fontSize:   15,
              fontWeight: FontWeight.w700,
              color:      vc.primary,
            )),
      ],
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
