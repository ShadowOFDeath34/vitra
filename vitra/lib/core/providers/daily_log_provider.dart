import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_entry.dart';
import '../models/water_entry.dart';
import '../services/local_storage_service.dart';
import '../services/firestore_service.dart';

// ── Varsayılan günlük rutinler ────────────────────────────────────────────────

class RoutineEntry {
  final String id;
  final String label;
  final bool done;
  final bool isCustom;

  const RoutineEntry({
    required this.id,
    required this.label,
    required this.done,
    this.isCustom = false,
  });

  RoutineEntry copyWith({bool? done}) =>
      RoutineEntry(id: id, label: label, done: done ?? this.done, isCustom: isCustom);
}

const kDefaultRoutines = [
  RoutineEntry(id: 'vitamin',     label: 'Vitamin iç',           done: false),
  RoutineEntry(id: 'cold_shower', label: 'Soğuk duş',            done: false),
  RoutineEntry(id: 'meditation',  label: 'Sabah meditasyonu',    done: false),
  RoutineEntry(id: 'morning_ex',  label: 'Sabah egzersizi',      done: false),
  RoutineEntry(id: 'daily_plan',  label: 'Günlük plan yap',      done: false),
  RoutineEntry(id: 'water_goal',  label: 'Su hedefine ulaş',     done: false),
  RoutineEntry(id: 'walk',        label: '10.000 adım',           done: false),
  RoutineEntry(id: 'lunch_walk',  label: 'Öğle yürüyüşü',        done: false),
  RoutineEntry(id: 'fruit_veg',   label: 'Meyve/sebze ye',        done: false),
  RoutineEntry(id: 'read',        label: 'Kitap oku',             done: false),
  RoutineEntry(id: 'reflection',  label: 'Günlük reflection',     done: false),
  RoutineEntry(id: 'sleep_time',  label: 'Uyku saatini koru',     done: false),
  RoutineEntry(id: 'no_screen',   label: 'Dijital detoks',        done: false),
  RoutineEntry(id: 'breathing',   label: 'Nefes egzersizi',       done: false),
  RoutineEntry(id: 'stretch',     label: 'Stretching yap',        done: false),
];

// ── State ─────────────────────────────────────────────────────────────────────

class DailyLog {
  final List<MealEntry> meals;
  final List<WaterEntry> waterLog;
  final List<RoutineEntry> routines;
  final int streakDays;

  const DailyLog({
    required this.meals,
    required this.waterLog,
    required this.routines,
    required this.streakDays,
  });

  int get caloriesConsumed => meals.fold(0, (sum, m) => sum + m.calories);
  int get waterConsumedMl  => waterLog.fold(0, (sum, e) => sum + e.ml);
  int get routinesDoneCount => routines.where((r) => r.done).length;

