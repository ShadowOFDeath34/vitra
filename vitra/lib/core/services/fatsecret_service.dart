import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_service.dart';
import 'food_cache_service.dart';

/// FatSecret Platform API — Premier Free tier.
/// Barkod (UPC/EAN-13) ile küresel markalı ürün arama.
/// Attribution zorunlu: "Powered by FatSecret" note alanında gösterilir.
class FatSecretService {
  static final FatSecretService instance = FatSecretService._();
  FatSecretService._();

  static const _tokenUrl = 'https://oauth.fatsecret.com/connect/token';
  static const _apiBase  = 'https://platform.fatsecret.com/rest/server.api';

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  String? _accessToken;
  DateTime? _tokenExpiry;

  String get _clientId     => dotenv.env['FATSECRET_CLIENT_ID']     ?? '';
  String get _clientSecret => dotenv.env['FATSECRET_CLIENT_SECRET'] ?? '';

  // ── OAuth 2.0 Token ───────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        _tokenUrl,
        data: 'grant_type=client_credentials&scope=basic premier',
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {'Authorization': _basicAuth()},
        ),
      );
      final token   = resp.data?['access_token'] as String?;
      final expires = (resp.data?['expires_in'] as num?)?.toInt() ?? 86400;
      if (token == null) return null;
      _accessToken = token;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expires - 60));
      return _accessToken;
    } catch (_) {
      return null;
    }
  }

  String _basicAuth() {
    final creds   = '$_clientId:$_clientSecret';
    final bytes   = creds.codeUnits;
    const chars   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final buf     = StringBuffer();
    for (int i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      buf.write(chars[(b0 >> 2) & 0x3F]);
      buf.write(chars[((b0 << 4) | (b1 >> 4)) & 0x3F]);
      buf.write(i + 1 < bytes.length ? chars[((b1 << 2) | (b2 >> 6)) & 0x3F] : '=');
      buf.write(i + 2 < bytes.length ? chars[b2 & 0x3F] : '=');
    }
    return 'Basic ${buf.toString()}';
  }

  // ── Barkod Arama ─────────────────────────────────────────────────────────

  /// EAN-13 / UPC barkod ile ürün arar. Bulamazsa null döner.
  /// Küresel markalar (Coca-Cola, Lay's, Nutella, Nescafé vb.) için güçlüdür.
  Future<FoodAnalysisResult?> lookupBarcode(String barcode) async {
    if (barcode.isEmpty) return null;

    // 13 haneye tamamla (UPC → GTIN-13)
    final gtin = barcode.padLeft(13, '0');

    final cached = await FoodCacheService.instance.get('fatsecret_barcode', gtin);
    if (cached != null) return cached;

    final token = await _getToken();
    if (token == null) return null;

    try {
      // Adım 1: barkod → food_id
      final idResp = await _dio.get<Map<String, dynamic>>(
        _apiBase,
        queryParameters: {
          'method':  'food.find_id_for_barcode.v2',
          'barcode': gtin,
          'format':  'json',
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final foodId = idResp.data?['food_id']?['value'] as String?;
      if (foodId == null) return null;

      // Adım 2: food_id → detay (v5: alerjen + diyet bayrakları dahil)
      final detailResp = await _dio.get<Map<String, dynamic>>(
        _apiBase,
        queryParameters: {
          'method':                 'food.get.v5',
          'food_id':                foodId,
          'include_food_attributes': true,
          'format':                 'json',
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final foodData = detailResp.data?['food'] as Map<String, dynamic>?;
      if (foodData == null) return null;

      final name    = (foodData['food_name'] as String?)?.trim() ?? '';
      if (name.isEmpty) return null;

      final servings = foodData['servings']?['serving'];
      final Map<String, dynamic>? s = servings is List
          ? (servings.first as Map<String, dynamic>?)
          : (servings as Map<String, dynamic>?);
      if (s == null) return null;

      final cal     = _num(s['calories']);
      if (cal <= 0) return null;

      final protein = _num(s['protein']);
      final carbs   = _num(s['carbohydrate']);
      final fat     = _num(s['fat']);
      final fiber   = _num(s['fiber']);
      final sodium  = _num(s['sodium']);
      final sugar   = _num(s['sugar']);
      final serving = (s['serving_description'] as String?) ?? '1 porsiyon';

      // Alerjen ve diyet bayraklarını not alanına ekle (ileride ayrı alan yapılabilir)
      final attrs  = foodData['food_attributes'] as Map<String, dynamic>?;
      final extras = _buildAttrsNote(attrs);

      final result = FoodAnalysisResult(
        foodName:   name,
        calories:   cal,
        proteinG:   protein,
        carbsG:     carbs,
        fatG:       fat,
        fiberG:     fiber,
        sodiumMg:   sodium,
        sugarG:     sugar,
        confidence: 'high',
        note:       '$serving — FatSecret${extras.isNotEmpty ? ' · $extras' : ''}',
      );

      FoodCacheService.instance.put('fatsecret_barcode', gtin, result);
      return result;
    } catch (_) {
      return null;
    }
  }

  // ── Yardımcılar ───────────────────────────────────────────────────────────

  int _num(dynamic v) => double.tryParse(v?.toString() ?? '')?.round() ?? 0;

  /// Alerjen / diyet bilgisini kısa metin olarak üretir.
  String _buildAttrsNote(Map<String, dynamic>? attrs) {
    if (attrs == null) return '';
    final parts = <String>[];

    final prefs    = attrs['preferences'] as List<dynamic>?;
    final allergens = attrs['allergens']  as List<dynamic>?;

    if (prefs != null) {
      for (final p in prefs) {
        final map = p as Map<String, dynamic>;
        if (map['value'] == 1) {
          final name = map['name'] as String? ?? '';
          if (name == 'vegan')      parts.add('Vegan');
          if (name == 'vegetarian') parts.add('Vejetaryen');
        }
      }
    }

    if (allergens != null) {
      final flagged = <String>[];
      for (final a in allergens) {
        final map = a as Map<String, dynamic>;
        if (map['value'] == 1) {
          final n = map['name'] as String? ?? '';
          final label = switch (n) {
            'gluten'    => 'Gluten',
            'milk'      => 'Süt',
            'lactose'   => 'Laktoz',
            'egg'       => 'Yumurta',
            'fish'      => 'Balık',
            'nuts'      => 'Kuruyemiş',
            'peanuts'   => 'Yer fıstığı',
            'sesame'    => 'Susam',
            'shellfish' => 'Kabuklu deniz ürünü',
            'soy'       => 'Soya',
            _           => '',
          };
          if (label.isNotEmpty) flagged.add(label);
        }
      }
      if (flagged.isNotEmpty) parts.add('İçerir: ${flagged.join(', ')}');
    }

    return parts.join(' · ');
  }
}
