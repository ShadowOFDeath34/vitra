import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_entry.dart';
import '../models/water_entry.dart';

/// Tüm SharedPreferences işlemleri buradan geçer.
class LocalStorageService {
  LocalStorageService._();
  static LocalStorageService? _instance;
  static LocalStorageService get instance {
    _instance ??= LocalStorageService._();
    return _instance!;
  }

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── User Profile ──────────────────────────────────────────────────────────

  static const _kOnboardingDone   = 'onboarding_complete';
  static const _kCalorieGoal     = 'calorie_goal';
  static const _kWaterGoalMl     = 'water_goal_ml';
  static const _kUserName        = 'user_name';
  static const _kProfileAge      = 'profile_age';
  static const _kProfileHeight   = 'profile_height_cm';
  static const _kProfileWeight   = 'profile_weight_kg';
  static const _kProfileGender   = 'profile_gender';
  static const _kProfileActivity    = 'profile_activity';
  static const _kProfileGoals       = 'profile_goals';
  static const _kTargetWeightKg     = 'target_weight_kg';
  static const _kWeeklyPaceFactor   = 'weekly_pace_factor';
  static const _kDietPreferences    = 'diet_preferences';
  // Misafir hesabının kimliğini korumak için backup key'leri.
  // Bu key'lere clearUserData() veya resetOnboardingAndGoals() DOKUNMAZ.
  // Sadece kullanıcı "Misafir Hesabını Sil" dediğinde temizlenir.
  static const _kGuestCalorieBackup          = 'guest_calorie_backup';
  static const _kGuestWaterBackup            = 'guest_water_backup';
  static const _kGuestStreakBackup           = 'guest_streak_backup';
  static const _kGuestCustomRoutinesBackup   = 'guest_custom_routines_backup';
  static const _kGuestDisabledRoutinesBackup = 'guest_disabled_routines_backup';

  bool   get isOnboardingComplete => _prefs.getBool(_kOnboardingDone) ?? false;
  int    get calorieGoal          => _prefs.getInt(_kCalorieGoal) ?? 0;
  int    get waterGoalMl          => _prefs.getInt(_kWaterGoalMl) ?? 0;
  String get userName             => _prefs.getString(_kUserName) ?? '';

  int?    get profileAge      => _prefs.containsKey(_kProfileAge) ? _prefs.getInt(_kProfileAge) : null;
  double? get profileHeightCm => _prefs.containsKey(_kProfileHeight) ? _prefs.getDouble(_kProfileHeight) : null;
  double? get profileWeightKg => _prefs.containsKey(_kProfileWeight) ? _prefs.getDouble(_kProfileWeight) : null;
  String? get profileGender   => _prefs.getString(_kProfileGender);
  String? get profileActivity => _prefs.getString(_kProfileActivity);
  List<String> get profileGoals      => _prefs.getStringList(_kProfileGoals) ?? [];
  double?      get targetWeightKg    => _prefs.containsKey(_kTargetWeightKg) ? _prefs.getDouble(_kTargetWeightKg) : null;
  double       get weeklyPaceFactor  => _prefs.getDouble(_kWeeklyPaceFactor) ?? 0.5;
  List<String> get dietPreferences   => _prefs.getStringList(_kDietPreferences) ?? [];

  Future<void> updateUserName(String name) async =>
      _prefs.setString(_kUserName, name);

