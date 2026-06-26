import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_service.dart';

/// İki koleksiyon:
///   food_cache   — FoodAnalysisResult (OFF + AI metin analizi), TTL 30 gün
///   health_cache — FoodHealthRating,                             TTL 30 gün
/// Her iki koleksiyon da kullanıcıdan bağımsız, tüm kullanıcılara ortak.
class FoodCacheService {
  static final FoodCacheService instance = FoodCacheService._();
  FoodCacheService._();

  final _db = FirebaseFirestore.instance;

  static const _ttlDays = 30;

  CollectionReference<Map<String, dynamic>> get _foodCol =>
      _db.collection('food_cache');

  CollectionReference<Map<String, dynamic>> get _healthCol =>
      _db.collection('health_cache');

  // ── Yardımcı ─────────────────────────────────────────────────────────────

  String _docId(String source, String query) {
    final normalized = query
        .toLowerCase()
        .trim()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return '${source}_$normalized';
  }

  bool _fresh(Timestamp ts) =>
      DateTime.now().difference(ts.toDate()).inDays <= _ttlDays;

  // ── FoodAnalysisResult cache ──────────────────────────────────────────────

  Future<FoodAnalysisResult?> get(String source, String query) async {
    try {
      final doc = await _foodCol.doc(_docId(source, query)).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      if (!_fresh(data['cachedAt'] as Timestamp)) return null;
      _foodCol.doc(_docId(source, query))
          .update({'hitCount': FieldValue.increment(1)});
      return _resultFromMap(data['result'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> put(
      String source, String query, FoodAnalysisResult result) async {
    try {
      await _foodCol.doc(_docId(source, query)).set({
        'source':   source,
        'query':    query.toLowerCase().trim(),
        'result':   _resultToMap(result),
        'cachedAt': FieldValue.serverTimestamp(),
        'hitCount': 0,
      });
    } catch (_) {}
  }

  // ── FoodHealthRating cache ────────────────────────────────────────────────

  Future<FoodHealthRating?> getHealth(String foodName) async {
    try {
      final doc = await _healthCol.doc(_docId('health', foodName)).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      if (!_fresh(data['cachedAt'] as Timestamp)) return null;
      _healthCol.doc(_docId('health', foodName))
          .update({'hitCount': FieldValue.increment(1)});
      return _healthFromMap(data['rating'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> putHealth(String foodName, FoodHealthRating rating) async {
    try {
      await _healthCol.doc(_docId('health', foodName)).set({
        'foodName': foodName.toLowerCase().trim(),
        'rating':   _healthToMap(rating),
        'cachedAt': FieldValue.serverTimestamp(),
        'hitCount': 0,
      });
    } catch (_) {}
  }

  // ── Translation cache ─────────────────────────────────────────────────────

  Future<String?> getTranslation(String originalName) async {
    try {
      final doc = await _db.collection('translation_cache')
          .doc(_docId('tr', originalName)).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      if (!_fresh(data['cachedAt'] as Timestamp)) return null;
      _db.collection('translation_cache')
          .doc(_docId('tr', originalName))
          .update({'hitCount': FieldValue.increment(1)});
      return data['translated'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> putTranslation(String originalName, String translated) async {
    try {
      await _db.collection('translation_cache')
          .doc(_docId('tr', originalName)).set({
        'original':    originalName,
        'translated':  translated,
        'cachedAt':    FieldValue.serverTimestamp(),
        'hitCount':    0,
      });
    } catch (_) {}
  }

  // ── Serileştirme ──────────────────────────────────────────────────────────

  Map<String, dynamic> _resultToMap(FoodAnalysisResult r) => {
    'foodName':  r.foodName,
    'calories':  r.calories,
    'proteinG':  r.proteinG,
    'carbsG':    r.carbsG,
    'fatG':      r.fatG,
    'fiberG':    r.fiberG,
    'sodiumMg':  r.sodiumMg,
    'sugarG':    r.sugarG,
    'confidence': r.confidence,
    'note':      r.note,
  };

  FoodAnalysisResult _resultFromMap(Map<String, dynamic> m) => FoodAnalysisResult(
    foodName:   m['foodName'] as String? ?? '',
    calories:   (m['calories'] as num?)?.toInt() ?? 0,
    proteinG:   (m['proteinG'] as num?)?.toInt() ?? 0,
    carbsG:     (m['carbsG']   as num?)?.toInt() ?? 0,
    fatG:       (m['fatG']     as num?)?.toInt() ?? 0,
    fiberG:     (m['fiberG']   as num?)?.toInt() ?? 0,
    sodiumMg:   (m['sodiumMg'] as num?)?.toInt() ?? 0,
    sugarG:     (m['sugarG']   as num?)?.toInt() ?? 0,
    confidence: m['confidence'] as String? ?? 'high',
    note:       m['note']      as String? ?? '',
  );

  Map<String, dynamic> _healthToMap(FoodHealthRating r) => {
    'level': r.level,
    'title': r.title,
    'note':  r.note,
  };

  FoodHealthRating _healthFromMap(Map<String, dynamic> m) => FoodHealthRating(
    level: m['level'] as String? ?? 'moderate',
    title: m['title'] as String? ?? '',
    note:  m['note']  as String? ?? '',
  );
}
