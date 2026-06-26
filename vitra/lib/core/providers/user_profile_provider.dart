import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';
import '../services/firestore_service.dart';

class UserProfile {
  final int calorieGoal;
  final int waterGoalMl;
  final bool isOnboardingComplete;
  final String userName;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String? gender;
  final String? activityLevel;
  final List<String> goals;
  final double weeklyPaceFactor;

  const UserProfile({
    required this.calorieGoal,
    required this.waterGoalMl,
    required this.isOnboardingComplete,
    this.userName = '',
    this.age,
    this.heightCm,
    this.weightKg,
    this.gender,
    this.activityLevel,
    this.goals = const [],
    this.weeklyPaceFactor = 0.5,
  });

  double get waterGoalLiters => waterGoalMl / 1000;

  bool get hasPhysicalProfile =>
      age != null &&
      heightCm != null &&
      weightKg != null &&
      gender != null &&
      activityLevel != null;

  UserProfile copyWith({
    int? calorieGoal,
    int? waterGoalMl,
    bool? isOnboardingComplete,
    String? userName,
    int? age,
    double? heightCm,
    double? weightKg,
    String? gender,
    String? activityLevel,
    List<String>? goals,
    double? weeklyPaceFactor,
  }) {
    return UserProfile(
      calorieGoal:          calorieGoal ?? this.calorieGoal,
      waterGoalMl:          waterGoalMl ?? this.waterGoalMl,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      userName:             userName ?? this.userName,
      age:                  age ?? this.age,
      heightCm:             heightCm ?? this.heightCm,
      weightKg:             weightKg ?? this.weightKg,
      gender:               gender ?? this.gender,
      activityLevel:        activityLevel ?? this.activityLevel,
      goals:                goals ?? this.goals,
      weeklyPaceFactor:     weeklyPaceFactor ?? this.weeklyPaceFactor,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier()
      : super(const UserProfile(
          calorieGoal: 0,
          waterGoalMl: 0,
          isOnboardingComplete: false,
        )) {
    _load();
  }

  // ── BMR / TDEE Hesaplama ──────────────────────────────────────────────────

  static double _activityMultiplier(String level) => switch (level) {
        'sedentary' => 1.2,
        'light'     => 1.375,
        'moderate'  => 1.55,
        'very'      => 1.725,
        _           => 1.375,
      };

  /// Mifflin-St Jeor TDEE → hedefe göre kalori hedefi
  /// Öncelik: kilo ver > kas yap > daha iyi beslen > maintenance
  static int calcCalorieGoal({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String activityLevel,
    required List<String> goals,
    double weeklyPaceFactor = 0.5,
  }) {
    final base    = 10 * weightKg + 6.25 * heightCm - 5 * age;
    final bmr     = gender == 'male' ? base + 5 : base - 161;
    final tdee    = bmr * _activityMultiplier(activityLevel);
    final deficit = (weeklyPaceFactor * 7700 / 7).round();
    if (goals.contains('lose_weight')) return (tdee - deficit).clamp(1200, 9999).round();
    if (goals.contains('gain_muscle')) return (tdee + 300).round();
    if (goals.contains('eat_better'))  return (tdee - 200).clamp(1200, 9999).round();
    return tdee.round();
  }

  /// Ağırlık × 33 ml + aktivite bonusu + "daha fazla su" hedefi bonusu
  static int calcWaterGoal({
    required double weightKg,
    required String activityLevel,
    List<String> goals = const [],
  }) {
    final base          = (weightKg * 33).round();
    final activityBonus = activityLevel == 'very' ? 500 : activityLevel == 'moderate' ? 300 : 0;
    final drinkBonus    = goals.contains('drink_more') ? 500 : 0;
    return (base + activityBonus + drinkBonus).clamp(1500, 5000);
  }

  // ── Yükleme ───────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final storage = LocalStorageService.instance;

    // Önce local'den yükle
    state = UserProfile(
      calorieGoal:          storage.calorieGoal,
      waterGoalMl:          storage.waterGoalMl,
      isOnboardingComplete: storage.isOnboardingComplete,
      userName:             storage.userName,
      age:                  storage.profileAge,
      heightCm:             storage.profileHeightCm,
      weightKg:             storage.profileWeightKg,
      gender:               storage.profileGender,
      activityLevel:        storage.profileActivity,
      goals:                storage.profileGoals,
      weeklyPaceFactor:     storage.weeklyPaceFactor,
    );

    // Firestore'dan güncel veri varsa üzerine yaz
    final remote = await FirestoreService.instance.fetchProfile();
    if (remote == null) return;

    final remoteCalorie  = (remote['calorieGoal'] as int?)    ?? state.calorieGoal;
    final remoteWater    = (remote['waterGoalMl'] as int?)    ?? state.waterGoalMl;
    final remoteName     = (remote['userName']   as String?)  ?? state.userName;
    final remoteAge      = (remote['age']         as int?)    ?? state.age;
    final remoteGender   = (remote['gender']      as String?) ?? state.gender;
    final remoteActivity = (remote['activityLevel'] as String?) ?? state.activityLevel;
    final remoteGoals    = (remote['goals'] as List<dynamic>?)
        ?.map((e) => e.toString()).toList() ?? state.goals;

    // Firestore'dan gelen height/weight int veya double olabilir
    final remoteHeight = switch (remote['heightCm']) {
      double d => d,
      int i    => i.toDouble(),
      _        => state.heightCm,
    };
    final remoteWeight = switch (remote['weightKg']) {
      double d => d,
      int i    => i.toDouble(),
      _        => state.weightKg,
    };

    if (remoteCalorie != state.calorieGoal) await storage.updateCalorieGoal(remoteCalorie);
    if (remoteWater   != state.waterGoalMl)  await storage.updateWaterGoalMl(remoteWater);
    if (remoteName.isNotEmpty && remoteName != state.userName) {
      await storage.updateUserName(remoteName);
    }
    if (remoteAge != null && remoteHeight != null && remoteWeight != null &&
        remoteGender != null && remoteActivity != null) {
      await storage.savePhysicalProfile(
        age: remoteAge,
        heightCm: remoteHeight,
        weightKg: remoteWeight,
        gender: remoteGender,
        activityLevel: remoteActivity,
        goals: remoteGoals,
      );
    }

    state = state.copyWith(
      calorieGoal:  remoteCalorie,
      waterGoalMl:  remoteWater,
      userName:     remoteName.isNotEmpty ? remoteName : state.userName,
      age:          remoteAge,
      heightCm:     remoteHeight,
      weightKg:     remoteWeight,
      gender:       remoteGender,
      activityLevel: remoteActivity,
      goals:        remoteGoals.isNotEmpty ? remoteGoals : state.goals,
    );
  }

  // ── Metodlar ──────────────────────────────────────────────────────────────

  Future<void> completeOnboarding({
    required int calorieGoal,
    required int waterGoalMl,
    String? userName,
    List<String> disabledRoutineIds = const [],
    int? age,
    double? heightCm,
    double? weightKg,
    String? gender,
    String? activityLevel,
    List<String> goals = const [],
    double? targetWeightKg,
    double weeklyPaceFactor = 0.5,
    List<String> dietPreferences = const [],
  }) async {
    await LocalStorageService.instance.saveOnboardingResult(
      calorieGoal: calorieGoal,
      waterGoalMl: waterGoalMl,
      userName: userName,
    );
    if (disabledRoutineIds.isNotEmpty) {
      await LocalStorageService.instance.saveDisabledDefaultRoutines(disabledRoutineIds);
    }
    if (age != null && heightCm != null && weightKg != null &&
        gender != null && activityLevel != null) {
      await LocalStorageService.instance.savePhysicalProfile(
        age: age,
        heightCm: heightCm,
        weightKg: weightKg,
        gender: gender,
        activityLevel: activityLevel,
        goals: goals,
        targetWeightKg: targetWeightKg,
        weeklyPaceFactor: weeklyPaceFactor,
        dietPreferences: dietPreferences,
      );
    }
    state = state.copyWith(
      calorieGoal:          calorieGoal,
      waterGoalMl:          waterGoalMl,
      isOnboardingComplete: true,
      userName:             userName ?? state.userName,
      age:                  age,
      heightCm:             heightCm,
      weightKg:             weightKg,
      gender:               gender,
      activityLevel:        activityLevel,
      goals:                goals,
      weeklyPaceFactor:     weeklyPaceFactor,
    );
    FirestoreService.instance.saveProfile(
      calorieGoal: calorieGoal,
      waterGoalMl: waterGoalMl,
      userName: userName,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      gender: gender,
      activityLevel: activityLevel,
      goals: goals,
    );
  }

  /// Sadece aktivite seviyesini değiştirir → kalori + su hedeflerini yeniden hesaplar.
  Future<void> updateActivityLevel(String level) async {
    final s = state;
    // Profil eksikse sadece kaydet, hesaplama yapma
    final wkg = s.weightKg;
    final hcm = s.heightCm;
    final age = s.age;
    final gen = s.gender;
    if (wkg == null || hcm == null || age == null || gen == null) {
      await LocalStorageService.instance.saveActivityLevel(level);
      state = s.copyWith(activityLevel: level);
      return;
    }

    final newCalorie = calcCalorieGoal(
      weightKg:         wkg,
      heightCm:         hcm,
      age:              age,
      gender:           gen,
      activityLevel:    level,
      goals:            s.goals,
      weeklyPaceFactor: s.weeklyPaceFactor,
    );
    final newWater = calcWaterGoal(
      weightKg:      wkg,
      activityLevel: level,
      goals:         s.goals,
    );

    await LocalStorageService.instance.saveActivityLevel(level);
    await LocalStorageService.instance.updateCalorieGoal(newCalorie);
    await LocalStorageService.instance.updateWaterGoalMl(newWater);

    state = s.copyWith(
      activityLevel: level,
      calorieGoal:   newCalorie,
      waterGoalMl:   newWater,
    );

    FirestoreService.instance.updatePhysicalProfile(
      age:           age,
      heightCm:      hcm,
      weightKg:      wkg,
      gender:        gen,
      activityLevel: level,
      goals:         s.goals,
      calorieGoal:   newCalorie,
      waterGoalMl:   newWater,
    );
  }

  Future<void> updateCalorieGoal(int kcal) async {
    await LocalStorageService.instance.updateCalorieGoal(kcal);
    FirestoreService.instance.updateCalorieGoal(kcal);
    state = state.copyWith(calorieGoal: kcal);
  }

  Future<void> updateWaterGoal(int ml) async {
    await LocalStorageService.instance.updateWaterGoalMl(ml);
    FirestoreService.instance.updateWaterGoal(ml);
    state = state.copyWith(waterGoalMl: ml);
  }

  Future<void> updateWeightKg(double? kg) async {
    final s = state;
    await LocalStorageService.instance.savePhysicalProfile(
      age:           s.age ?? 25,
      heightCm:      s.heightCm ?? 170,
      weightKg:      kg ?? 70,
      gender:        s.gender ?? 'male',
      activityLevel: s.activityLevel ?? 'moderate',
      goals:         s.goals,
    );
    FirestoreService.instance.saveProfile(
      calorieGoal:   s.calorieGoal,
      waterGoalMl:   s.waterGoalMl,
      weightKg:      kg,
    );
    state = state.copyWith(weightKg: kg);
  }

  Future<void> updateUserName(String name) async {
    await LocalStorageService.instance.updateUserName(name);
    FirestoreService.instance.saveProfile(
      calorieGoal: state.calorieGoal,
      waterGoalMl: state.waterGoalMl,
      userName: name,
    );
    state = state.copyWith(userName: name);
  }

  /// Fiziksel profili günceller ve BMR/TDEE'ye göre kalori + su hedeflerini yeniden hesaplar.
  Future<void> updatePhysicalProfile({
    required int age,
    required double heightCm,
    required double weightKg,
    required String gender,
    required String activityLevel,
    required List<String> goals,
    double? weeklyPaceFactor,
  }) async {
    final pace       = weeklyPaceFactor ?? state.weeklyPaceFactor;
    final newCalorie = calcCalorieGoal(
      weightKg:         weightKg,
      heightCm:         heightCm,
      age:              age,
      gender:           gender,
      activityLevel:    activityLevel,
      goals:            goals,
      weeklyPaceFactor: pace,
    );
    final newWater = calcWaterGoal(
      weightKg: weightKg,
      activityLevel: activityLevel,
      goals: goals,
    );

    await LocalStorageService.instance.savePhysicalProfile(
      age:              age,
      heightCm:         heightCm,
      weightKg:         weightKg,
      gender:           gender,
      activityLevel:    activityLevel,
      goals:            goals,
      weeklyPaceFactor: pace,
    );
    await LocalStorageService.instance.updateCalorieGoal(newCalorie);
    await LocalStorageService.instance.updateWaterGoalMl(newWater);

    state = state.copyWith(
      age:              age,
      heightCm:         heightCm,
      weightKg:         weightKg,
      gender:           gender,
      activityLevel:    activityLevel,
      goals:            goals,
      calorieGoal:      newCalorie,
      waterGoalMl:      newWater,
      weeklyPaceFactor: pace,
    );

    FirestoreService.instance.updatePhysicalProfile(
      age:          age,
      heightCm:     heightCm,
      weightKg:     weightKg,
      gender:       gender,
      activityLevel:activityLevel,
      goals:        goals,
      calorieGoal:  newCalorie,
      waterGoalMl:  newWater,
    );
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>(
  (ref) => UserProfileNotifier(),
);