  Future<void> savePhysicalProfile({
    required int age,
    required double heightCm,
    required double weightKg,
    required String gender,
    required String activityLevel,
    required List<String> goals,
    double? targetWeightKg,
    double weeklyPaceFactor = 0.5,
    List<String> dietPreferences = const [],
  }) async {
    await _prefs.setInt(_kProfileAge, age);
    await _prefs.setDouble(_kProfileHeight, heightCm);
    await _prefs.setDouble(_kProfileWeight, weightKg);
    await _prefs.setString(_kProfileGender, gender);
    await _prefs.setString(_kProfileActivity, activityLevel);
    await _prefs.setStringList(_kProfileGoals, goals);
    if (targetWeightKg != null) await _prefs.setDouble(_kTargetWeightKg, targetWeightKg);
    await _prefs.setDouble(_kWeeklyPaceFactor, weeklyPaceFactor);
    if (dietPreferences.isNotEmpty) await _prefs.setStringList(_kDietPreferences, dietPreferences);
  }
  Future<void> saveTargetWeight(double kg) async {
    await _prefs.setDouble(_kTargetWeightKg, kg);
  }

  Future<void> saveActivityLevel(String level) async {
    await _prefs.setString(_kProfileActivity, level);
  }

  Future<void> saveDietPreferences(List<String> prefs) async {
    await _prefs.setStringList(_kDietPreferences, prefs);
  }

  int? get guestCalorieBackup   => _prefs.getInt(_kGuestCalorieBackup);
  int? get guestWaterBackup     => _prefs.getInt(_kGuestWaterBackup);

  bool get hasGuestBackup =>
      (_prefs.getInt(_kGuestCalorieBackup) ?? 0) > 0 &&
      (_prefs.getInt(_kGuestWaterBackup) ?? 0) > 0;

  Future<void> saveOnboardingResult({
    required int calorieGoal,
    required int waterGoalMl,
    String? userName,
  }) async {
    await _prefs.setInt(_kCalorieGoal, calorieGoal);
    await _prefs.setInt(_kWaterGoalMl, waterGoalMl);
    if (userName != null && userName.isNotEmpty) {
      await _prefs.setString(_kUserName, userName);
    }
    await _prefs.setBool(_kOnboardingDone, true);
  }

  /// Misafir hesabından gerçek hesaba geçişte çağrılır.
  /// Goals + streak + routines snapshot alır.
  Future<void> saveGuestDataBackup() async {
    if (calorieGoal <= 0 || waterGoalMl <= 0) return;
    await _prefs.setInt(_kGuestCalorieBackup, calorieGoal);
    await _prefs.setInt(_kGuestWaterBackup, waterGoalMl);
    await _prefs.setInt(_kGuestStreakBackup, streakDays);
    if (userName.isNotEmpty) await _prefs.setString(_kUserName + '_guest', userName);
    final routinesJson = _prefs.getString(_kCustomRoutines);
    if (routinesJson != null) {
      await _prefs.setString(_kGuestCustomRoutinesBackup, routinesJson);
    }
    final disabled = _prefs.getStringList(_kDisabledDefaultRoutines);
    if (disabled != null) {
      await _prefs.setStringList(_kGuestDisabledRoutinesBackup, disabled);
    }
  }

  Future<void> restoreGuestDataBackup() async {
    final cal  = _prefs.getInt(_kGuestCalorieBackup) ?? 0;
    final wtr  = _prefs.getInt(_kGuestWaterBackup) ?? 0;
    if (cal <= 0 || wtr <= 0) return;
    final guestName = _prefs.getString(_kUserName + '_guest') ?? '';
    await saveOnboardingResult(calorieGoal: cal, waterGoalMl: wtr, userName: guestName.isNotEmpty ? guestName : null);
    final streak = _prefs.getInt(_kGuestStreakBackup) ?? 0;
    if (streak > 0) await _prefs.setInt(_kStreakDays, streak);
    final routinesJson = _prefs.getString(_kGuestCustomRoutinesBackup);
    if (routinesJson != null) await _prefs.setString(_kCustomRoutines, routinesJson);
    final disabled = _prefs.getStringList(_kGuestDisabledRoutinesBackup);
    if (disabled != null) await _prefs.setStringList(_kDisabledDefaultRoutines, disabled);
    // Restore tamamlandı — backup'ı temizle (sonraki misafir sıfırdan başlasın)
    await clearGuestDataBackup();
  }

