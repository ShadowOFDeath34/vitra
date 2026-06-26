import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/v_theme.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/firestore_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _orbCtrl;

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _taglineAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _orbAnim;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _fadeAnim = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnim = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _taglineAnim = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(_glowCtrl);
    _orbAnim  = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(_orbCtrl);

    _mainCtrl.forward();

    Future.delayed(const Duration(milliseconds: 2600), _navigate);
  }

  /// Firebase Auth session'ı kaybettiyse Google hesabıyla yeniden auth dene.
  /// Google hesabı cihazda kayıtlı olduğu sürece kullanıcıya picker gösterilmez.
  Future<User?> _recoverGoogleSession() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signInSilently();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );
      final result = await FirebaseAuth.instance
          .signInWithCredential(credential);
      return result.user;
    } catch (_) {
      return null;
    }
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final storage = LocalStorageService.instance;
    final nav     = Navigator.of(context);

    User? user = FirebaseAuth.instance.currentUser;

    // Firebase Auth session'ı kaybettiyse (EncryptedSharedPreferences sorunu)
    // Google hesabı cihazda varsa sessizce yeniden bağlan.
    if (user == null && (storage.calorieGoal > 0 || storage.isOnboardingComplete)) {
      user = await _recoverGoogleSession().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
    }

    // Email/password kullanıcısı için session kaybında auth ekranına yönlendir
    if (user == null &&
        (storage.calorieGoal > 0 || storage.isOnboardingComplete) &&
        storage.lastLoginMethod == 'email') {
      if (!mounted) return;
      nav.pushReplacementNamed('/auth', arguments: {'sessionExpired': true});
      return;
    }

    if (user != null) {
      var calorieGoal = storage.calorieGoal;
      var waterGoalMl = storage.waterGoalMl;

      if (calorieGoal == 0 || waterGoalMl == 0) {
        try {
          final remote = await FirestoreService.instance
              .fetchProfile()
              .timeout(const Duration(seconds: 5));
          if (remote != null) {
            final rc = (remote['calorieGoal'] as int?) ?? 0;
            final rw = (remote['waterGoalMl'] as int?) ?? 0;
            final rn = (remote['userName']    as String?) ?? '';
            if (rc > 0 && rw > 0) {
              await storage.saveOnboardingResult(
                calorieGoal: rc,
                waterGoalMl: rw,
                userName: rn.isNotEmpty ? rn : null,
              );
              calorieGoal = rc;
              waterGoalMl = rw;
            }
          }
        } catch (_) {}
      }

      if (!mounted) return;
      if (calorieGoal > 0 && waterGoalMl > 0) {
        nav.pushReplacementNamed('/dashboard');
      } else {
        nav.pushReplacementNamed('/onboarding/flow');
      }
      return;
    }

    nav.pushReplacementNamed('/onboarding');
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _glowCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Scaffold(
      backgroundColor: vc.bg,
      body: Stack(
        children: [
          // Arka plan ambient ışınlar
          _AmbientBackground(orbAnim: _orbAnim),

          // Ana içerik
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: AnimatedBuilder(
                animation: _mainCtrl,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo glow çemberi
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (context, _) {
                        final vc2 = context.vt;
                        return Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                vc2.primarySurface,
                                vc2.bg,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: vc2.primary
                                    .withValues(alpha: 0.25 * _glowAnim.value),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                              BoxShadow(
                                color: vc2.primary
                                    .withValues(alpha: 0.12 * _glowAnim.value),
                                blurRadius: 100,
                                spreadRadius: 40,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    vc2.primary,
                                    vc2.primaryGlow,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: vc2.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.spa_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // Marka adı
                    Text(
                      'Vitra',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: vc.text,
                        letterSpacing: -2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tagline — gecikmeli fade
                    FadeTransition(
                      opacity: _taglineAnim,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 1,
                            color: vc.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'wellness. elevated.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: vc.textMuted,
                              letterSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 28,
                            height: 1,
                            color: vc.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Alt köşe — altın nokta
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _taglineAnim,
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ambient arka plan ışınları ───────────────────────────────────────────────

class _AmbientBackground extends StatelessWidget {
  final Animation<double> orbAnim;
  const _AmbientBackground({required this.orbAnim});

  @override
  Widget build(BuildContext context) {
    final vc   = context.vt;
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: orbAnim,
      builder: (context, _) {
        final t = orbAnim.value / (2 * math.pi);
        return Stack(
          children: [
            // Teal orb — sol üst
            Positioned(
              top: size.height * 0.1 + math.sin(t * 2 * math.pi) * 20,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      vc.primary.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Indigo orb — sağ alt
            Positioned(
              bottom: size.height * 0.1 + math.cos(t * 2 * math.pi) * 20,
              right: -100,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.coach.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