  DailyLog copyWith({
    List<MealEntry>? meals,
    List<WaterEntry>? waterLog,
    List<RoutineEntry>? routines,
    int? streakDays,
  }) {
    return DailyLog(
      meals: meals ?? this.meals,
      waterLog: waterLog ?? this.waterLog,
      routines: routines ?? this.routines,
      streakDays: streakDays ?? this.streakDays,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class DailyLogNotifier extends StateNotifier<DailyLog> {
  DailyLogNotifier()
      : super(const DailyLog(
          meals: [],
          waterLog: [],
          routines: kDefaultRoutines,
          streakDays: 0,
        )) {
    _load();
  }

  Future<void> _load() async {
    final storage = LocalStorageService.instance;
    await storage.resetDailyLogIfNeeded();

    // Streak değişmiş olabilir — Firestore'a sync et
    FirestoreService.instance.saveStreak(storage.streakDays);

    // Custom rutinleri local'den yükle
    final localCustom = storage.customRoutines.map((m) => RoutineEntry(
          id: m['id']!,
          label: m['label']!,
          done: false,
          isCustom: true,
        )).toList();

    // Onboarding'de deselect edilen default rutinleri filtrele
    final disabled = storage.disabledDefaultRoutines;
    final activeDefaults = kDefaultRoutines
        .where((r) => !disabled.contains(r.id))
        .toList();

    // Önce local'den yükle — anlık gösterim için
    final localDoneIds = storage.routinesDone;
    final allLocal = [
      ...activeDefaults.map((r) => r.copyWith(done: localDoneIds.contains(r.id))),
      ...localCustom.map((r) => r.copyWith(done: localDoneIds.contains(r.id))),
    ];
    state = DailyLog(
      meals:      storage.meals,
      waterLog:   storage.waterLog,
      routines:   allLocal,
      streakDays: storage.streakDays,
    );

    // Firestore'dan çek — kullanıcı varsa local'i güncelle
    final results = await Future.wait([
      FirestoreService.instance.fetchTodayLog(),
      FirestoreService.instance.fetchCustomRoutines(),
    ]);

    final remote       = results[0] as Map<String, dynamic>?;
    final remoteCustom = results[1] as List<Map<String, String>>;

    // Custom rutinleri Firestore'la merge et (Firestore öncelikli)
    if (remoteCustom.isNotEmpty) {
      await storage.saveCustomRoutines(remoteCustom);
    }

    final mergedCustom = remoteCustom.isNotEmpty ? remoteCustom : storage.customRoutines;
    final customEntries = mergedCustom.map((m) => RoutineEntry(
          id: m['id']!,
          label: m['label']!,
          done: false,
          isCustom: true,
        )).toList();

    if (remote == null) {
      final doneIds = storage.routinesDone;
      state = state.copyWith(
        routines: [
          ...activeDefaults.map((r) => r.copyWith(done: doneIds.contains(r.id))),
          ...customEntries.map((r) => r.copyWith(done: doneIds.contains(r.id))),
        ],
      );
      return;
    }

    final remoteMeals = (remote['meals'] as List<dynamic>? ?? [])
        .map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    final remoteWater = (remote['waterLog'] as List<dynamic>? ?? [])
        .map((e) => WaterEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    final remoteDoneIds = List<String>.from(remote['routinesDone'] ?? []);
    final remoteRoutines = [
      ...activeDefaults.map((r) => r.copyWith(done: remoteDoneIds.contains(r.id))),
      ...customEntries.map((r) => r.copyWith(done: remoteDoneIds.contains(r.id))),
    ];

    // Local cache'i de güncelle
    await storage.saveMeals(remoteMeals);
    await storage.saveWaterLog(remoteWater);
    await Future.forEach(remoteDoneIds, (id) async {
      if (!storage.routinesDone.contains(id)) {
        await storage.toggleRoutine(id);
      }
    });

    state = DailyLog(
      meals:      remoteMeals,
      waterLog:   remoteWater,
      routines:   remoteRoutines,
      streakDays: storage.streakDays,
    );
  }

  Future<void> addMeal(MealEntry meal) async {
    final updated = [...state.meals, meal];
    await LocalStorageService.instance.saveMeals(updated);
    FirestoreService.instance.saveMeals(updated);
    state = state.copyWith(meals: updated);
  }

  Future<void> removeMeal(String id) async {
    final updated = state.meals.where((m) => m.id != id).toList();
    await LocalStorageService.instance.saveMeals(updated);
    FirestoreService.instance.saveMeals(updated);
    state = state.copyWith(meals: updated);
  }

  Future<String> addWater(int ml) async {
    final entry = WaterEntry(
      id:   DateTime.now().millisecondsSinceEpoch.toString(),
      ml:   ml,
      time: DateTime.now(),
    );
    final updated = [...state.waterLog, entry];
    await LocalStorageService.instance.saveWaterLog(updated);
    FirestoreService.instance.saveWaterLog(updated);
    state = state.copyWith(waterLog: updated);
    return entry.id;
  }

  Future<void> removeWaterEntry(String id) async {
    final updated = state.waterLog.where((e) => e.id != id).toList();
    await LocalStorageService.instance.saveWaterLog(updated);
    FirestoreService.instance.saveWaterLog(updated);
    state = state.copyWith(waterLog: updated);
  }

  Future<void> toggleRoutine(String routineId) async {
    await LocalStorageService.instance.toggleRoutine(routineId);
    final updated = state.routines.map((r) {
      if (r.id == routineId) return r.copyWith(done: !r.done);
      return r;
    }).toList();
    state = state.copyWith(routines: updated);
    FirestoreService.instance.saveRoutinesDone(
      updated.where((r) => r.done).map((r) => r.id).toList(),
    );
  }

  Future<void> addCustomRoutine(String label) async {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final entry = RoutineEntry(id: id, label: label, done: false, isCustom: true);
    final updated = [...state.routines, entry];
    state = state.copyWith(routines: updated);

    final customList = updated
        .where((r) => r.isCustom)
        .map((r) => {'id': r.id, 'label': r.label})
        .toList();
    await LocalStorageService.instance.saveCustomRoutines(customList);
    FirestoreService.instance.saveCustomRoutines(customList);
  }

  void reorderRoutines(int oldIndex, int newIndex) {
    final list = [...state.routines];
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(routines: list);
    // Sadece custom sırasını kaydet; default sıra zaten sabit
    final customList = list
        .where((r) => r.isCustom)
        .map((r) => {'id': r.id, 'label': r.label})
        .toList();
    LocalStorageService.instance.saveCustomRoutines(customList);
  }

  Future<void> removeRoutine(String routineId) async {
    final isDefault = kDefaultRoutines.any((r) => r.id == routineId);
    final updated = state.routines.where((r) => r.id != routineId).toList();
    state = state.copyWith(routines: updated);

    final storage = LocalStorageService.instance;
    if (storage.routinesDone.contains(routineId)) {
      await storage.toggleRoutine(routineId);
    }

    if (isDefault) {
      final disabled = [...storage.disabledDefaultRoutines, routineId];
      await storage.saveDisabledDefaultRoutines(disabled);
    }

    final customList = updated
        .where((r) => r.isCustom)
        .map((r) => {'id': r.id, 'label': r.label})
        .toList();
    await storage.saveCustomRoutines(customList);
    FirestoreService.instance.saveCustomRoutines(customList);
    FirestoreService.instance.saveRoutinesDone(
      updated.where((r) => r.done).map((r) => r.id).toList(),
    );
  }

  /// Daha önce silinmiş varsayılan bir rutini geri ekler.
  Future<void> enableDefaultRoutine(String routineId) async {
    final entry = kDefaultRoutines.firstWhere((r) => r.id == routineId);
    final storage = LocalStorageService.instance;
    final disabled = storage.disabledDefaultRoutines.where((id) => id != routineId).toList();
    await storage.saveDisabledDefaultRoutines(disabled);
    state = state.copyWith(routines: [...state.routines, entry]);
  }

  /// Hâlâ devre dışı olan varsayılan rutin ID'lerini döner.
  List<String> get disabledDefaultRoutineIds =>
      LocalStorageService.instance.disabledDefaultRoutines;

  /// Hâlâ devre dışı olan tüm varsayılan rutinleri döner.
  List<RoutineEntry> get disabledDefaultRoutines =>
      kDefaultRoutines.where((r) => disabledDefaultRoutineIds.contains(r.id)).toList();
}

final dailyLogProvider =
    StateNotifierProvider<DailyLogNotifier, DailyLog>(
  (ref) => DailyLogNotifier(),
);