  Future<void> clearGuestDataBackup() async {
    await _prefs.remove(_kGuestCalorieBackup);
    await _prefs.remove(_kGuestWaterBackup);
    await _prefs.remove(_kGuestStreakBackup);
    await _prefs.remove(_kGuestCustomRoutinesBackup);
    await _prefs.remove(_kGuestDisabledRoutinesBackup);
  }

  // Geriye dönük uyumluluk — tam backup metoduna yönlendir
  Future<void> saveGuestGoalsBackup() => saveGuestDataBackup();
  Future<void> clearGuestGoalsBackup() => clearGuestDataBackup();

  Future<void> updateCalorieGoal(int kcal) async =>
      _prefs.setInt(_kCalorieGoal, kcal);

  Future<void> updateWaterGoalMl(int ml) async =>
      _prefs.setInt(_kWaterGoalMl, ml);

  // ── Daily Log ─────────────────────────────────────────────────────────────

  static const _kLogDate         = 'log_date';
  static const _kWaterLog        = 'water_log_json';
  static const _kRoutinesDone    = 'routines_done';
  static const _kStreakDays      = 'streak_days';
  static const _kMeals           = 'meals_json';
  static const _kCustomRoutines        = 'custom_routines_json';
  static const _kDisabledDefaultRoutines = 'disabled_default_routines';
  static const _kRoutineTimes           = 'routine_notif_times';
  static const _kWaterNotifEnabled     = 'water_notif_enabled';
  static const _kWaterNotifInterval    = 'water_notif_interval_h';
  static const _kRoutineNotifEnabled   = 'routine_notif_enabled';
  static const _kRoutineNotifHour      = 'routine_notif_hour';
  static const _kRoutineNotifMinute    = 'routine_notif_minute';
  static const _kWakeHour              = 'wake_hour';
  static const _kWakeMinute            = 'wake_minute';
  static const _kSleepHour             = 'sleep_hour';
  static const _kSleepMinute           = 'sleep_minute';

