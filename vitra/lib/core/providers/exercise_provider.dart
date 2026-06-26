import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise_entry.dart';
import '../services/firestore_service.dart';

class ExerciseLog {
  final List<ExerciseEntry> entries;
  final bool loading;

  const ExerciseLog({required this.entries, this.loading = false});

  int get totalBurned => entries.fold(0, (s, e) => s + e.caloriesBurned);
  int get totalMinutes => entries.fold(0, (s, e) => s + e.durationMin);

  ExerciseLog copyWith({List<ExerciseEntry>? entries, bool? loading}) =>
      ExerciseLog(
        entries: entries ?? this.entries,
        loading: loading ?? this.loading,
      );
}

class ExerciseNotifier extends StateNotifier<ExerciseLog> {
  ExerciseNotifier() : super(const ExerciseLog(entries: [], loading: true)) {
    loadToday();
  }

  Future<void> loadToday() async {
    state = state.copyWith(loading: true);
    try {
      final entries = await FirestoreService.instance.fetchExercises(DateTime.now());
      state = ExerciseLog(entries: entries, loading: false);
    } catch (_) {
      state = ExerciseLog(entries: state.entries, loading: false);
    }
  }

  Future<void> add(ExerciseEntry entry) async {
    await FirestoreService.instance.saveExercise(entry);
    await loadToday();
  }

  Future<void> remove(ExerciseEntry entry) async {
    await FirestoreService.instance.deleteExercise(entry);
    await loadToday();
  }
}

final exerciseProvider =
    StateNotifierProvider<ExerciseNotifier, ExerciseLog>(
  (ref) => ExerciseNotifier(),
);
