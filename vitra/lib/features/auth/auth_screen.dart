import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/providers/daily_log_provider.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/providers/premium_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/theme/v_theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _showEmailForm = false;
  bool _isLogin       = true;
  bool _loading       = false;

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Provider Sıfırlama ────────────────────────────────────────────────────

  void _invalidateProviders() {
    ref.invalidate(dailyLogProvider);
    ref.invalidate(userProfileProvider);
    ref.invalidate(aiUsageProvider);
    ref.invalidate(selectedTabIndexProvider);
  }

  // ── Giriş Sonrası Akıllı Yönlendirme ─────────────────────────────────────

  Future<void> _navigateAfterSignIn() async {
    await LocalStorageService.instance.clearGuestDataBackup();
    _invalidateProviders();
    if (!mounted) return;
    final storage = LocalStorageService.instance;
    if (storage.calorieGoal > 0 && storage.waterGoalMl > 0) {
      Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (_) => false);
      return;
    }
    try {
      final remote = await FirestoreService.instance.fetchProfile()
          .timeout(const Duration(seconds: 5));
      if (remote != null) {
        final rc = (remote['calorieGoal'] as int?) ?? 0;
        final rw = (remote['waterGoalMl'] as int?) ?? 0;
        if (rc > 0 && rw > 0) {
          final rn = (remote['userName'] as String?) ?? '';
          await storage.saveOnboardingResult(
            calorieGoal: rc,
            waterGoalMl: rw,
            userName: rn.isNotEmpty ? rn : null,
          );
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (_) => false);
          return;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/onboarding/flow', (_) => false);
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _handleGoogle() async {
    setState(() => _loading = true);
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: '662245475057-4r5j4uoirk8v57ht5p1drp9dnhp1ev8d.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google kimlik doğrulaması alınamadı. Tekrar deneyin.')),
        );
        return;
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );
      final previousUid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseAuth.instance.signInWithCredential(credential);
      final newUid = FirebaseAuth.instance.currentUser?.uid;
      if (previousUid != newUid) {
        await LocalStorageService.instance.clearUserData();
        await LocalStorageService.instance.resetOnboardingAndGoals();
      }
      await LocalStorageService.instance.saveLastLoginMethod('google');
      if (!mounted) return;
      await _navigateAfterSignIn();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = switch (e.code) {
        'account-exists-with-different-credential' =>
            'Bu e-posta başka bir yöntemle kayıtlı.',
        'network-request-failed' => 'İnternet bağlantısı yok.',
        _                        => 'Hata: ${e.code} - ${e.message}',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 10)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Google girişi sırasında hata oluştu.')));
    }
  }

  Future<void> _handlePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final previousUid = FirebaseAuth.instance.currentUser?.uid;
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email:    _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email:    _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
        await FirebaseAuth.instance.currentUser
            ?.sendEmailVerification()
            .catchError((_) => null);
      }
      final newUid = FirebaseAuth.instance.currentUser?.uid;
      if (previousUid != newUid) {
        await LocalStorageService.instance.clearUserData();
        await LocalStorageService.instance.resetOnboardingAndGoals();
      }
      await LocalStorageService.instance.saveLastLoginMethod('email');
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        final msg = _isLogin
            ? 'E-postanız doğrulanmamış.'
            : 'Doğrulama e-postası gönderildi. Lütfen e-postanızı kontrol edin.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 5),
          action: _isLogin
              ? SnackBarAction(
                  label: 'Tekrar Gönder',
                  onPressed: () =>
                      user.sendEmailVerification().catchError((_) => null),
                )
              : null,
        ));
      }

      await _navigateAfterSignIn();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = switch (e.code) {
        'user-not-found'            => 'Bu e-posta ile kayıtlı hesap bulunamadı.',
        'wrong-password'            => 'Şifre hatalı.',
        'invalid-credential'        => 'E-posta veya şifre hatalı.',
        'invalid-login-credentials' => 'E-posta veya şifre hatalı.',
        'email-already-in-use'      => 'Bu e-posta zaten kullanımda.',
        'weak-password'             => 'Şifre çok zayıf. En az 6 karakter girin.',
        'invalid-email'             => 'Geçersiz e-posta adresi.',
        'too-many-requests'         => 'Çok fazla deneme. Birkaç dakika bekleyin.',
        'network-request-failed'    => 'İnternet bağlantısı yok.',
        'user-disabled'             => 'Bu hesap devre dışı bırakılmış.',
        _                           => 'Giriş yapılamadı. Lütfen tekrar deneyin.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Giriş yapılamadı. Lütfen tekrar deneyin.')));
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Önce e-posta adresinizi girin.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Şifre sıfırlama e-postası $email adresine gönderildi.')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('E-posta gönderilemedi. Lütfen tekrar deneyin.')));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final canGoBack = Navigator.canPop(context);
    final args = ModalRoute.of(context)?.settings.arguments;
    final sessionExpired = args is Map && args['sessionExpired'] == true;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: vc.bg,
      body: Stack(
        children: [
          // Gradient arka plan
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF0A1628),
                          vc.bg,
                          vc.bg,
                        ]
                      : [
                          vc.primary.withValues(alpha: 0.06),
                          vc.bg,
                          vc.bg,
                        ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          // Aurora glow — sağ üst
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    vc.primary.withValues(alpha: isDark ? 0.18 : 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // İçerik
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sessionExpired)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: vc.primarySurface,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: vc.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Oturumun sona erdi. Devam etmek için tekrar giriş yap.',
                            style: TextStyle(
                              fontSize: 13,
                              color: vc.text.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (canGoBack || _showEmailForm)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20, color: vc.textSub),
                      onPressed: () {
                        if (_showEmailForm) {
                          setState(() => _showEmailForm = false);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildLogo(),
                        if (!_showEmailForm) ...[
                          const SizedBox(height: 32),
                          _buildFeatureTeasers(),
                          const SizedBox(height: 32),
                          _buildMainButtons(),
                          const SizedBox(height: 20),
                          _buildTrustBadge(),
                        ] else ...[
                          const SizedBox(height: 40),
                          _buildPasswordForm(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTeasers() {
    final vc = context.vt;
    const features = [
      (Icons.bolt_rounded,        '0xFF14C2A8', 'AI Kalori Analizi',   'Yemeğin adını yaz, kalorisi otomatik dolsun'),
      (Icons.insights_rounded,    '0xFF6366F1', 'Akıllı İstatistikler','Kilo, kalori ve egzersiz trendlerini takip et'),
      (Icons.self_improvement_rounded, '0xFFF59E0B', 'Kişisel Koç',   'Hedefine özel günlük tavsiyeler al'),
    ];

    return Column(
      children: features.map((f) {
        final color = Color(int.parse(f.$2));
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: vc.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: vc.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(f.$1, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.$3,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: vc.text,
                        )),
                    const SizedBox(height: 2),
                    Text(f.$4,
                        style: TextStyle(
                          fontSize: 12,
                          color: vc.textMuted,
                        )),
                  ],
                ),
              ),
              Icon(Icons.check_circle_rounded, color: color, size: 18),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrustBadge() {
    final vc = context.vt;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 14, color: vc.textMuted),
        const SizedBox(width: 6),
        Text(
          'Verilerinin güvenliği Firebase ile korunuyor',
          style: TextStyle(fontSize: 12, color: vc.textMuted),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    final vc = context.vt;
    return Column(
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [vc.primary, vc.primaryGlow],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: vc.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.spa_rounded, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Vitra\'ya hoş geldin',
          style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w700,
            color: vc.text, letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hesabınla verilerini her cihazda\nkullanmaya devam et.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: vc.textSub, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildMainButtons() {
    final vc = context.vt;
    return Column(
      children: [
        _SocialButton(
          onTap: _loading ? null : _handleGoogle,
          loading: _loading,
          icon: _googleIcon(),
          label: 'Google ile giriş yap',
        ),
        const SizedBox(height: 12),
        _SocialButton(
          onTap: () => setState(() => _showEmailForm = true),
          icon: Icon(Icons.email_outlined, size: 22, color: vc.text),
          label: 'E-posta ile giriş yap',
          outlined: true,
        ),
      ],
    );
  }

  Widget _buildPasswordForm() {
    final vc = context.vt;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TabButton(
                label: 'Giriş Yap',
                active: _isLogin,
                onTap: () => setState(() => _isLogin = true),
              ),
              const SizedBox(width: 8),
              _TabButton(
                label: 'Kayıt Ol',
                active: !_isLogin,
                onTap: () => setState(() => _isLogin = false),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _AuthField(
            controller: _emailCtrl,
            label: 'E-posta',
            hint: 'ornek@mail.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'E-posta gerekli';
              if (!v.contains('@')) return 'Geçerli bir e-posta girin';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _AuthField(
            controller: _passwordCtrl,
            label: 'Şifre',
            hint: '••••••••',
            obscure: true,
            validator: (v) {
              if (v == null || v.length < 6) return 'En az 6 karakter';
              return null;
            },
          ),
          if (_isLogin) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _loading ? null : _handleForgotPassword,
                child: Text(
                  'Şifremi Unuttum',
                  style: TextStyle(
                    fontSize: 13, color: vc.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _handlePassword,
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _showEmailForm = false),
              child: Text(
                '← Geri dön',
                style: TextStyle(fontSize: 13, color: vc.textSub),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _googleIcon() {
    return Container(
      width: 22, height: 22,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      child: const Center(
        child: Text('G', style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
        )),
      ),
    );
  }
}

// ── Alt bileşenler ────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget icon;
  final String label;
  final bool outlined;
  final bool loading;

  const _SocialButton({
    required this.onTap,
    required this.icon,
    required this.label,
    this.outlined = false,
    this.loading  = false,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 54,
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : vc.primary,
          borderRadius: BorderRadius.circular(14),
          border: outlined ? Border.all(color: vc.border, width: 1.5) : null,
          boxShadow: outlined ? null : [
            BoxShadow(
              color: vc.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: outlined ? vc.text : Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? vc.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: active ? Colors.white : vc.textSub,
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure      = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: vc.textSub,
        )),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(fontSize: 15, color: vc.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: vc.textMuted),
            filled: true,
            fillColor: vc.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: vc.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: vc.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
