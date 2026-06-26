import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/v_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/aurora_bg.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/providers/premium_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/notification_service.dart';
import '../../shared/widgets/v_theme_picker.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc        = context.vt;
    final profile   = ref.watch(userProfileProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final theme     = ref.watch(themeProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _SettingsHero(
              vc:        vc,
              profile:   profile,
              isPremium: isPremium,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Profil ──────────────────────────────────────────────────
                _SectionHeader('Profil', vc),
                const SizedBox(height: 8),
                _ProfileCard(vc: vc, userName: profile.userName),
                const SizedBox(height: 8),
                _PersonalInfoCard(profile: profile, ref: ref, vc: vc),
                const SizedBox(height: 20),

                // ── Hedefler ─────────────────────────────────────────────────
                _SectionHeader('Hedefler', vc),
                const SizedBox(height: 8),
                _GoalsCard(vc: vc),
                const SizedBox(height: 20),

                // ── Bildirimler ───────────────────────────────────────────────
                _SectionHeader('Bildirimler', vc),
                const SizedBox(height: 8),
                _NotificationCard(vc: vc),
                const SizedBox(height: 20),

                // ── Uygulama ──────────────────────────────────────────────────
                _SectionHeader('Uygulama', vc),
                const SizedBox(height: 8),
                _ThemeCard(vc: vc, current: theme),
                const SizedBox(height: 20),

                // ── Hesap ─────────────────────────────────────────────────────
                _SectionHeader('Hesap', vc),
                const SizedBox(height: 8),
                _PremiumBannerCard(isPremium: isPremium, vc: vc),
                const SizedBox(height: 8),
                _AboutCard(vc: vc),
                if (kDebugMode) ...[
                  const SizedBox(height: 8),
                  _DevCard(isPremium: isPremium, ref: ref, vc: vc),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VColors vc;

  const _SectionHeader(this.title, this.vc);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: vc.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Settings Aurora Hero ──────────────────────────────────────────────────────

class _SettingsHero extends StatelessWidget {
  final VColors vc;
  final UserProfile profile;
  final bool isPremium;

  const _SettingsHero({
    required this.vc,
    required this.profile,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final user          = FirebaseAuth.instance.currentUser;
    final email         = user?.email ?? '';
    final effectiveName = profile.userName.isNotEmpty
        ? profile.userName
        : (email.isNotEmpty ? email.split('@').first : 'Vitra');
    final initial = effectiveName.isNotEmpty
        ? effectiveName[0].toUpperCase()
        : 'V';

    return SizedBox(
      height: 180,
      child: AuroraBg(
        primaryColor:   vc.primary,
        secondaryColor: const Color(0xFF8B5CF6),
        accentColor:    AppColors.gold,
        primaryOpacity: vc.isDark ? 0.22 : 0.15,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.60, 1.0],
                  colors: [Colors.transparent, Colors.transparent, vc.bg],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            vc.primary.withValues(alpha: 0.30),
                            vc.primaryGlow.withValues(alpha: 0.18),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: vc.primary.withValues(alpha: 0.50),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: vc.primary.withValues(alpha: 0.28),
                            blurRadius: 16,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: vc.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            effectiveName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: vc.text,
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hedeflerine doğru ilerliyorsun',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: vc.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppColors.gold, Color(0xFFF59E0B)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.40),
                              blurRadius: 10,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 11, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Premium',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                )),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Ayarlar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: vc.text,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ── Tema Seçim Kartı ──────────────────────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  final VColors vc;
  final VitraTheme current;

  const _ThemeCard({required this.vc, required this.current});

  @override
  Widget build(BuildContext context) {
    final preview = current.previewColors;

    return GestureDetector(
      onTap: () => VThemePicker.show(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: vc.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: vc.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Tema önizleme
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: preview,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: preview.last.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Uygulama Teması',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: vc.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    current.displayName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: vc.textSub,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: vc.primarySurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: vc.primary.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Değiştir',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: vc.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Premium Banner Kartı ──────────────────────────────────────────────────────

class _PremiumBannerCard extends StatefulWidget {
  final bool isPremium;
  final VColors vc;
  const _PremiumBannerCard({required this.isPremium, required this.vc});

  @override
  State<_PremiumBannerCard> createState() => _PremiumBannerCardState();
}

class _PremiumBannerCardState extends State<_PremiumBannerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = widget.vc;

    if (widget.isPremium) {
      return AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [vc.primary, vc.primaryGlow],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: vc.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.verified_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vitra Premium',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 2),
                  Text('Tüm özellikler aktif',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      )),
                ],
              ),
            ),
            // Animasyonlu altın rozet
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15 + 0.1 * _glowAnim.value),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.5 + 0.5 * _glowAnim.value),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3 * _glowAnim.value),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded,
                      size: 10,
                      color: AppColors.gold.withValues(alpha: 0.7 + 0.3 * _glowAnim.value)),
                  const SizedBox(width: 4),
                  Text('AKTİF',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gold,
                        letterSpacing: 1,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/premium'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: vc.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: vc.primary.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: vc.primary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: vc.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.psychology_rounded,
                  color: vc.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Vitra Premium'a Geç",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: vc.text,
                      )),
                  const SizedBox(height: 2),
                  Text('Sınırsız AI koç, haftalık rapor ve daha fazlası',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: vc.textSub,
                      )),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: vc.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Profil Kartı ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final VColors vc;
  final String userName;
  const _ProfileCard({required this.vc, required this.userName});

  @override
  Widget build(BuildContext context) {
    final user          = FirebaseAuth.instance.currentUser;
    final email         = user?.email;
    final effectiveName = userName.isNotEmpty ? userName : (email ?? 'Kullanıcı');
    final initial       = effectiveName.isNotEmpty ? effectiveName[0].toUpperCase() : 'V';
    final displayName   = effectiveName;
    const subtitle      = 'Hedeflerine doğru ilerliyorsun';

    // Giriş yöntemi rozeti
    final provider = user?.providerData.firstOrNull?.providerId ?? '';
    final (loginLabel, loginColor, loginIcon) = switch (provider) {
      'google.com'  => ('Google', const Color(0xFF4285F4), Icons.g_mobiledata_rounded),
      'password'    => ('E-posta', const Color(0xFF10B981), Icons.email_outlined),
      'apple.com'   => ('Apple', const Color(0xFF555555), Icons.apple_rounded),
      _             => ('Misafir', const Color(0xFF9CA3AF), Icons.person_outline_rounded),
    };

    return _Card(
      vc: vc,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: vc.primarySurface,
                  border: Border.all(
                    color: vc.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: vc.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: vc.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Giriş yöntemi rozeti
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: loginColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: loginColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(loginIcon,
                              size: 12, color: loginColor),
                          const SizedBox(width: 4),
                          Text(
                            loginLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: loginColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: vc.border.withValues(alpha: 0.5)),
          _SettingsRow(
            vc: vc,
            icon: Icons.logout_rounded,
            iconColor: Colors.red,
            iconBg: Colors.red.withValues(alpha: 0.10),
            label: 'Çıkış Yap',
            onTap: () => _confirmSignOut(context),
          ),
          Divider(height: 1, color: vc.border.withValues(alpha: 0.5)),
          _SettingsRow(
            vc: vc,
            icon: Icons.delete_forever_rounded,
            iconColor: Colors.red.shade800,
            iconBg: Colors.red.withValues(alpha: 0.08),
            label: 'Hesabımı Sil',
            onTap: () => _confirmDeleteAccount(context),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabımı Sil'),
        content: const Text(
            'Hesabın ve tüm verilerin kalıcı olarak silinecek. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteAccount(context);
            },
            child: const Text('Hesabi Sil',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      await FirestoreService.instance.deleteAllUserData();
      await LocalStorageService.instance.clearUserData();
      await LocalStorageService.instance.resetOnboardingAndGoals();
      await GoogleSignIn().signOut().catchError((_) => null);
      await GoogleSignIn().disconnect().catchError((_) => null);
      await FirebaseAuth.instance.currentUser?.delete();
      if (context.mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/onboarding', (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await GoogleSignIn().signOut().catchError((_) => null);
        await GoogleSignIn().disconnect().catchError((_) => null);
        await FirebaseAuth.instance.signOut();
        await LocalStorageService.instance.clearUserData();
        await LocalStorageService.instance.resetOnboardingAndGoals();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "Hesabı silmek için tekrar giriş yap, ardından Ayarlar'dan tekrar dene."),
            duration: Duration(seconds: 5),
          ));
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/onboarding/complete', (_) => false);
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Hesap silinemedi. Lütfen tekrar dene.'),
        ));
      }
    }
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text(
            'Hesabından çıkış yapılacak. Devam etmek istiyor musun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalStorageService.instance.clearUserData();
              await LocalStorageService.instance.resetOnboardingAndGoals();
              await GoogleSignIn().signOut();
              await GoogleSignIn().disconnect().catchError((_) => null);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/onboarding/complete', (_) => false);
              }
            },
            child: const Text('Çıkış Yap',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

// ── Kişisel Bilgiler Kartı ────────────────────────────────────────────────────

typedef _SaveCallback = Future<void> Function({
  required int age,
  required double heightCm,
  required double weightKg,
  required String gender,
  required String activityLevel,
  required List<String> goals,
  required double weeklyPaceFactor,
});

class _PersonalInfoCard extends StatelessWidget {
  final UserProfile profile;
  final WidgetRef ref;
  final VColors vc;

  const _PersonalInfoCard({
    required this.profile,
    required this.ref,
    required this.vc,
  });

  String get _summary {
    if (!profile.hasPhysicalProfile) return 'Bilgilerini ekle →';
    final gender = profile.gender == 'male' ? 'Erkek' : 'Kadın';
    final height = profile.heightCm!.toStringAsFixed(0);
    final weight = profile.weightKg!.toStringAsFixed(1);
    final nameStr = profile.userName.isNotEmpty ? '${profile.userName}  •  ' : '';
    return '$nameStr${profile.age} yaş  •  $gender  •  $height cm  •  $weight kg';
  }

  String get _activityGoalSummary {
    final activity = switch (profile.activityLevel) {
      'sedentary' => 'Hareketsiz',
      'light'     => 'Hafif aktif',
      'moderate'  => 'Orta aktif',
      'very'      => 'Çok aktif',
      _           => '',
    };
    final goal = profile.goals.contains('lose_weight')
        ? 'Kilo vermek'
        : profile.goals.contains('gain_muscle')
            ? 'Kas yapmak'
            : 'Genel sağlık';
    return activity.isEmpty ? goal : '$activity  •  $goal';
  }

  @override
  Widget build(BuildContext context) {
    final hasData = profile.hasPhysicalProfile;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PersonalInfoEditPage(
            profile: profile,
            initialName: profile.userName,
            onSaveName: (name) =>
                ref.read(userProfileProvider.notifier).updateUserName(name),
            onSave: ({
              required int age,
              required double heightCm,
              required double weightKg,
              required String gender,
              required String activityLevel,
              required List<String> goals,
              required double weeklyPaceFactor,
            }) =>
                ref.read(userProfileProvider.notifier).updatePhysicalProfile(
                      age:              age,
                      heightCm:         heightCm,
                      weightKg:         weightKg,
                      gender:           gender,
                      activityLevel:    activityLevel,
                      goals:            goals,
                      weeklyPaceFactor: weeklyPaceFactor,
                    ),
          ),
        ),
      ),
      child: _Card(
        vc: vc,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: vc.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.person_rounded, color: vc.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kişisel Bilgilerim',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: vc.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _summary,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: hasData ? vc.textSub : vc.primary,
                    ),
                  ),
                  if (hasData) ...[
                    const SizedBox(height: 2),
                    Text(
                      _activityGoalSummary,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: vc.textSub,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: vc.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Kişisel Bilgiler Düzenleme Sayfası ───────────────────────────────────────

class _PersonalInfoEditPage extends StatefulWidget {
  final UserProfile profile;
  final _SaveCallback onSave;
  final String initialName;
  final void Function(String) onSaveName;

  const _PersonalInfoEditPage({
    required this.profile,
    required this.onSave,
    required this.initialName,
    required this.onSaveName,
  });

  @override
  State<_PersonalInfoEditPage> createState() => _PersonalInfoEditPageState();
}

class _PersonalInfoEditPageState extends State<_PersonalInfoEditPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late String  _gender;
  late int     _age;
  late String? _activityLevel;
  late List<String> _goals;
  late double  _weeklyPaceFactor;
  bool         _saving = false;

  static const _activityLevels = [
    ('sedentary', '🪑', 'Hareketsiz',  'Masabaşı çalışıyorum, az hareket'),
    ('light',     '🚶', 'Hafif aktif', 'Haftada 1-3 gün egzersiz'),
    ('moderate',  '🏃', 'Orta aktif',  'Haftada 3-5 gün egzersiz'),
    ('very',      '⚡', 'Çok aktif',   'Haftada 6-7 gün yoğun antrenman'),
  ];

  static const _goalOptions = [
    ('lose_weight',  '🏃', 'Kilo vermek'),
    ('gain_muscle',  '💪', 'Kas kazanmak'),
    ('stay_healthy', '🌿', 'Sağlıklı kalmak'),
    ('eat_better',   '🥗', 'Daha iyi beslenme'),
    ('drink_more',   '💧', 'Daha fazla su'),
    ('build_habits', '✅', 'Alışkanlık oluşturmak'),
  ];

  int? get _previewCalories {
    final h = double.tryParse(_heightCtrl.text);
    final w = double.tryParse(_weightCtrl.text);
    if (h == null || w == null || _activityLevel == null) return null;
    if (h < 100 || h > 250 || w < 20 || w > 300) return null;
    return UserProfileNotifier.calcCalorieGoal(
      weightKg: w,
      heightCm: h,
      age: _age,
      gender: _gender,
      activityLevel: _activityLevel!,
      goals: _goals,
    );
  }

  int? get _previewWater {
    final w = double.tryParse(_weightCtrl.text);
    if (w == null || w < 20 || w > 300 || _activityLevel == null) return null;
    return UserProfileNotifier.calcWaterGoal(
      weightKg: w,
      activityLevel: _activityLevel!,
      goals: _goals,
    );
  }

  bool get _isComplete {
    final h = double.tryParse(_heightCtrl.text);
    final w = double.tryParse(_weightCtrl.text);
    return h != null && w != null &&
        h >= 100 && h <= 250 &&
        w >= 20 && w <= 300 &&
        _activityLevel != null;
  }

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl      = TextEditingController(text: widget.initialName);
    _heightCtrl    = TextEditingController(text: p.heightCm?.toStringAsFixed(0) ?? '');
    _weightCtrl    = TextEditingController(text: p.weightKg?.toStringAsFixed(1) ?? '');
    _gender           = p.gender ?? 'male';
    _age              = p.age ?? 25;
    _activityLevel    = p.activityLevel;
    _goals            = List.from(p.goals);
    _weeklyPaceFactor = p.weeklyPaceFactor;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final h = double.tryParse(_heightCtrl.text);
    final w = double.tryParse(_weightCtrl.text);
    if (h == null || w == null || _activityLevel == null) return;
    setState(() => _saving = true);
    final newName = _nameCtrl.text.trim();
    if (newName != widget.initialName) {
      widget.onSaveName(newName);
    }
    await widget.onSave(
      age:              _age,
      heightCm:         h,
      weightKg:         w,
      gender:           _gender,
      activityLevel:    _activityLevel!,
      goals:            _goals,
      weeklyPaceFactor: _weeklyPaceFactor,
    );
    // Kilo değiştiyse kilo takibine otomatik kayıt ekle
    final prevWeight = widget.profile.weightKg;
    if (prevWeight == null || (w - prevWeight).abs() > 0.05) {
      FirestoreService.instance.saveWeightEntry(w);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vc  = context.vt;
    final cal = _previewCalories;
    final wtr = _previewWater;

    return Scaffold(
      backgroundColor: vc.bg,
      appBar: AppBar(
        backgroundColor: vc.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: vc.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kişisel Bilgiler',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: vc.text,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _editSectionLabel(vc, 'Adın'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(fontSize: 15, color: vc.text, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Adını gir',
                        hintStyle: TextStyle(color: vc.textMuted),
                        filled: true,
                        fillColor: vc.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: vc.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: vc.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: vc.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    _editSectionLabel(vc, 'Cinsiyet'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _EditGenderButton(
                            vc: vc,
                            label: 'Erkek',
                            emoji: '👨',
                            selected: _gender == 'male',
                            onTap: () => setState(() => _gender = 'male'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EditGenderButton(
                            vc: vc,
                            label: 'Kadın',
                            emoji: '👩',
                            selected: _gender == 'female',
                            onTap: () => setState(() => _gender = 'female'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    _editSectionLabel(vc, 'Yaşın'),
                    const SizedBox(height: 10),
                    _EditAgeStepper(
                      vc: vc,
                      value: _age,
                      onChanged: (v) => setState(() => _age = v),
                    ),
                    const SizedBox(height: 22),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _editSectionLabel(vc, 'Boyun'),
                              const SizedBox(height: 10),
                              _EditMeasurementField(
                                vc: vc,
                                controller: _heightCtrl,
                                unit: 'cm',
                                hint: '175',
                                min: 100, max: 250,
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _editSectionLabel(vc, 'Kilonuz'),
                              const SizedBox(height: 10),
                              _EditMeasurementField(
                                vc: vc,
                                controller: _weightCtrl,
                                unit: 'kg',
                                hint: '70',
                                min: 20, max: 300,
                                decimal: true,
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    _editSectionLabel(vc, 'Yaşam tarzın nasıl?'),
                    const SizedBox(height: 10),
                    ..._activityLevels.map((lvl) {
                      final (id, emoji, label, desc) = lvl;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _EditOptionCard(
                          vc: vc,
                          emoji: emoji,
                          label: label,
                          description: desc,
                          selected: _activityLevel == id,
                          onTap: () => setState(() => _activityLevel = id),
                        ),
                      );
                    }),
                    const SizedBox(height: 18),

                    // Haftalık hız — sadece kilo ver / kas kazan seçiliyse göster
                    if (_goals.contains('lose_weight') ||
                        _goals.contains('gain_muscle')) ...[
                      _editSectionLabel(vc, 'Haftalık Hız'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (final pace in [
                            (0.25, 'Yavaş',  '0.25 kg/hafta', '🐢'),
                            (0.5,  'Normal', '0.5 kg/hafta',  '🏃'),
                            (0.75, 'Hızlı',  '0.75 kg/hafta', '⚡'),
                          ]) ...[
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _weeklyPaceFactor = pace.$1),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _weeklyPaceFactor == pace.$1
                                        ? vc.primarySurface
                                        : vc.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _weeklyPaceFactor == pace.$1
                                          ? vc.primary
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(pace.$4,
                                          style: const TextStyle(
                                              fontSize: 18)),
                                      const SizedBox(height: 4),
                                      Text(
                                        pace.$2,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _weeklyPaceFactor ==
                                                  pace.$1
                                              ? vc.primary
                                              : vc.text,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        pace.$3,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: vc.textSub),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (pace.$1 != 0.75) const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],

                    _editSectionLabel(vc, 'Hedefin ne? (birden fazla seçebilirsin)'),
                    const SizedBox(height: 10),
                    for (int row = 0; row < 3; row++) ...[
                      Row(
                        children: [
                          for (int col = 0; col < 2; col++) ...[
                            Expanded(
                              child: Builder(builder: (_) {
                                final (id, emoji, label) = _goalOptions[row * 2 + col];
                                final selected = _goals.contains(id);
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    selected ? _goals.remove(id) : _goals.add(id);
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: selected ? vc.primarySurface : vc.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: selected ? vc.primary : Colors.transparent,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                              alpha: selected ? 0.04 : 0.06),
                                          blurRadius: 12,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(emoji,
                                            style: const TextStyle(fontSize: 28)),
                                        const SizedBox(height: 6),
                                        Text(
                                          label,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: selected ? vc.primary : vc.text,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                            if (col == 0) const SizedBox(width: 12),
                          ],
                        ],
                      ),
                      if (row < 2) const SizedBox(height: 12),
                    ],

                    if (cal != null && wtr != null) ...[
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _EditLiveCalcCard(
                          key: ValueKey('$cal-$wtr'),
                          vc: vc,
                          calories: cal,
                          waterMl: wtr,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_isComplete && !_saving) ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: vc.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: vc.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          'Kaydet',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit Page Yardımcı Widget'ları ───────────────────────────────────────────

Widget _editSectionLabel(VColors vc, String text) => Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: vc.textSub,
        letterSpacing: 0.3,
      ),
    );

class _EditGenderButton extends StatelessWidget {
  final VColors vc;
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _EditGenderButton({
    required this.vc,
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: selected ? vc.primary : vc.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? vc.primary : vc.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : vc.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditAgeStepper extends StatelessWidget {
  final VColors vc;
  final int value;
  final ValueChanged<int> onChanged;

  const _EditAgeStepper({
    required this.vc,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _EditStepButton(
            vc: vc,
            icon: Icons.remove,
            onTap: value > 10 ? () => onChanged(value - 1) : null,
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: vc.text,
              ),
            ),
          ),
          _EditStepButton(
            vc: vc,
            icon: Icons.add,
            onTap: value < 120 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _EditStepButton extends StatelessWidget {
  final VColors vc;
  final IconData icon;
  final VoidCallback? onTap;

  const _EditStepButton({
    required this.vc,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: onTap != null ? vc.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? vc.primary : vc.textMuted,
        ),
      ),
    );
  }
}

class _EditMeasurementField extends StatelessWidget {
  final VColors vc;
  final TextEditingController controller;
  final String unit;
  final String hint;
  final double min;
  final double max;
  final bool decimal;
  final ValueChanged<String> onChanged;

  const _EditMeasurementField({
    required this.vc,
    required this.controller,
    required this.unit,
    required this.hint,
    required this.min,
    required this.max,
    required this.onChanged,
    this.decimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: decimal
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: decimal
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
                  : [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: vc.text,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: vc.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Text(
              unit,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: vc.textSub,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditOptionCard extends StatelessWidget {
  final VColors vc;
  final String emoji;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _EditOptionCard({
    required this.vc,
    required this.emoji,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? vc.primarySurface : vc.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? vc.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? vc.primary : vc.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: vc.textSub),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: vc.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _EditLiveCalcCard extends StatelessWidget {
  final VColors vc;
  final int calories;
  final int waterMl;

  const _EditLiveCalcCard({
    super.key,
    required this.vc,
    required this.calories,
    required this.waterMl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: vc.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _EditCalcChip(
              vc: vc, icon: '🔥',
              label: 'Kalori hedefin',
              value: '$calories kcal',
            ),
          ),
          Container(width: 1, height: 40, color: vc.primary.withValues(alpha: 0.15)),
          Expanded(
            child: _EditCalcChip(
              vc: vc, icon: '💧',
              label: 'Su hedefin',
              value: '${(waterMl / 1000).toStringAsFixed(1)} litre',
            ),
          ),
        ],
      ),
    );
  }
}

class _EditCalcChip extends StatelessWidget {
  final VColors vc;
  final String icon;
  final String label;
  final String value;

  const _EditCalcChip({
    required this.vc,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: vc.textSub)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: vc.primary,
          ),
        ),
      ],
    );
  }
}


// ── Hedeflerim Kartı ──────────────────────────────────────────────────────────

class _GoalsCard extends ConsumerStatefulWidget {
  final VColors vc;
  const _GoalsCard({required this.vc});

  @override
  ConsumerState<_GoalsCard> createState() => _GoalsCardState();
}

class _GoalsCardState extends ConsumerState<_GoalsCard> {
  static const _activityLabels = {
    'sedentary': 'Hareketsiz',
    'light':     'Hafif aktif',
    'moderate':  'Orta aktif',
    'very':      'Çok aktif',
    'extra':     'Ekstra aktif',
  };

  static const _dietLabels = {
    'all':          'Her şeyi yerim',
    'vegetarian':   'Vejeteryan',
    'vegan':        'Vegan',
    'gluten_free':  'Glutensiz',
    'keto':         'Ketojenik',
    'low_carb':     'Düşük karbonhidrat',
  };

  // Yerel görüntü state'i — provider dışındaki veriler için
  double? _targetWt;
  List<String> _diets = [];

  @override
  void initState() {
    super.initState();
    final storage = LocalStorageService.instance;
    _targetWt = storage.targetWeightKg;
    _diets    = storage.dietPreferences;
  }

  @override
  Widget build(BuildContext context) {
    final vc          = widget.vc;
    final profile     = ref.watch(userProfileProvider);
    final calorieGoal = profile.calorieGoal;
    final waterLiters = (profile.waterGoalMl / 1000).toStringAsFixed(1);
    final activity    = profile.activityLevel;

    return _Card(
      vc: vc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hedeflerim',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: vc.text,
            ),
          ),
          const SizedBox(height: 4),
          _SettingsRow(
            vc: vc,
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.calories,
            iconBg: vc.calorieSurface,
            label: 'Günlük Kalori Hedefi',
            value: '$calorieGoal kcal',
            onTap: () => _showEditDialog(
              context,
              title: 'Kalori Hedefini Düzenle',
              hint: 'kcal (örn. 2000)',
              initialValue: calorieGoal.toString(),
              keyboardType: TextInputType.number,
              onSave: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed > 0) {
                  ref.read(userProfileProvider.notifier).updateCalorieGoal(parsed);
                }
              },
            ),
          ),
          Divider(height: 1, color: vc.border.withValues(alpha: 0.5)),
          _SettingsRow(
            vc: vc,
            icon: Icons.water_drop_rounded,
            iconColor: AppColors.water,
            iconBg: vc.waterSurface,
            label: 'Günlük Su Hedefi',
            value: '$waterLiters L',
            onTap: () => _showEditDialog(
              context,
              title: 'Su Hedefini Düzenle',
              hint: 'ml (örn. 2500)',
              initialValue: profile.waterGoalMl.toString(),
              keyboardType: TextInputType.number,
              onSave: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed > 0) {
                  ref.read(userProfileProvider.notifier).updateWaterGoal(parsed);
                }
              },
            ),
          ),
          Divider(height: 1, color: vc.border.withValues(alpha: 0.5)),
          _SettingsRow(
            vc: vc,
            icon: Icons.flag_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: vc.habitSurface,
            label: 'Hedef Kilo',
            value: _targetWt != null ? '${_targetWt!.toStringAsFixed(1)} kg' : '—',
            onTap: () => _showEditDialog(
              context,
              title: 'Hedef Kiloyu Düzenle',
              hint: 'kg (örn. 70)',
              initialValue: _targetWt?.toStringAsFixed(1) ?? '',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onSave: (v) async {
                final parsed = double.tryParse(v);
                if (parsed != null && parsed > 0 && parsed <= 300) {
                  await LocalStorageService.instance.saveTargetWeight(parsed);
                  FirestoreService.instance.updateTargetWeightEntry(parsed);
                  if (mounted) setState(() => _targetWt = parsed);
                }
              },
            ),
          ),
          Divider(height: 1, color: vc.border.withValues(alpha: 0.5)),
          _SettingsRow(
            vc: vc,
            icon: Icons.directions_run_rounded,
            iconColor: const Color(0xFF8B5CF6),
            iconBg: vc.habitSurface,
            label: 'Aktivite Seviyesi',
            value: activity != null ? (_activityLabels[activity] ?? activity) : '—',
            onTap: () => _showActivityPicker(context),
          ),
          Divider(height: 1, color: vc.border.withValues(alpha: 0.5)),
          _SettingsRow(
            vc: vc,
            icon: Icons.restaurant_menu_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: vc.streakSurface,
            label: 'Beslenme Tercihi',
            value: _diets.isEmpty
                ? 'Her şeyi yerim'
                : _diets.map((d) => _dietLabels[d] ?? d).join(', '),
            onTap: () => _showDietPicker(context),
          ),
        ],
      ),
    );
  }

  void _showActivityPicker(BuildContext context) {
    final profile = ref.read(userProfileProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        vc: widget.vc,
        title: 'Aktivite Seviyesi',
        options: const [
          ('sedentary', 'Hareketsiz',   'Masa başı iş, egzersiz yok'),
          ('light',     'Hafif aktif',  'Haftada 1-3 gün egzersiz'),
          ('moderate',  'Orta aktif',   'Haftada 3-5 gün egzersiz'),
          ('very',      'Çok aktif',    'Haftada 6-7 gün egzersiz'),
          ('extra',     'Ekstra aktif', 'Günde 2x antrenman'),
        ],
        current: profile.activityLevel,
        onSelect: (val) async {
          // Kalori + su hedeflerini TDEE'ye göre yeniden hesapla ve state'i güncelle
          await ref.read(userProfileProvider.notifier).updateActivityLevel(val);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                'Aktivite güncellendi → kalori ve su hedefleri yeniden hesaplandı',
              ),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
      ),
    );
  }

  void _showDietPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _DietPickerSheet(
        vc: widget.vc,
        current: _diets,
        onSave: (selected) async {
          await LocalStorageService.instance.saveDietPreferences(selected);
          if (mounted) setState(() => _diets = selected);
        },
      ),
    );
  }

  void _showEditDialog(
    BuildContext context, {
    required String title,
    required String hint,
    required String initialValue,
    required TextInputType keyboardType,
    required void Function(String) onSave,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: Text('Kaydet',
                style: TextStyle(color: widget.vc.primary, fontWeight: FontWeight.w700)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

// ── Picker bottom sheets ──────────────────────────────────────────────────────

class _PickerSheet extends StatelessWidget {
  final VColors vc;
  final String title;
  final List<(String, String, String)> options;
  final String? current;
  final void Function(String) onSelect;

  const _PickerSheet({
    required this.vc,
    required this.title,
    required this.options,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: vc.border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(title,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: vc.text)),
          ),
          const SizedBox(height: 12),
          ...options.map((o) {
            final isSelected = current == o.$1;
            return GestureDetector(
              onTap: () {
                onSelect(o.$1);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? vc.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? vc.primary : vc.border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.$2,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? vc.primary : vc.text,
                              )),
                          Text(o.$3,
                              style: TextStyle(
                                  fontSize: 11, color: vc.textSub)),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_rounded, color: vc.primary, size: 18),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DietPickerSheet extends StatefulWidget {
  final VColors vc;
  final List<String> current;
  final void Function(List<String>) onSave;

  const _DietPickerSheet({
    required this.vc,
    required this.current,
    required this.onSave,
  });

  @override
  State<_DietPickerSheet> createState() => _DietPickerSheetState();
}

class _DietPickerSheetState extends State<_DietPickerSheet> {
  late Set<String> _selected;

  static const _options = [
    ('all',         '🍽️', 'Her şeyi yerim'),
    ('vegetarian',  '🥦', 'Vejeteryan'),
    ('vegan',       '🌱', 'Vegan'),
    ('gluten_free', '🌾', 'Glutensiz'),
    ('keto',        '🥑', 'Ketojenik'),
    ('low_carb',    '🥩', 'Düşük karbonhidrat'),
  ];

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.current.isEmpty ? ['all'] : widget.current);
  }

  @override
  Widget build(BuildContext context) {
    final vc = widget.vc;
    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: vc.border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Beslenme Tercihi',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: vc.text)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: vc.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Birden fazla seçilebilir',
                      style: TextStyle(fontSize: 11, color: vc.primary, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._options.map((o) {
            final isSelected = _selected.contains(o.$1);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (o.$1 == 'all') {
                    _selected = {'all'};
                  } else {
                    _selected.remove('all');
                    if (isSelected) {
                      _selected.remove(o.$1);
                      if (_selected.isEmpty) _selected = {'all'};
                    } else {
                      _selected.add(o.$1);
                    }
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? vc.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isSelected ? vc.primary : vc.border),
                ),
                child: Row(
                  children: [
                    Text(o.$2, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(o.$3,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? vc.primary : vc.text,
                        )),
                    const Spacer(),
                    if (isSelected)
                      Icon(Icons.check_rounded, color: vc.primary, size: 18),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(_selected.toList());
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: vc.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Kaydet',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Bildirim Ayarları Kartı ───────────────────────────────────────────────────

class _NotificationCard extends StatefulWidget {
  final VColors vc;
  const _NotificationCard({required this.vc});

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  late bool _waterEnabled;
  late int  _wakeHour;
  late int  _wakeMinute;
  late int  _sleepHour;
  late int  _sleepMinute;
  late bool _routineEnabled;
  late int  _routineHour;
  late int  _routineMinute;

  @override
  void initState() {
    super.initState();
    final s = LocalStorageService.instance;
    _waterEnabled   = s.waterNotifEnabled;
    _wakeHour       = s.wakeHour;
    _wakeMinute     = s.wakeMinute;
    _sleepHour      = s.sleepHour;
    _sleepMinute    = s.sleepMinute;
    _routineEnabled = s.routineNotifEnabled;
    _routineHour    = s.routineNotifHour;
    _routineMinute  = s.routineNotifMinute;
  }

  Future<void> _applyWater({bool? enabled}) async {
    final isEnabled = enabled ?? _waterEnabled;
    await LocalStorageService.instance.saveWaterNotifSettings(enabled: isEnabled);
    await LocalStorageService.instance.saveWakeSleepTime(
      wakeHour: _wakeHour,
      wakeMinute: _wakeMinute,
      sleepHour: _sleepHour,
      sleepMinute: _sleepMinute,
    );
    if (isEnabled) {
      await NotificationService.instance.requestPermission();
      NotificationService.instance.scheduleWaterRemindersForWindow(
        wakeHour: _wakeHour,
        wakeMinute: _wakeMinute,
        sleepHour: _sleepHour,
        sleepMinute: _sleepMinute,
      );
    } else {
      NotificationService.instance.cancelWaterReminders();
    }
  }

  Future<void> _applyRoutine(bool enabled, int hour, int minute) async {
    await LocalStorageService.instance.saveRoutineNotifSettings(
      enabled: enabled,
      hour: hour,
      minute: minute,
    );
    if (enabled) {
      await NotificationService.instance.requestPermission();
      NotificationService.instance.scheduleRoutineReminder(hour: hour, minute: minute);
    } else {
      NotificationService.instance.cancelRoutineReminder();
    }
  }

  Future<void> _showWakeTimePicker() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _wakeHour, minute: _wakeMinute),
      helpText: 'Kalkış Saati',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _wakeHour   = picked.hour;
      _wakeMinute = picked.minute;
    });
    _applyWater();
  }

  Future<void> _showSleepTimePicker() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _sleepHour, minute: _sleepMinute),
      helpText: 'Yatış Saati',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _sleepHour   = picked.hour;
      _sleepMinute = picked.minute;
    });
    _applyWater();
  }

  Future<void> _showRoutineTimePicker() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _routineHour, minute: _routineMinute),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _routineHour   = picked.hour;
      _routineMinute = picked.minute;
    });
    _applyRoutine(_routineEnabled, picked.hour, picked.minute);
  }

  String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  String _routineTimeLabel() => _fmt(_routineHour, _routineMinute);

  @override
  Widget build(BuildContext context) {
    final vc = widget.vc;
    return _Card(
      vc: vc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bildirimler',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: vc.text,
            ),
          ),
          const SizedBox(height: 4),
          // Su bildirimi toggle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: vc.waterSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.water_drop_rounded,
                      size: 18, color: AppColors.water),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Su Hatırlatıcısı',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: vc.text,
                          )),
                      Text('Günde 8 hatırlatma',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: vc.textSub,
                          )),
                    ],
                  ),
                ),
                Switch(
                  value: _waterEnabled,
                  onChanged: (v) {
                    setState(() => _waterEnabled = v);
                    _applyWater(enabled: v);
                  },
                ),
              ],
            ),
          ),
          if (_waterEnabled) ...[
            _SettingsRow(
              vc: vc,
              icon: Icons.wb_sunny_rounded,
              iconColor: const Color(0xFFF59E0B),
              iconBg: const Color(0xFFFEF3C7),
              label: 'Kalkış Saati',
              value: _fmt(_wakeHour, _wakeMinute),
              onTap: _showWakeTimePicker,
            ),
            _SettingsRow(
              vc: vc,
              icon: Icons.nights_stay_rounded,
              iconColor: const Color(0xFF6366F1),
              iconBg: const Color(0xFFEEF2FF),
              label: 'Yatış Saati',
              value: _fmt(_sleepHour, _sleepMinute),
              onTap: _showSleepTimePicker,
            ),
          ],
          Divider(height: 1, color: vc.border.withValues(alpha: 0.5)),
          // Rutin bildirimi toggle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: vc.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.checklist_rounded,
                      size: 18, color: vc.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Rutin Hatırlatıcısı',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: vc.text,
                      )),
                ),
                Switch(
                  value: _routineEnabled,
                  onChanged: (v) {
                    setState(() => _routineEnabled = v);
                    _applyRoutine(v, _routineHour, _routineMinute);
                  },
                ),
              ],
            ),
          ),
          if (_routineEnabled) ...[
            _SettingsRow(
              vc: vc,
              icon: Icons.access_time_rounded,
              iconColor: vc.primary,
              iconBg: vc.primarySurface,
              label: 'Hatırlatma Saati',
              value: _routineTimeLabel(),
              onTap: _showRoutineTimePicker,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Hakkında Kartı ────────────────────────────────────────────────────────────

// ── Hakkında Kartı ────────────────────────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  final VColors vc;
  const _AboutCard({required this.vc});

  @override
  Widget build(BuildContext context) {
    return _Card(
      vc: vc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hakkında',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: vc.text,
            ),
          ),
          const SizedBox(height: 4),
          _SettingsRow(
            vc: vc,
            icon: Icons.info_outline_rounded,
            iconColor: vc.primary,
            iconBg: vc.primarySurface,
            label: 'Sürüm',
            value: '1.0.0',
          ),
          Divider(height: 1, color: vc.border.withValues(alpha: 0.5)),
          _SettingsRow(
            vc: vc,
            icon: Icons.shield_outlined,
            iconColor: vc.primary,
            iconBg: vc.primarySurface,
            label: 'Gizlilik Politikası',
            trailing: Icon(Icons.chevron_right_rounded,
                color: vc.textMuted, size: 20),
            onTap: () => Navigator.of(context).pushNamed('/privacy'),
          ),
          Divider(height: 1, color: vc.border.withValues(alpha: 0.5)),
          _SettingsRow(
            vc: vc,
            icon: Icons.description_outlined,
            iconColor: vc.primary,
            iconBg: vc.primarySurface,
            label: 'Kullanım Koşulları',
            trailing: Icon(Icons.chevron_right_rounded,
                color: vc.textMuted, size: 20),
            onTap: () => Navigator.of(context).pushNamed('/terms'),
          ),
        ],
      ),
    );
  }
}

