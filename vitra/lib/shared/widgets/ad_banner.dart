import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/providers/premium_provider.dart';
import '../../core/services/ad_service.dart';

/// Ücretsiz kullanıcılara gösterilen AdMob banner.
/// isPremium == true ise hiçbir şey render etmez.
class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _banner = AdService.instance.createBanner(
      onLoaded: (ad) {
        if (mounted) setState(() => _loaded = true);
      },
    );
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium || !_loaded || _banner == null) return const SizedBox.shrink();

    return Container(
      alignment: Alignment.center,
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}
