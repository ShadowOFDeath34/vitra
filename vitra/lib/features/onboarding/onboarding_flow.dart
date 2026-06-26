import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/v_theme.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import 'models/onboarding_data.dart';
import 'widgets/onboarding_top_bar.dart';
import 'steps/onboarding_name_step.dart';
import 'steps/onboarding_goal_step.dart';
import 'steps/onboarding_lifestyle_step.dart';
import 'steps/onboarding_diet_step.dart';
import 'steps/onboarding_routine_step.dart';

const _kTotalPages = 5;

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _pageController = PageController();
  final _data = OnboardingData();
  int _pageIndex = 0;

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _pageIndex = page);
  }

  void _nextStep() {
    final next = _pageIndex + 1;
    if (next >= _kTotalPages) {
      _finish();
      return;
    }
    _goToPage(next);
  }

  void _prevStep() {
    final prev = _pageIndex - 1;
    if (prev < 0) return;
    _goToPage(prev);
  }

  Future<void> _finish() async {
    final calorieGoal = _data.dailyCalorieGoal?.round() ?? 2000;
    final waterGoalMl = _data.dailyWaterGoalMl?.round() ?? 2000;

    // Seçilmeyen rutinleri devre dışı bırak
    const allRoutineIds = [
      'vitamin', 'cold_shower', 'meditation', 'morning_ex', 'daily_plan',
      'water_goal', 'walk', 'lunch_walk', 'fruit_veg',
      'read', 'reflection', 'sleep_time', 'no_screen', 'breathing', 'stretch',
    ];
    final disabled = allRoutineIds
        .where((id) => !_data.selectedRoutineIds.contains(id))
        .toList();

    await ref.read(userProfileProvider.notifier).completeOnboarding(
          calorieGoal:        calorieGoal,
          waterGoalMl:        waterGoalMl,
          userName:           _data.name,
          disabledRoutineIds: disabled,
          age:                _data.age,
          heightCm:           _data.heightCm,
          weightKg:           _data.weightKg,
          gender:             _data.gender,
          activityLevel:      _data.activityLevel,
          goals:              _data.goals,
          targetWeightKg:     _data.targetWeightKg,
          weeklyPaceFactor:   _data.weeklyPaceFactor,
          dietPreferences:    _data.dietPreferences,
        );

    // Onboarding kilo verilerini istatistik tablosuna korumalı kayıt olarak at
    if (_data.weightKg != null) {
      FirestoreService.instance.saveOnboardingWeightEntries(
        currentWeight: _data.weightKg!,
        targetWeight:  _data.targetWeightKg,
      );
    }

    // Bildirim izni — arka planda iste
    NotificationService.instance.requestPermission();

    if (!mounted) return;
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (_) => false);
    } else {
      Navigator.of(context).pushReplacementNamed('/onboarding/complete');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.vt.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              OnboardingTopBar(
                currentStep: _pageIndex + 1,
                totalSteps:  _kTotalPages,
                onBack:      _pageIndex > 0 ? _prevStep : null,
                onSkip:      _pageIndex < _kTotalPages - 1 ? _nextStep : null,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // ── Adım 1: İsim ───────────────────────────────────────
                    OnboardingNameStep(
                      name:          _data.name,
                      onNameChanged: (v) => setState(() => _data.name = v),
                      onNext:        _nextStep,
                    ),

                    // ── Adım 2: Hedef + Hedef Kilo + Haftalık Hız ──────────
                    OnboardingGoalStep(
                      selectedGoals:   _data.goals,
                      currentWeightKg: _data.weightKg,
                      targetWeightKg:  _data.targetWeightKg,
                      weeklyPaceFactor:_data.weeklyPaceFactor,
                      onChanged:       (v) => setState(() => _data.goals = v),
                      onTargetChanged: (v) => setState(() => _data.targetWeightKg = v),
                      onPaceChanged:   (v) => setState(() => _data.weeklyPaceFactor = v),
                      onNext:          _nextStep,
                    ),

                    // ── Adım 3: Yaşam Tarzı (Profil + Aktivite) ────────────
                    OnboardingLifestyleStep(
                      gender:           _data.gender,
                      age:              _data.age,
                      heightCm:         _data.heightCm,
                      weightKg:         _data.weightKg,
                      selectedActivity: _data.activityLevel,
                      goals:            _data.goals,
                      weeklyPaceFactor: _data.weeklyPaceFactor,
                      targetWeightKg:   _data.targetWeightKg,
                      onGenderChanged:  (v) => setState(() => _data.gender = v),
                      onAgeChanged:     (v) => setState(() => _data.age = v),
                      onHeightChanged:  (v) => setState(() => _data.heightCm = v),
                      onWeightChanged:  (v) => setState(() {
                        _data.weightKg = v;
                      }),
                      onActivityChanged:(v) => setState(() => _data.activityLevel = v),
                      onNext:           _nextStep,
                    ),

                    // ── Adım 4: Beslenme Tercihi ───────────────────────────
                    OnboardingDietStep(
                      selectedPreferences: _data.dietPreferences,
                      onChanged:           (v) => setState(() => _data.dietPreferences = v),
                      onNext:              _nextStep,
                    ),

                    // ── Adım 5: Rutinler ───────────────────────────────────
                    OnboardingRoutineStep(
                      selectedIds: _data.selectedRoutineIds,
                      onChanged:   (v) => setState(() => _data.selectedRoutineIds = v),
                      onNext:      _finish,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
