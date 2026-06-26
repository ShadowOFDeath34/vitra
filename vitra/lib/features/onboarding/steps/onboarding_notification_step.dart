import 'package:flutter/material.dart';
import '../../../core/theme/v_theme.dart';

class OnboardingNotificationStep extends StatelessWidget {
  final int? dailyCalories;
  final double? dailyWaterLiters;
  final VoidCallback onEnable;
  final VoidCallback onSkip;

  const OnboardingNotificationStep({
    super.key,
    this.dailyCalories,
    this.dailyWaterLiters,
    required this.onEnable,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Neredeyse hazırsın!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: vc.text,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bildirimler açık olsun mu?',
          style: TextStyle(fontSize: 15, color: vc.textSub),
        ),
        const SizedBox(height: 24),

        // Kişisel özet kartı
        if (dailyCalories != null && dailyWaterLiters != null)
          _SummaryCard(
            calories: dailyCalories!,
            waterLiters: dailyWaterLiters!,
          ),

        const Spacer(),

        // Bildirim bölümü
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: vc.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🔔', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Vitra seni hatırlatsın mı?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: vc.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Su içme ve rutin hatırlatmaları için',
                style: TextStyle(fontSize: 13, color: vc.textSub),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Butonlar
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: onEnable,
            child: const Text('Evet, açık kalsın'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: onSkip,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: vc.primary, width: 1.5),
              foregroundColor: vc.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Şimdi değil'),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int calories;
  final double waterLiters;

  const _SummaryCard({required this.calories, required this.waterLiters});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: vc.primarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: vc.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'Senin için hesaplandı',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: vc.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  emoji: '🔥',
                  value: '$calories kcal',
                  label: 'Günlük kalori',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  emoji: '💧',
                  value: '${waterLiters.toStringAsFixed(1)} litre',
                  label: 'Günlük su',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Aktivite düzeyin ve hedeflerine göre hesaplandı.',
            style: TextStyle(
              fontSize: 11,
              color: vc.textSub,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StatBox({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(12),
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
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: vc.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: vc.textSub),
          ),
        ],
      ),
    );
  }
}
