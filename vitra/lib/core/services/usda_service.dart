import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_service.dart';
import 'food_cache_service.dart';

/// USDA FoodData Central — ABD Tarım Bakanlığı ücretsiz yemek DB'si.
/// 900,000+ yemek kaydı, doğru makro veriler.
/// API key: api.data.gov üzerinden ücretsiz — https://fdc.nal.usda.gov
class UsdaService {
  static final UsdaService instance = UsdaService._();
  UsdaService._();

  static const _base = 'https://api.nal.usda.gov/fdc/v1';

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'User-Agent': 'Vitra-App/1.0'},
  ));

  String get _key => dotenv.env['USDA_API_KEY'] ?? 'DEMO_KEY';

  /// Yemek arar. Önce cache, sonra Survey (FNDDS) ve Foundation verilerini tercih eder.
  Future<List<FoodAnalysisResult>> search(
    String query, {
    int maxResults = 5,
  }) async {
    if (query.trim().isEmpty) return [];

    // Cache'e bak — hit varsa API çağrısı yapma
    final cached = await FoodCacheService.instance.get('usda', query);
    if (cached != null) return [cached];

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_base/foods/search',
        queryParameters: {'api_key': _key},
        data: {
          'query':    query,
          'dataType': ['Survey (FNDDS)', 'Foundation', 'SR Legacy'],
          'pageSize': maxResults,
          'sortBy':   'score',
          'sortOrder': 'desc',
        },
      );

      final data = response.data;
      if (data == null) return [];
      final foods = data['foods'] as List<dynamic>? ?? [];
      final results = foods
          .map((f) => _parseFdcFood(Map<String, dynamic>.from(f as Map)))
          .whereType<FoodAnalysisResult>()
          .toList();

      // En iyi sonucu cache'e yaz (fire-and-forget)
      if (results.isNotEmpty) {
        FoodCacheService.instance.put('usda', query, results.first);
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  FoodAnalysisResult? _parseFdcFood(Map<String, dynamic> food) {
    final name = (food['description'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;

    final nutrients = food['foodNutrients'] as List<dynamic>? ?? [];

    // USDA nutrient ID'leri:
    // 1008 = Energy (kcal), 1003 = Protein, 1005 = Carbs, 1004 = Fat
    // 1079 = Fiber, 1093 = Sodium, 2000 = Sugars
    int cal     = _nutrient(nutrients, 1008);
    int protein = _nutrient(nutrients, 1003);
    int carbs   = _nutrient(nutrients, 1005);
    int fat     = _nutrient(nutrients, 1004);
    int fiber   = _nutrient(nutrients, 1079);
    int sodium  = _nutrient(nutrients, 1093);
    int sugar   = _nutrient(nutrients, 2000);

    // Foundation veri setinde 1008 (kcal) search response'unda gelmeyebilir.
    // Makrolardan Atwater formülüyle hesapla: protein*4 + carbs*4 + fat*9
    if (cal <= 0) {
      if (protein > 0 || carbs > 0 || fat > 0) {
        cal = protein * 4 + carbs * 4 + fat * 9;
      } else {
        return null; // hiç makro yok, işe yaramaz
      }
    }

    // Güzel isim — baş harfleri büyüt (USDA tümü büyük harfle yazar)
    final prettyName = name.split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');

    return FoodAnalysisResult(
      foodName:   prettyName,
      calories:   cal,
      proteinG:   protein,
      carbsG:     carbs,
      fatG:       fat,
      fiberG:     fiber,
      sodiumMg:   sodium,
      sugarG:     sugar,
      confidence: 'high',
      note:       '100g — USDA FoodData Central',
    );
  }

  int _nutrient(List<dynamic> nutrients, int nutrientId) {
    for (final n in nutrients) {
      final map = n as Map<String, dynamic>;
      if ((map['nutrientId'] as int?) == nutrientId) {
        final v = map['value'];
        if (v is num) return v.round();
      }
    }
    return 0;
  }
}
