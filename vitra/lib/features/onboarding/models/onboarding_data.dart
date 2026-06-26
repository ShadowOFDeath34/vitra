class OnboardingData {
  String? name;
  List<String> goals;
  String? activityLevel;
  double? heightCm;
  double? weightKg;
  int? age;
  String? gender; // 'male' | 'female'
  bool notificationsEnabled;
  List<String> selectedRoutineIds;
  double? targetWeightKg;
  double weeklyPaceFactor; // 0.25 | 0.5 | 0.75 kg/hafta
  List<String> dietPreferences;

  OnboardingData({
    this.name,
    this.goals = const [],
    this.activityLevel,
    this.heightCm,
    this.weightKg,
    this.age,
    this.gender,
    this.notificationsEnabled = false,
    List<String>? selectedRoutineIds,
    this.targetWeightKg,
    this.weeklyPaceFactor = 0.5,
    this.dietPreferences = const [],
  }) : selectedRoutineIds = selectedRoutineIds ?? ['vitamin', 'meditation', 'walk'];

  bool get needsTargetWeight =>
      goals.contains('lose_weight') || goals.contains('gain_muscle');

  // Mifflin-St Jeor BMR hesabı
  double? get bmr {
    if (weightKg == null || heightCm == null || age == null || gender == null) return null;
    final base = 10 * weightKg! + 6.25 * heightCm! - 5 * age!;
    return gender == 'male' ? base + 5 : base - 161;
  }

  // Aktivite çarpanı
  double get activityMultiplier => switch (activityLevel) {
        'sedentary' => 1.2,
        'light' => 1.375,
        'moderate' => 1.55,
        'very' => 1.725,
        _ => 1.375,
      };

  // TDEE (Toplam Günlük Enerji Harcaması)
  double? get tdee => bmr != null ? (bmr! * activityMultiplier) : null;

  // Hedefe göre kalori hedefi
  double? get dailyCalorieGoal {
    if (tdee == null) return null;
    // weeklyPaceFactor → haftalık 1 kg = ~7700 kcal → günlük açık = pace * 7700 / 7
    final deficit = (weeklyPaceFactor * 7700 / 7).round(); // 0.25→275 / 0.5→550 / 0.75→825
    if (goals.contains('lose_weight')) return (tdee! - deficit).clamp(1200, 9999);
    if (goals.contains('gain_muscle')) return tdee! + 300;
    if (goals.contains('eat_better'))  return (tdee! - 200).clamp(1200, 9999);
    return tdee;
  }

  // Su hedefi (ml) — ağırlık × 33ml, aktiviteye ve hedefe göre artı
  int? get dailyWaterGoalMl {
    if (weightKg == null) return null;
    final base         = (weightKg! * 33).round();
    final activityBonus = activityLevel == 'very' ? 500 : activityLevel == 'moderate' ? 300 : 0;
    final drinkBonus   = goals.contains('drink_more') ? 500 : 0;
    return base + activityBonus + drinkBonus;
  }
}
