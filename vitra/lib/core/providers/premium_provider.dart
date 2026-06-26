import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/premium_service.dart';

// ── Premium durumu ─────────────────────────────────────────────────────────────

final isPremiumProvider = StateNotifierProvider<_PremiumNotifier, bool>(
  (ref) => _PremiumNotifier(),
);

class _PremiumNotifier extends StateNotifier<bool> {
  _PremiumNotifier() : super(false) {
    _check();
  }

  Future<void> _check() async {
    // TODO: RevenueCat production aktif olunca bu satırı kaldır
    state = true; return;
    // ignore: dead_code
    final result = await PremiumService.instance.isPremium();
    state = result;
  }

  Future<void> refresh() => _check();

  void setDev(bool value) => state = value; // geliştirme sırasında test için
}

// ── Günlük AI kullanım sayacı ─────────────────────────────────────────────────
// Ücretsiz kullanıcı: günde 3 AI fotoğraf/metin analizi

class AiUsageNotifier extends StateNotifier<int> {
  AiUsageNotifier() : super(0) {
    _load();
  }

  static const _kCount  = 'ai_usage_count';
  static const _kDate   = 'ai_usage_date';
  static const freeLimit = 3;

  String get _todayKey {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_kDate);
    if (savedDate != _todayKey) {
      // Yeni gün — sayacı sıfırla
      await prefs.setInt(_kCount, 0);
      await prefs.setString(_kDate, _todayKey);
      state = 0;
    } else {
      state = prefs.getInt(_kCount) ?? 0;
    }
  }

  Future<bool> canUse(bool isPremium) async {
    if (isPremium) return true;
    await _load();
    return state < freeLimit;
  }

  Future<void> increment() async {
    final prefs = await SharedPreferences.getInstance();
    final newCount = state + 1;
    await prefs.setInt(_kCount, newCount);
    await prefs.setString(_kDate, _todayKey);
    state = newCount;
  }

  int get remaining => (freeLimit - state).clamp(0, freeLimit);
}

final aiUsageProvider =
    StateNotifierProvider<AiUsageNotifier, int>(
  (ref) => AiUsageNotifier(),
);