// ── Settings Row ──────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final VColors vc;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.vc,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: vc.text,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: vc.textSub,
                ),
              ),
            if (onTap != null && trailing == null)
              Icon(Icons.edit_outlined, size: 16, color: vc.textMuted),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ── Geliştirici Kartı (sadece debug) ──────────────────────────────────────────

class _DevCard extends StatelessWidget {
  final bool isPremium;
  final WidgetRef ref;
  final VColors vc;
  const _DevCard({required this.isPremium, required this.ref, required this.vc});

  @override
  Widget build(BuildContext context) {
    return _Card(
      vc: vc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.code_rounded,
                    size: 18, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Text(
                'Geliştirici Modu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: vc.text,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('DEBUG',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: vc.border.withValues(alpha: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_rounded,
                      size: 18, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Test Premium',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: vc.text,
                          )),
                      Text('Sadece bu oturumda geçerli',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: vc.textSub,
                          )),
                    ],
                  ),
                ),
                Switch(
                  value: isPremium,
                  onChanged: (v) =>
                      ref.read(isPremiumProvider.notifier).setDev(v),
                  activeThumbColor: Colors.purple,
                  activeTrackColor: Colors.purple.withValues(alpha: 0.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kart Wrapper ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final VColors vc;
  const _Card({required this.child, required this.vc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: vc.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: vc.primary.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