  String get _todayKey {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  Future<void> resetDailyLogIfNeeded() async {
    final saved = _prefs.getString(_kLogDate);
    final today = _todayKey;
    if (saved == today) return;

    final yesterday = () {
      final y = DateTime.now().subtract(const Duration(days: 1));
      return '${y.year}-${y.month.toString().padLeft(2,'0')}-${y.day.toString().padLeft(2,'0')}';
    }();

    if (saved == yesterday) {
      await _prefs.setInt(_kStreakDays, (_prefs.getInt(_kStreakDays) ?? 0) + 1);
    } else {
      await _prefs.setInt(_kStreakDays, 1);
    }

    await _prefs.setString(_kLogDate, today);
    await _prefs.setString(_kWaterLog, '[]');
    await _prefs.setStringList(_kRoutinesDone, []);
    await _prefs.setString(_kMeals, '[]');
  }

  int          get streakDays   => _prefs.getInt(_kStreakDays) ?? 0;
  List<String> get routinesDone => _prefs.getStringList(_kRoutinesDone) ?? [];

  List<WaterEntry> get waterLog {
    final raw = _prefs.getString(_kWaterLog);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => WaterEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveWaterLog(List<WaterEntry> entries) async =>
      _prefs.setString(
        _kWaterLog,
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );

  List<MealEntry> get meals {
    final raw = _prefs.getString(_kMeals);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }


  Future<void> toggleRoutine(String id) async {
    final done = List<String>.from(routinesDone);
    done.contains(id) ? done.remove(id) : done.add(id);
    await _prefs.setStringList(_kRoutinesDone, done);
  }

  Future<void> saveMeals(List<MealEntry> meals) async =>
      _prefs.setString(_kMeals, jsonEncode(meals.map((m) => m.toJson()).toList()));

  // ── Custom Routines ───────────────────────────────────────────────────────

  /// [{id, label}] listesi olarak saklar
  List<Map<String, String>> get customRoutines {
    final raw = _prefs.getString(_kCustomRoutines);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomRoutines(List<Map<String, String>> routines) async =>
      _prefs.setString(_kCustomRoutines, jsonEncode(routines));

  // ── Disabled Default Routines (onboarding'de deselect edilenler) ──────────

  /// Kullanıcının onboarding'de kapatmak istediği default rutin ID'leri
  List<String> get disabledDefaultRoutines =>
      _prefs.getStringList(_kDisabledDefaultRoutines) ?? [];

  Future<void> saveDisabledDefaultRoutines(List<String> ids) async =>
      _prefs.setStringList(_kDisabledDefaultRoutines, ids);

  // ── Notification Settings ─────────────────────────────────────────────────

  bool get waterNotifEnabled   => _prefs.getBool(_kWaterNotifEnabled) ?? true;
  int  get waterNotifInterval  => _prefs.getInt(_kWaterNotifInterval) ?? 2;
  bool get routineNotifEnabled => _prefs.getBool(_kRoutineNotifEnabled) ?? true;
  int  get routineNotifHour    => _prefs.getInt(_kRoutineNotifHour) ?? 20;
  int  get routineNotifMinute  => _prefs.getInt(_kRoutineNotifMinute) ?? 0;
  int  get wakeHour            => _prefs.getInt(_kWakeHour) ?? 7;
  int  get wakeMinute          => _prefs.getInt(_kWakeMinute) ?? 0;
  int  get sleepHour           => _prefs.getInt(_kSleepHour) ?? 23;
  int  get sleepMinute         => _prefs.getInt(_kSleepMinute) ?? 0;

  Future<void> saveWaterNotifSettings({required bool enabled}) async {
    await _prefs.setBool(_kWaterNotifEnabled, enabled);
  }

  // ── Rutin Bildirim Saatleri ───────────────────────────────────────────────

  /// {routineId: {hour: int, minute: int}} haritası
  Map<String, Map<String, int>> get routineNotifTimes {
    final raw = _prefs.getString(_kRoutineTimes);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) =>
          MapEntry(k, Map<String, int>.from((v as Map).cast<String, int>())));
    } catch (_) {
      return {};
    }
  }

  Future<void> setRoutineNotifTime(
      String routineId, int hour, int minute) async {
    final times = Map<String, Map<String, int>>.from(routineNotifTimes);
    times[routineId] = {'hour': hour, 'minute': minute};
    await _prefs.setString(_kRoutineTimes, jsonEncode(times));
  }

  Future<void> removeRoutineNotifTime(String routineId) async {
    final times = Map<String, Map<String, int>>.from(routineNotifTimes);
    times.remove(routineId);
    await _prefs.setString(_kRoutineTimes, jsonEncode(times));
  }

  Future<void> saveWakeSleepTime({
    required int wakeHour,
    required int wakeMinute,
    required int sleepHour,
    required int sleepMinute,
  }) async {
    await _prefs.setInt(_kWakeHour, wakeHour);
    await _prefs.setInt(_kWakeMinute, wakeMinute);
    await _prefs.setInt(_kSleepHour, sleepHour);
    await _prefs.setInt(_kSleepMinute, sleepMinute);
  }

