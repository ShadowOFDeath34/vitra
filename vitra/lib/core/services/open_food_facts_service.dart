import 'package:dio/dio.dart';
import 'ai_service.dart';
import 'food_cache_service.dart';

/// Open Food Facts API'sinden barkod ve metin araması yapar.
/// Ücretsiz, kayıt gerektirmez — https://world.openfoodfacts.org
class OpenFoodFactsService {
  static final OpenFoodFactsService instance = OpenFoodFactsService._();
  OpenFoodFactsService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'User-Agent': 'Vitra-App/1.0 (contact@vitra.app)'},
  ));

  // ── Barkod araması ─────────────────────────────────────────────────────────

  /// Barkodu arar, bulamazsa null döner.
  /// Önce Firestore cache'e bakar — aynı barkod daha önce tarındıysa OFF'a gitmez.
  Future<FoodAnalysisResult?> lookup(String barcode) async {
    final cached = await FoodCacheService.instance.get('barcode', barcode);
    if (cached != null) return cached;

    final result = await _fetchBarcode(
        'https://tr.openfoodfacts.org/api/v0/product/$barcode.json')
      ?? await _fetchBarcode(
          'https://world.openfoodfacts.org/api/v0/product/$barcode.json');

    if (result != null) {
      FoodCacheService.instance.put('barcode', barcode, result);
    }
    return result;
  }

  Future<FoodAnalysisResult?> _fetchBarcode(String url) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(url);
      final data = response.data;
      if (data == null || data['status'] != 1) return null;
      final product = data['product'] as Map<String, dynamic>? ?? {};
      return _parseProduct(product);
    } catch (_) {
      return null;
    }
  }

  // ── Metin araması ──────────────────────────────────────────────────────────

  /// Metin ile yemek arar. Önce cache, sonra Türkiye veritabanı, bulamazsa global.
  Future<List<FoodAnalysisResult>> textSearch(
    String query, {
    int maxResults = 5,
  }) async {
    if (query.trim().isEmpty) return [];

    // Cache'e bak — hit varsa API çağrısı yapma
    final cached = await FoodCacheService.instance.get('openfoodfacts', query);
    if (cached != null) return [cached];

    final trResults = await _textSearchFrom(query, cc: 'tr', max: maxResults);
    if (trResults.length >= maxResults) return trResults;

    // TR sonucu az geldiyse global ile tamamla
    final globalResults = await _textSearchFrom(query, cc: null,
        max: maxResults - trResults.length);

    // Tekrarları ayıkla (isim bazlı)
    final seen = <String>{};
    final merged = <FoodAnalysisResult>[];
    for (final r in [...trResults, ...globalResults]) {
      final key = r.foodName.toLowerCase().trim();
      if (seen.add(key)) merged.add(r);
      if (merged.length >= maxResults) break;
    }

    // En iyi sonucu cache'e yaz (fire-and-forget)
    if (merged.isNotEmpty) {
      FoodCacheService.instance.put('openfoodfacts', query, merged.first);
    }

    return merged;
  }

  Future<List<FoodAnalysisResult>> _textSearchFrom(
    String query, {
    required String? cc,
    required int max,
  }) async {
    if (max <= 0) return [];
    try {
      final params = <String, String>{
        'search_terms': query,
        'action':       'process',
        'json':         '1',
        'page_size':    '$max',
        'fields':
            'product_name,product_name_tr,product_name_en,nutriments,quantity',
      };
      if (cc != null) params['cc'] = cc;

      final response = await _dio.get<Map<String, dynamic>>(
        'https://world.openfoodfacts.org/cgi/search.pl',
        queryParameters: params,
      );
      final data = response.data;
      if (data == null) return [];
      final products = data['products'] as List<dynamic>? ?? [];
      return products
          .map((p) => _parseProduct(Map<String, dynamic>.from(p as Map)))
          .whereType<FoodAnalysisResult>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Ortak ürün parse ───────────────────────────────────────────────────────

  FoodAnalysisResult? _parseProduct(Map<String, dynamic> product) {
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    final name = _str(product['product_name_tr']) ??
        _str(product['product_name']) ??
        _str(product['product_name_en']);
    if (name == null) return null;

    // Kalori: kcal tercihli
    int cal = 0;
    final calRaw = nutriments['energy-kcal_100g'] ??
        nutriments['energy-kcal'];
    if (calRaw is num) {
      cal = calRaw.round();
    } else {
      final kj = nutriments['energy_100g'] ?? nutriments['energy'];
      if (kj is num) cal = (kj / 4.184).round();
    }
    final protein = _num(nutriments['proteins_100g'])?.round() ?? 0;
    final carbs   = _num(nutriments['carbohydrates_100g'])?.round() ?? 0;
    final fat     = _num(nutriments['fat_100g'])?.round() ?? 0;
    final fiber   = _num(nutriments['fiber_100g'])?.round() ?? 0;
    final sodiumRaw = _num(nutriments['sodium_100g']);
    final sodium = sodiumRaw != null ? (sodiumRaw * 1000).round() : 0;
    final sugar   = _num(nutriments['sugars_100g'])?.round() ?? 0;

    // Kalori alanı boş ama makrolar varsa Atwater formülüyle hesapla
    if (cal <= 0) {
      final atwater = protein * 4 + carbs * 4 + fat * 9;
      if (atwater > 0) cal = atwater;
      else return null;
    }

    // Fiziksel olarak imkansız kalori değeri — veri hatası
    if (cal > 950) return null;

    // Verinin tamlığına göre güven seviyesi belirle
    final macroCount = (protein > 0 ? 1 : 0) + (carbs > 0 ? 1 : 0) + (fat > 0 ? 1 : 0);
    final confidence = macroCount >= 2 ? 'high' : macroCount == 1 ? 'medium' : 'low';

    final qty = _str(product['quantity']) ?? '100g';

    return FoodAnalysisResult(
      foodName:   name,
      calories:   cal,
      proteinG:   protein,
      carbsG:     carbs,
      fatG:       fat,
      fiberG:     fiber,
      sodiumMg:   sodium,
      sugarG:     sugar,
      confidence: confidence,
      note:       '100g — Open Food Facts ($qty)',
    );
  }

  String? _str(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  num? _num(dynamic v) => v is num ? v : null;
}

