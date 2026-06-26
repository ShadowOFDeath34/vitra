import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/v_theme.dart';

class OnboardingProfileStep extends StatefulWidget {
  final String? gender;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<int> onAgeChanged;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onWeightChanged;
  final VoidCallback onNext;

  const OnboardingProfileStep({
    super.key,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.onGenderChanged,
    required this.onAgeChanged,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onNext,
  });

  @override
  State<OnboardingProfileStep> createState() => _OnboardingProfileStepState();
}

class _OnboardingProfileStepState extends State<OnboardingProfileStep> {
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;

  @override
  void initState() {
    super.initState();
    _heightCtrl = TextEditingController(
      text: widget.heightCm?.toStringAsFixed(0) ?? '',
    );
    _weightCtrl = TextEditingController(
      text: widget.weightKg?.toStringAsFixed(0) ?? '',
    );
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
      widget.weightKg != null;

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sen kimsin?',
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
            style: TextStyle(fontSize: 15, color: vc.textSub),
          ),
          const SizedBox(height: 28),

          // Cinsiyet toggle
          _SectionLabel('Cinsiyet'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _GenderButton(
                  label: 'Erkek',
                  emoji: '👨',
                  selected: widget.gender == 'male',
                  onTap: () => widget.onGenderChanged('male'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GenderButton(
                  label: 'Kadın',
                  emoji: '👩',
                  selected: widget.gender == 'female',
                  onTap: () => widget.onGenderChanged('female'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Yaş stepper
          _SectionLabel('Yaşın'),
          const SizedBox(height: 8),
          _AgeStepper(
            value: widget.age ?? 25,
            onChanged: widget.onAgeChanged,
          ),

          const SizedBox(height: 20),

          // Boy & Kilo yan yana
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Boyun'),
                    const SizedBox(height: 8),
                    _MeasurementField(
                      controller: _heightCtrl,
                      unit: 'cm',
                      hint: '175',
                      min: 100,
                      max: 250,
                      onChanged: (v) => widget.onHeightChanged(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Kilonuz'),
                    const SizedBox(height: 8),
                    _MeasurementField(
                      controller: _weightCtrl,
                      unit: 'kg',
                      hint: '70',
                      min: 30,
                      max: 300,
                      onChanged: (v) => widget.onWeightChanged(v),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bilgi notu
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
                    style: TextStyle(fontSize: 12, color: vc.textSub, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isComplete ? widget.onNext : null,
              child: const Text('Devam'),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

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
          border: Border.all(
            color: selected ? vc.primary : vc.border,
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
      _editing = true;
      _ctrl.text = '${widget.value}';
      _ctrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _ctrl.text.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
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
          _StepButton(
            icon: Icons.remove,
            onTap: widget.value > 10 ? () {
              if (_editing) { _focus.unfocus(); }
              widget.onChanged(widget.value - 1);
            } : null,
          ),
          Expanded(
            child: _editing
                ? TextField(
                    controller: _ctrl,
                    focusNode: _focus,
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
          _StepButton(
            icon: Icons.add,
            onTap: widget.value < 120 ? () {
              if (_editing) { _focus.unfocus(); }
              widget.onChanged(widget.value + 1);
            } : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.onTap});

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
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? vc.primary : vc.textMuted,
        ),
      ),
    );
  }
}

class _MeasurementField extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final String hint;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _MeasurementField({
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
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: vc.text,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: vc.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: vc.textSub,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
