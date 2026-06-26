import 'package:flutter/material.dart';
import '../../../core/theme/v_theme.dart';

class OnboardingTopBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  const OnboardingTopBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.onBack,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Row(
      children: [
        if (onBack != null)
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: vc.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: vc.text,
              ),
            ),
          )
        else
          const SizedBox(width: 40),

        Expanded(
          child: Column(
            children: [
              Text(
                '$currentStep / $totalSteps',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: vc.textSub,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: currentStep / totalSteps,
                  backgroundColor: vc.primarySurface,
                  valueColor: AlwaysStoppedAnimation(vc.primary),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ),

        if (onSkip != null)
          GestureDetector(
            onTap: onSkip,
            child: SizedBox(
              width: 40,
              child: Text(
                'Atla',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: vc.primary,
                ),
              ),
            ),
          )
        else
          const SizedBox(width: 40),
      ],
    );
  }
}
