import 'ai_service.dart';
import '../data/turkish_foods_db.dart';

/// Yemek araması için tek giriş noktası.
/// Cascade: Yerel DB → AI (null döner, caller karar verir)
///
/// Maliyet sırası:
///   0₺  — Yerel DB (offline, anlık, 5.000 yemek)
///   $   — AI (Gemini Flash, sadece bulamazsa)
class UnifiedFoodSearchService {
  static final UnifiedFoodSearchService instance =
      UnifiedFoodSearchService._();
  UnifiedFoodSearchService._();

  // ── Tek sonuç: en iyi eşleşme ─────────────────────────────────────────────

  /// Yerel DB'de bulunamazsa null döner — caller AI'a geçer.
  Future<FoodAnalysisResult?> findBest(String query) async {
    if (query.trim().isEmpty) return null;

    final local = TurkishFoodsDB.search(query);
    if (local.isNotEmpty) return localResult(local.first);

    return null;
  }

  // ── Çoklu sonuç: arama önerileri için ────────────────────────────────────

  /// Arama önerileri — sadece yerel DB, anlık.
  Future<List<SearchSuggestion>> suggest(String query) async {
    if (query.trim().length < 2) return [];

    final local = TurkishFoodsDB.search(query);
    return local
        .take(8)
        .map((item) => SearchSuggestion(
              result: localResult(item),
              source: SuggestionSource.local,
            ))
        .toList();
  }

  // ── Yardımcı ──────────────────────────────────────────────────────────────

  FoodAnalysisResult localResult(TurkishFoodItem item) => FoodAnalysisResult(
        foodName:   item.name,
        calories:   item.calories,
        proteinG:   item.proteinG,
        carbsG:     item.carbsG,
        fatG:       item.fatG,
        fiberG:     item.fiberG,
        sodiumMg:   item.sodiumMg,
        sugarG:     item.sugarG,
        confidence: 'high',
        note:       item.serving,
      );
}

enum SuggestionSource { local }

class SearchSuggestion {
  final FoodAnalysisResult result;
  final SuggestionSource source;

  const SearchSuggestion({required this.result, required this.source});

  String get sourceLabel => '';
}
