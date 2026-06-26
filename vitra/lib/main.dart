import 'dart:ui';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/local_storage_service.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/v_theme.dart';
import 'core/providers/theme_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/premium/paywall_screen.dart';
import 'features/legal/legal_pages.dart';
import 'core/services/premium_service.dart';
import 'core/services/ad_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics — production'da tüm hataları yakala
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // App Check — debug ya da --dart-define=DEBUG_APP_CHECK=true ile debug provider
  const _debugAppCheck = bool.fromEnvironment('DEBUG_APP_CHECK', defaultValue: kDebugMode);
  await FirebaseAppCheck.instance.activate(
    androidProvider: _debugAppCheck
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: _debugAppCheck
        ? AppleProvider.debug
        : AppleProvider.appAttest,
  );


  // Analytics — session takibi
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);

  await LocalStorageService.instance.init();
  await LocalStorageService.instance.ensureFirstUseDateSaved();
  await PremiumService.instance.init();
  await AdService.instance.init();
  await NotificationService.instance.init();
  _scheduleNotifications();
  runApp(const ProviderScope(child: VitraApp()));
}

/// Kayıtlı ayarlara göre bildirimleri planlar.
void _scheduleNotifications() {
  final storage = LocalStorageService.instance;
  final notif   = NotificationService.instance;

  if (storage.waterNotifEnabled) {
    notif.scheduleWaterReminders(intervalHours: storage.waterNotifInterval);
  } else {
    notif.cancelWaterReminders();
  }

  if (storage.routineNotifEnabled) {
    notif.scheduleRoutineReminder(
      hour:   storage.routineNotifHour,
      minute: storage.routineNotifMinute,
    );
  } else {
    notif.cancelRoutineReminder();
  }
}

class VitraApp extends ConsumerWidget {
  const VitraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitraTheme = ref.watch(themeProvider);
    final themeData  = VThemeBuilder.build(vitraTheme);
    final isDark     = vitraTheme.colors.isDark;

    return MaterialApp(
      title: 'Vitra',
      debugShowCheckedModeBanner: false,
      theme:     themeData,
      darkTheme: themeData,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/onboarding/flow': (context) => const OnboardingFlow(),
        '/onboarding/complete': (context) => const AuthScreen(),
        '/auth': (context) => const AuthScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/premium':  (context) => const PaywallScreen(),
        '/privacy':  (context) => const PrivacyPolicyPage(),
        '/terms':    (context) => const TermsOfUsePage(),
      },
    );
  }
}
