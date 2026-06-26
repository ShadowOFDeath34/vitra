import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/v_theme.dart';

class OnboardingDietStep extends StatelessWidget {
  final List<String> selectedPreferences;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback onNext;

  const OnboardingDietStep({
    super.key,
    required this.selectedPreferences,
    required this.onChanged,
    required this.onNext,
  });

  static const _options = [
    _DietOption('all',        '🍽️', 'Her şeyi yerim',       'Kısıtlama yok'),
    _DietOption('vegetarian', '🥦', 'Vejeteryan',            'Et yemiyorum'),
    _DietOption('vegan',      '🌱', 'Vegan',                 'Hayvansal ürün yok'),
    _DietOption('gluten_free','🌾', 'Glutensiz',             'Gluten içermez'),
    _DietOption('keto',       '🥑', 'Ketojenik',             'Düşük karbonhidrat, yüksek yağ'),
    _DietOption('low_carb',   '🥩', 'Düşük karbonhidrat',   'Az karbonhidrat'),
  ];

  void _toggle(String id, List<String> current) {
    final updated = List<String>.from(current);

    // "Her şeyi yerim" seçilince diğerlerini temizle
    if (id == 'all') {
      onChanged(['all']);
      return;
    }

    // Başka bir seçenek seçilince "all"ı kaldır
    updated.remove('all');

    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }

    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beslenme tercihin?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: vc.text,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Koçun ve yemek önerileri buna göre kişiselleşecek.',
          style: TextStyle(fontSize: 15, color: vc.textSub, height: 1.4),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 14, color: vc.primary),
            const SizedBox(width: 6),
            Text(
              'Birden fazla seçebilirsin',
              style: TextStyle(fontSize: 13, color: vc.primary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Expanded(
          child: ListView.separated(
            itemCount: _options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final opt = _options[i];
              final selected = selectedPreferences.contains(opt.id);
              return _DietCard(
                option: opt,
                selected: selected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _toggle(opt.id, selectedPreferences);
                },
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: selectedPreferences.isNotEmpty ? onNext : null,
            child: const Text('Devam'),
          ),
        ),
      ],
    );
  }
}

class _DietCard extends StatelessWidget {
  final _DietOption option;
  final bool selected;
  final VoidCallback onTap;

  const _DietCard({
    required this.option,
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
            Text(option.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? vc.primary : vc.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: TextStyle(fontSize: 12, color: vc.textSub),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: selected
                  ? Icon(
                      key: const ValueKey(true),
                      Icons.check_circle_rounded,
                      color: vc.primary,
                      size: 20,
                    )
                  : Icon(
                      key: const ValueKey(false),
                      Icons.radio_button_unchecked_rounded,
                      color: vc.textMuted.withValues(alpha: 0.3),
                      size: 20,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DietOption {
  final String id;
  final String emoji;
  final String label;
  final String description;
  const _DietOption(this.id, this.emoji, this.label, this.description);
}
