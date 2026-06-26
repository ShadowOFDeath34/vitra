import 'package:flutter/material.dart';
import '../../../core/theme/v_theme.dart';

class OnboardingNameStep extends StatefulWidget {
  final String? name;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onNext;

  const OnboardingNameStep({
    super.key,
    required this.name,
    required this.onNameChanged,
    required this.onNext,
  });

  @override
  State<OnboardingNameStep> createState() => _OnboardingNameStepState();
}

class _OnboardingNameStepState extends State<OnboardingNameStep> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.name ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isValid => _ctrl.text.trim().length >= 2;

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sana nasıl\nhitap edelim?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: vc.text,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kişisel deneyimin için adını öğrenmek istiyoruz.',
            style: TextStyle(fontSize: 15, color: vc.textSub),
          ),
          const SizedBox(height: 40),

          Container(
            decoration: BoxDecoration(
              color: vc.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: vc.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: vc.text,
              ),
              decoration: InputDecoration(
                hintText: 'Adın',
                hintStyle: TextStyle(
                  color: vc.textMuted,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              onChanged: (v) {
                setState(() {});
                if (v.trim().length >= 2) widget.onNameChanged(v.trim());
              },
              onSubmitted: (_) {
                if (_isValid) widget.onNext();
              },
            ),
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isValid ? widget.onNext : null,
              child: const Text('Devam'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