  Future<void> saveRoutineNotifSettings({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    await _prefs.setBool(_kRoutineNotifEnabled, enabled);
    await _prefs.setInt(_kRoutineNotifHour, hour);
    await _prefs.setInt(_kRoutineNotifMinute, minute);
  }

  // ── Koç Sohbet Geçmişi ────────────────────────────────────────────────────

  static const _kCoachHistory   = 'coach_chat_history';
  static const _kMaxHistory     = 80; // saklanacak max mesaj
  static const _kCoachChatCount        = 'coach_chat_count';
  static const _kCoachChatDate         = 'coach_chat_date';
  static const _kPremiumFlashCount     = 'premium_flash_count';
  static const _kPremiumFlashDate      = 'premium_flash_date';

  // Günde bu kadar mesaj Flash ile gider, sonrası Lite'a düşer
  static const premiumDailyFlashLimit = 30;

  int get premiumChatFlashTodayCount {
    final savedDate = _prefs.getString(_kPremiumFlashDate);
    if (savedDate != _todayKey) return 0;
    return _prefs.getInt(_kPremiumFlashCount) ?? 0;
  }

  Future<void> incrementPremiumChatFlashCount() async {
    final today = _todayKey;
    final savedDate = _prefs.getString(_kPremiumFlashDate);
    final count = savedDate == today ? (_prefs.getInt(_kPremiumFlashCount) ?? 0) : 0;
    await _prefs.setInt(_kPremiumFlashCount, count + 1);
    await _prefs.setString(_kPremiumFlashDate, today);
  }

  /// [{role:'user'|'assistant', text:'...', ts: millis}]
  List<Map<String, dynamic>> get coachChatHistory {
    final raw = _prefs.getString(_kCoachHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCoachChatHistory(List<Map<String, dynamic>> messages) async {
    final trimmed = messages.length > _kMaxHistory
        ? messages.sublist(messages.length - _kMaxHistory)
        : messages;
    await _prefs.setString(_kCoachHistory, jsonEncode(trimmed));
  }

  Future<void> clearCoachChatHistory() async =>
      _prefs.remove(_kCoachHistory);

  /// Bugünkü koç sohbet sayısı (gün değiştiyse 0 döner)
  int get coachChatTodayCount {
    final savedDate = _prefs.getString(_kCoachChatDate);
    if (savedDate != _todayKey) return 0;
    return _prefs.getInt(_kCoachChatCount) ?? 0;
  }

  Future<void> incrementCoachChatCount() async {
    final today = _todayKey;
    final savedDate = _prefs.getString(_kCoachChatDate);
    final count = savedDate == today ? (_prefs.getInt(_kCoachChatCount) ?? 0) : 0;
    await _prefs.setInt(_kCoachChatCount, count + 1);
    await _prefs.setString(_kCoachChatDate, today);
  }

  // ── Brifing Cache ──────────────────────────────────────────────────────────

  static const _kBriefingDate = 'briefing_cache_date';
  static const _kBriefingText = 'briefing_cache_text';

  /// Bugünkü tarihle eşleşiyorsa cache'den döner, yoksa null.
  String? get cachedBriefing {
    final date = _prefs.getString(_kBriefingDate);
    if (date != _todayKey) return null;
    return _prefs.getString(_kBriefingText);
  }

  Future<void> saveBriefingCache(String text) async {
    await _prefs.setString(_kBriefingDate, _todayKey);
    await _prefs.setString(_kBriefingText, text);
  }

  Future<void> clearBriefingCache() async {
    await _prefs.remove(_kBriefingDate);
    await _prefs.remove(_kBriefingText);
  }

  // ── İlk Kullanım Tarihi ───────────────────────────────────────────────────────
  // Kullanıcı uygulamayı ilk açtığında kaydedilir — haftalık rapor başlangıcı için.

  static const _kFirstUseDate = 'first_use_date';

  /// İlk kullanım tarihini kaydeder. Zaten kayıtlıysa dokunmaz.
  Future<void> ensureFirstUseDateSaved() async {
    if (_prefs.getString(_kFirstUseDate) != null) return;
    await _prefs.setString(_kFirstUseDate, _todayKey);
  }

  /// Kullanıcının uygulamayı ilk kullandığı tarih.
  DateTime? get firstUseDate {
    final raw = _prefs.getString(_kFirstUseDate);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // ── Haftalık Rapor Cache ───────────────────────────────────────────────────
  // Her hafta ilk kullanım gününün yıldönümünde yeniden üretilir.

  static const _kWeeklyReportWeek = 'weekly_report_week';
  static const _kWeeklyReportText = 'weekly_report_text';

  /// Bu haftanın key'i: ilk kullanım gününden kaç hafta geçti.
  String? _currentWeekKey() {
    final start = firstUseDate;
    if (start == null) return null;
    final days = DateTime.now().difference(start).inDays;
    if (days < 7) return null; // Henüz 1 hafta olmadı
    final weekNum = days ~/ 7;
    return 'week_$weekNum';
  }

  /// Bu haftaya ait cache'i döner. Null = henüz yok veya 1 haftadan az geçti.
  String? get cachedWeeklyReport {
    final key = _currentWeekKey();
    if (key == null) return null;
    final savedKey = _prefs.getString(_kWeeklyReportWeek);
    if (savedKey != key) return null;
    return _prefs.getString(_kWeeklyReportText);
  }

  Future<void> saveWeeklyReportCache(String text) async {
    final key = _currentWeekKey();
    if (key == null) return;
    await _prefs.setString(_kWeeklyReportWeek, key);
    await _prefs.setString(_kWeeklyReportText, text);
  }

  Future<void> clearWeeklyReportCache() async {
    await _prefs.remove(_kWeeklyReportWeek);
    await _prefs.remove(_kWeeklyReportText);
  }

  // ── Son Giriş Yöntemi ─────────────────────────────────────────────────────────
  // 'google' | 'email' | 'anonymous' — session kaybında doğru yönlendirme için

  static const _kLastLoginMethod = 'last_login_method';

  String? get lastLoginMethod => _prefs.getString(_kLastLoginMethod);

  Future<void> saveLastLoginMethod(String method) async =>
      _prefs.setString(_kLastLoginMethod, method);

  // ── Email Link Auth ───────────────────────────────────────────────────────────

  static const _kPendingSignInEmail = 'pending_sign_in_email';

  String? get pendingSignInEmail => _prefs.getString(_kPendingSignInEmail);

  Future<void> savePendingSignInEmail(String email) async =>
      _prefs.setString(_kPendingSignInEmail, email);

  Future<void> clearPendingSignInEmail() async =>
      _prefs.remove(_kPendingSignInEmail);

  // ── Kullanıcı Değişiminde Temizlik ───────────────────────────────────────────

  /// Farklı kullanıcı giriş yaptığında çağrılır.
  /// Günlük aktivite + AI sohbet + brifing + rutin tercihleri temizlenir.
  /// Onboarding, hedefler ve bildirim ayarları korunur.
  Future<void> clearUserData() async {
    await _prefs.remove(_kLogDate);
    await _prefs.setString(_kWaterLog, '[]');
    await _prefs.setStringList(_kRoutinesDone, []);
    await _prefs.setString(_kMeals, '[]');
    await _prefs.setInt(_kStreakDays, 0);
    await _prefs.remove(_kCoachHistory);
    await _prefs.remove(_kBriefingDate);
    await _prefs.remove(_kBriefingText);
    await _prefs.remove(_kCustomRoutines);
    await _prefs.remove(_kDisabledDefaultRoutines);
    await _prefs.remove('ai_usage_count');
    await _prefs.remove('ai_usage_date');
  }

  /// Onboarding ve hedefleri sıfırlar — sadece farklı kullanıcıya geçişte çağrılır.
  Future<void> resetOnboardingAndGoals() async {
    await _prefs.remove(_kOnboardingDone);
    await _prefs.remove(_kCalorieGoal);
    await _prefs.remove(_kWaterGoalMl);
    await _prefs.remove(_kUserName);
    await _prefs.remove(_kProfileAge);
    await _prefs.remove(_kProfileHeight);
    await _prefs.remove(_kProfileWeight);
    await _prefs.remove(_kProfileGender);
    await _prefs.remove(_kProfileActivity);
    await _prefs.remove(_kProfileGoals);
  }
}
