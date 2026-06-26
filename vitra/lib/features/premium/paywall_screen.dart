import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/theme/v_theme.dart';
import '../../core/services/premium_service.dart';
import '../../core/providers/premium_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Package? _monthlyPackage;
  Package? _annualPackage;
  bool _isAnnualSelected = false; // varsayılan: aylık
  bool _loading = false;
  bool _restoring = false;

  Package? get _selectedPackage =>
      _isAnnualSelected ? _annualPackage : _monthlyPackage;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final pkgs = await PremiumService.instance.getOfferings();
    if (!mounted) return;
    setState(() {
      _monthlyPackage = pkgs.where((p) =>
          p.identifier == 'monthly' ||
          p.packageType == PackageType.monthly).firstOrNull;
      _annualPackage = pkgs.where((p) =>
          p.identifier == 'annual' ||
          p.packageType == PackageType.annual).firstOrNull;
    });
  }

  Future<void> _purchase() async {
    final pkg = _selectedPackage;
    if (pkg == null || _loading) return;
    setState(() => _loading = true);
    final success = await PremiumService.instance.purchase(pkg);
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) {
      ref.read(isPremiumProvider.notifier).refresh();
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satın alma işlemi tamamlanamadı.')),
      );
    }
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    final success = await PremiumService.instance.restore();
    if (!mounted) return;
    setState(() => _restoring = false);
    if (success) {
      ref.read(isPremiumProvider.notifier).refresh();
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktif abonelik bulunamadı.')),
      );
    }
  }

  String _contextualSubtitle(BuildContext context) {
    final reason = ModalRoute.of(context)?.settings.arguments as String?;
    return switch (reason) {
      'ai_limit'   => 'Günlük AI limitini doldurdun. Premium ile sınırsız analiz yap.',
      'coach'      => 'AI koç özelliği Premium\'a özel. Hedefine ulaşmak için koçunu aktifleştir.',
      'stats'      => 'Detaylı istatistikler ve haftalık raporlar Premium\'a özel.',
      'recipe'     => 'Kişisel yemek önerileri Premium\'a özel.',
      'barcode'    => 'Barkod tarayıcı Premium\'a özel. Ürünleri anında ekle.',
      'scan'       => 'Fotoğrafla kalori analizi Premium\'a özel.',
      _            => 'Hedefine ulaşmak için ihtiyacın olan her şey',
    };
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      body: SafeArea(
        child: Column(
          children: [
            // Kapat butonu
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    // 3 günlük deneme vurgusu
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF14C2A8), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            '3 GÜN ÜCRETSİZ DENE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.star_rounded,
                              color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // İkon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            vc.primary,
                            vc.primary.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: vc.primary.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.psychology_rounded,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Vitra Premium',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _contextualSubtitle(context),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Özellikler
                    ..._features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: f.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(f.icon, color: f.color, size: 17),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      )),
                                  Text(f.subtitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white
                                            .withValues(alpha: 0.5),
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Plan seçimi
                    if (_monthlyPackage != null || _annualPackage != null) ...[
                      Row(
                        children: [
                          if (_monthlyPackage != null)
                            Expanded(
                              child: _PlanCard(
                                pkg: _monthlyPackage!,
                                selected: !_isAnnualSelected,
                                isPopular: false,
                                onTap: () => setState(() => _isAnnualSelected = false),
                              ),
                            ),
                          if (_monthlyPackage != null && _annualPackage != null)
                            const SizedBox(width: 8),
                          if (_annualPackage != null)
                            Expanded(
                              child: _PlanCard(
                                pkg: _annualPackage!,
                                selected: _isAnnualSelected,
                                isPopular: true,
                                onTap: () => setState(() => _isAnnualSelected = true),
                                monthlyPrice: _monthlyPackage?.storeProduct.price,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.hourglass_top_rounded,
                                color: Colors.white.withValues(alpha: 0.4), size: 32),
                            const SizedBox(height: 10),
                            const Text(
                              'Planlar yükleniyor...',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Abonelik planları alınamadı. İnternet bağlantını kontrol et ve sayfayı yenile.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: _loadPackages,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Yenile',
                                    style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Satın Al butonu
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed:
                            _loading || _selectedPackage == null ? null : _purchase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vc.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '3 Gün Ücretsiz Dene',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Sonra otomatik devam eder',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Geri yükle
                    GestureDetector(
                      onTap: _restoring ? null : _restore,
                      child: Text(
                        _restoring
                            ? 'Kontrol ediliyor...'
                            : 'Satın alımı geri yükle',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.4),
                          decoration: TextDecoration.underline,
                          decorationColor:
                              Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.5)),
                        const SizedBox(width: 6),
                        Text(
                          'İstediğin zaman iptal et, tek tıkla',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Abonelik otomatik yenilenir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Özellik listesi ───────────────────────────────────────────────────────────

class _Feature {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _Feature(this.icon, this.color, this.title, this.subtitle);
}

const _features = [
  _Feature(
    Icons.camera_alt_rounded,
    Color(0xFF14C2A8),
    'Sınırsız AI analizi',
    'Fotoğraf, metin, barkod — günde 3\'ten sınırsıza',
  ),
  _Feature(
    Icons.psychology_rounded,
    Color(0xFF8B5CF6),
    'Kişisel AI koç sohbeti',
    'Günün her saati koçunla konuş, sınırsız mesaj',
  ),
  _Feature(
    Icons.fitness_center_rounded,
    Color(0xFFEF4444),
    'Egzersiz & kalori dengesi',
    'Yakılan kalorileri günlüğüne ekle, net değeri gör',
  ),
  _Feature(
    Icons.monitor_weight_outlined,
    Color(0xFF3B82F6),
    'Kilo takibi & grafik',
    'Günlük tartı logu, haftalık ilerleme grafiği',
  ),
  _Feature(
    Icons.calendar_month_rounded,
    Color(0xFFF59E0B),
    'Haftalık AI raporu',
    'Verilerine dayalı derinlemesine kişisel analiz',
  ),
  _Feature(
    Icons.bar_chart_rounded,
    Color(0xFF10B981),
    'Detaylı istatistikler',
    '30 günlük kalori, su ve rutin geçmişi',
  ),
  _Feature(
    Icons.block_rounded,
    Color(0xFF6B7280),
    'Reklamsız deneyim',
    'Hiçbir kesinti olmadan odaklan',
  ),
];

class _PlanCard extends StatelessWidget {
  final Package pkg;
  final bool selected;
  final bool isPopular;
  final VoidCallback onTap;
  final double? monthlyPrice;

  const _PlanCard({
    required this.pkg,
    required this.selected,
    required this.isPopular,
    required this.onTap,
    this.monthlyPrice,
  });

  String _monthlyEquivalent(double annualPrice) {
    final monthly = annualPrice / 12;
    if (monthly >= 1) return '${monthly.round()} TL';
    return '${(monthly * 100).round()} kr';
  }

  String? _savings(double annualPrice) {
    final mp = monthlyPrice;
    if (mp == null) return null;
    final saved = (mp * 12) - annualPrice;
    if (saved <= 0) return null;
    return '${saved.round()} TL tasarruf';
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? vc.primary : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? vc.primary : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            if (isPopular) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('EN İYİ DEĞERİ',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    )),
              ),
            ],
            Text(
              isPopular ? 'Yıllık' : 'Aylık',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              pkg.storeProduct.priceString,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            if (isPopular) ...[
              const SizedBox(height: 4),
              Text(
                'Ayda ${_monthlyEquivalent(pkg.storeProduct.price)}',
                style: TextStyle(
                  fontSize: 10,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
              if (_savings(pkg.storeProduct.price) != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _savings(pkg.storeProduct.price)!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
