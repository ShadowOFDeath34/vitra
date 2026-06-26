import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/exercise_entry.dart';
import '../models/meal_entry.dart';
import '../models/water_entry.dart';
import '../models/weight_entry.dart';

/// Tüm Firestore okuma/yazma işlemleri buradan geçer.
/// Path: /users/{uid}/daily_logs/{date}/
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Kullanıcı giriş yapmamışsa Firestore'a dokunma
  bool get _hasUser => _uid != null;

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  DocumentReference<Map<String, dynamic>> _logDoc(String date) =>
      _db.collection('users').doc(_uid).collection('daily_logs').doc(date);

  DocumentReference<Map<String, dynamic>> _profileDoc() =>
      _db.collection('users').doc(_uid);

  // ── Profile ──────────────────────────────────────────────────────────────

  Future<void> saveProfile({
    required int calorieGoal,
    required int waterGoalMl,
    String? userName,
    int? age,
    double? heightCm,
    double? weightKg,
    String? gender,
    String? activityLevel,
    List<String> goals = const [],
  }) async {
    if (!_hasUser) return;
    await _profileDoc().set({
      'calorieGoal': calorieGoal,
      'waterGoalMl': waterGoalMl,
      if (userName != null && userName.isNotEmpty) 'userName': userName,
      if (age != null) 'age': age,
      if (heightCm != null) 'heightCm': heightCm,
      if (weightKg != null) 'weightKg': weightKg,
      if (gender != null) 'gender': gender,
      if (activityLevel != null) 'activityLevel': activityLevel,
      if (goals.isNotEmpty) 'goals': goals,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updatePhysicalProfile({
    required int age,
    required double heightCm,
    required double weightKg,
    required String gender,
    required String activityLevel,
    required List<String> goals,
    required int calorieGoal,
    required int waterGoalMl,
  }) async {
    if (!_hasUser) return;
    await _profileDoc().set({
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'gender': gender,
      'activityLevel': activityLevel,
      'goals': goals,
      'calorieGoal': calorieGoal,
      'waterGoalMl': waterGoalMl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateCalorieGoal(int kcal) async {
    if (!_hasUser) return;
    await _profileDoc().set({'calorieGoal': kcal}, SetOptions(merge: true));
  }

  Future<void> updateWaterGoal(int ml) async {
    if (!_hasUser) return;
    await _profileDoc().set({'waterGoalMl': ml}, SetOptions(merge: true));
  }

  // ── Daily Log ─────────────────────────────────────────────────────────────

  Future<void> saveMeals(List<MealEntry> meals) async {
    if (!_hasUser) return;
    await _logDoc(_todayKey()).set({
      'meals': meals.map((m) => m.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveWaterLog(List<WaterEntry> entries) async {
    if (!_hasUser) return;
    await _logDoc(_todayKey()).set({
      'waterLog': entries.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveRoutinesDone(List<String> doneIds) async {
    if (!_hasUser) return;
    await _logDoc(_todayKey()).set({
      'routinesDone': doneIds,
      'updatedAt'   : FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Returns map of dateKey → bool (true=done/had routines, false=no routines logged)
  /// for the past [days] days (not including today).
  Future<Map<String, bool>> fetchWeekRoutineLogs({int days = 7}) async {
    if (!_hasUser) return {};
    try {
      final today = DateTime.now();
      final result = <String, bool>{};
      for (var i = 1; i <= days; i++) {
        final d = today.subtract(Duration(days: i));
        final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        final snap = await _logDoc(key).get();
        final data = snap.data();
        final done = (data?['routinesDone'] as List<dynamic>?)?.isNotEmpty ?? false;
        result[key] = done;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveCustomRoutines(List<Map<String, String>> routines) async {
    if (!_hasUser) return;
    await _profileDoc().set({
      'customRoutines': routines,
      'updatedAt'     : FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, String>>> fetchCustomRoutines() async {
    if (!_hasUser) return [];
    try {
      final snap = await _profileDoc().get();
      final data = snap.data();
      if (data == null) return [];
      final raw = data['customRoutines'] as List<dynamic>? ?? [];
      return raw.map((e) => Map<String, String>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveStreak(int days) async {
    if (!_hasUser) return;
    await _profileDoc().set({'streakDays': days}, SetOptions(merge: true));
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Bugünün logunu Firestore'dan çeker. Kullanıcı yoksa null döner.
  Future<Map<String, dynamic>?> fetchTodayLog() async {
    if (!_hasUser) return null;
    try {
      final snap = await _logDoc(_todayKey()).get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  /// Kullanıcı profilini Firestore'dan çeker.
  Future<Map<String, dynamic>?> fetchProfile() async {
    if (!_hasUser) return null;
    try {
      final snap = await _profileDoc().get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  /// Kullanıcıya ait tüm Firestore verisini siler (hesap silme için).
  Future<void> deleteAllUserData() async {
    if (!_hasUser) return;
    try {
      // daily_logs subcollection'daki tüm dokümanları sil
      final logsSnap = await _db
          .collection('users')
          .doc(_uid)
          .collection('daily_logs')
          .get();
      final batch = _db.batch();
      for (final doc in logsSnap.docs) {
        batch.delete(doc.reference);
      }
      // Profil dokümanını da batch'e ekle
      batch.delete(_profileDoc());
      await batch.commit();
    } catch (_) {}
  }

  /// Son [days] günün loglarını {dateKey: data} map olarak çeker.
  Future<Map<String, Map<String, dynamic>>> fetchLastNDays(int days) async {
    if (!_hasUser) return {};
    final result = <String, Map<String, dynamic>>{};
    final today  = DateTime.now();

    final futures = List.generate(days, (i) {
      final d = today.subtract(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return _logDoc(key).get().then((snap) {
        if (snap.exists && snap.data() != null) {
          result[key] = snap.data()!;
        }
      }).catchError((_) {});
    });

    await Future.wait(futures);
    return result;
  }

  /// Son 7 günde yenilen, bugün henüz eklenmemiş benzersiz yemek adlarını döndürür.
  Future<List<Map<String, dynamic>>> fetchRecentMeals({int days = 7}) async {
    if (!_hasUser) return [];
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];

    for (int i = 1; i <= days; i++) {
      final d = today.subtract(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (key == todayKey) continue;
      try {
        final snap = await _logDoc(key).get();
        if (!snap.exists) continue;
        final meals = (snap.data()?['meals'] as List<dynamic>? ?? []);
        for (final m in meals) {
          final name = m['name'] as String? ?? '';
          if (name.isNotEmpty && seen.add(name.toLowerCase())) {
            result.add({
              'name':     name,
              'calories': (m['calories'] as int?) ?? 0,
              'proteinG': (m['proteinG'] as int?) ?? 0,
              'carbsG':   (m['carbsG']   as int?) ?? 0,
              'fatG':     (m['fatG']     as int?) ?? 0,
              'type':     (m['type']     as int?) ?? 0,
            });
          }
        }
      } catch (_) {}
      if (result.length >= 5) break;
    }
    return result.take(5).toList();
  }

  // ── Koç Sohbet Geçmişi ───────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _coachDoc() =>
      _db.collection('users').doc(_uid).collection('coach').doc('history');

  /// Koç sohbet geçmişini Firestore'a kaydeder (son 60 mesaj).
  Future<void> saveCoachHistory(List<Map<String, dynamic>> messages) async {
    if (!_hasUser || messages.isEmpty) return;
    final trimmed = messages.length > 60
        ? messages.sublist(messages.length - 60)
        : messages;
    try {
      await _coachDoc().set({
        'messages':  trimmed,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> clearCoachHistory() async {
    if (!_hasUser) return;
    try { await _coachDoc().delete(); } catch (_) {}
  }

  /// Firestore'dan koç sohbet geçmişini çeker.
  /// LocalStorage boşsa (yeni cihaz/yeniden kurulum) kullanılır.
  Future<List<Map<String, dynamic>>?> fetchCoachHistory() async {
    if (!_hasUser) return null;
    try {
      final doc = await _coachDoc().get();
      if (!doc.exists) return null;
      final msgs = doc.data()?['messages'] as List<dynamic>?;
      if (msgs == null || msgs.isEmpty) return null;
      return msgs
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ── Koç Konuşma Arşivi ───────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _convCol =>
      _db.collection('users').doc(_uid).collection('conversations');

  /// Mevcut sohbeti arşive kaydet. title = ilk user mesajı (truncated).
  Future<String?> archiveConversation(List<Map<String, dynamic>> messages) async {
    if (!_hasUser || messages.isEmpty) return null;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final firstUser = messages
        .firstWhere((m) => m['role'] == 'user', orElse: () => {'text': ''})['text']
        .toString();
    try {
      await _convCol.doc(id).set({
        'messages':  messages,
        'title':     firstUser.length > 60 ? '${firstUser.substring(0, 60)}…' : firstUser,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return id;
    } catch (_) { return null; }
  }

  /// Son 20 arşivlenmiş konuşmayı listeler (tarih sırasıyla, en yeni önce).
  Future<List<Map<String, dynamic>>> fetchConversationList() async {
    if (!_hasUser) return [];
    try {
      final snap = await _convCol
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        return {
          'id':        d.id,
          'title':     data['title'] ?? '',
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (_) { return []; }
  }

  /// Arşivlenmiş konuşmayı yükler.
  Future<List<Map<String, dynamic>>?> loadConversation(String id) async {
    if (!_hasUser) return null;
    try {
      final doc = await _convCol.doc(id).get();
      if (!doc.exists) return null;
      final msgs = doc.data()?['messages'] as List<dynamic>?;
      return msgs?.map((m) => Map<String, dynamic>.from(m as Map)).toList();
    } catch (_) { return null; }
  }

  /// Arşivlenmiş konuşmayı siler.
  Future<void> deleteConversation(String id) async {
    if (!_hasUser) return;
    try { await _convCol.doc(id).delete(); } catch (_) {}
  }

  // ── Kilo Logu ─────────────────────────────────────────────────────────────

  static const _kOnboardingCurrentId = 'onboarding_current';
  static const _kOnboardingTargetId  = 'onboarding_target';

  CollectionReference<Map<String, dynamic>> get _weightLogCol =>
      _db.collection('users').doc(_uid).collection('weight_log');

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Onboarding tamamlandığında başlangıç ve hedef kiloyu korumalı kayıt olarak saklar.
  Future<void> saveOnboardingWeightEntries({
    required double currentWeight,
    double? targetWeight,
  }) async {
    if (!_hasUser) return;
    final now = DateTime.now();
    try {
      await _weightLogCol.doc(_kOnboardingCurrentId).set({
        'weight': currentWeight,
        'date': Timestamp.fromDate(now),
        'protected': true,
        'label': 'Başlangıç',
      });
      if (targetWeight != null && targetWeight > 0) {
        await _weightLogCol.doc(_kOnboardingTargetId).set({
          'weight': targetWeight,
          'date': Timestamp.fromDate(now.add(const Duration(milliseconds: 1))),
          'protected': true,
          'label': 'Hedef',
        });
      }
    } catch (_) {}
  }

  /// Ayarlardan hedef kilo değişince tablosundaki hedef kaydını günceller.
  Future<void> updateTargetWeightEntry(double kg) async {
    if (!_hasUser) return;
    try {
      await _weightLogCol.doc(_kOnboardingTargetId).update({'weight': kg});
    } catch (_) {}
  }

  /// Her kayıt için benzersiz timestamp key kullanır — aynı günde birden çok kayıt mümkün.
  Future<void> saveWeightEntry(double weightKg) async {
    if (!_hasUser) return;
    final now = DateTime.now();
    final key = '${_dateKey(now)}_${now.millisecondsSinceEpoch}';
    try {
      await _weightLogCol.doc(key).set(
        WeightEntry(dateKey: key, weight: weightKg, date: now).toJson(),
      );
    } catch (_) {}
  }

  /// Son [limit] günlük kilo girişlerini tarih sırasıyla çeker.
  /// Kayıt yoksa Firestore profil datasından retroaktif olarak seed eder.
  Future<List<WeightEntry>> fetchWeightLog({int limit = 60}) async {
    if (!_hasUser) return [];
    try {
      final snap = await _weightLogCol
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      var entries = snap.docs
          .map((d) => WeightEntry.fromDoc(d.id, d.data()))
          .toList()
          .reversed
          .toList();
      if (entries.isEmpty) {
        entries = await _seedWeightLogFromProfile(limit);
      }
      return entries;
    } catch (_) {
      return [];
    }
  }

  /// weight_log boşsa Firestore profil datasındaki weightKg'dan onboarding_current oluşturur.
  Future<List<WeightEntry>> _seedWeightLogFromProfile(int limit) async {
    try {
      final profileSnap = await _profileDoc().get();
      final data = profileSnap.data();
      if (data == null) return [];
      final weight = (data['weightKg'] as num?)?.toDouble();
      if (weight == null || weight <= 0) return [];
      await saveOnboardingWeightEntries(currentWeight: weight);
      final snap2 = await _weightLogCol
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      return snap2.docs
          .map((d) => WeightEntry.fromDoc(d.id, d.data()))
          .toList()
          .reversed
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Korumalı olmayan bir kilo girişini siler.
  Future<void> deleteWeightEntry(String dateKey) async {
    if (!_hasUser) return;
    if (dateKey == _kOnboardingCurrentId || dateKey == _kOnboardingTargetId) return;
    try {
      await _weightLogCol.doc(dateKey).delete();
    } catch (_) {}
  }

  // ── Egzersiz Logu ─────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _exerciseLogCol =>
      _db.collection('users').doc(_uid).collection('exercise_log');

  /// Bugünkü log dokümanına egzersiz kaydeder (liste append).
  Future<void> saveExercise(ExerciseEntry entry) async {
    if (!_hasUser) return;
    final key = _dateKey(entry.time);
    try {
      await _exerciseLogCol.doc(key).set({
        'exercises': FieldValue.arrayUnion([entry.toJson()]),
        'date': Timestamp.fromDate(entry.time),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Belirli bir günün egzersizlerini çeker.
  Future<List<ExerciseEntry>> fetchExercises(DateTime day) async {
    if (!_hasUser) return [];
    final key = _dateKey(day);
    try {
      final snap = await _exerciseLogCol.doc(key).get();
      if (!snap.exists) return [];
      final raw = snap.data()?['exercises'] as List<dynamic>? ?? [];
      return raw.map((e) => ExerciseEntry.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  /// Egzersiz siler (ID'ye göre filtreler).
  Future<void> deleteExercise(ExerciseEntry entry) async {
    if (!_hasUser) return;
    final key = _dateKey(entry.time);
    try {
      final entries = await fetchExercises(entry.time);
      final updated = entries.where((e) => e.id != entry.id).map((e) => e.toJson()).toList();
      await _exerciseLogCol.doc(key).set({
        'exercises': updated,
        'date': Timestamp.fromDate(entry.time),
      });
    } catch (_) {}
  }
}
