import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob reklam servisi.
/// Ücretsiz kullanıcılara banner + interstitial gösterir.
/// Premium kullanıcılara hiçbir reklam gösterilmez.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;

  // Banner unit ID'leri
  String get _bannerUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return dotenv.env['ADMOB_BANNER_ANDROID'] ??
          'ca-app-pub-3940256099942544/6300978111';
    }
    return dotenv.env['ADMOB_BANNER_IOS'] ??
        'ca-app-pub-3940256099942544/2934735716';
  }

  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  /// Ücretsiz kullanıcılar için banner ad oluşturur.
  BannerAd createBanner({required void Function(Ad ad) onLoaded}) {
    final banner = BannerAd(
      adUnitId: _bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    banner.load();
    return banner;
  }
}
