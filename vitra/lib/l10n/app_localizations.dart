import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appName.
  ///
  /// In tr, this message translates to:
  /// **'Vitra'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In tr, this message translates to:
  /// **'wellness. elevated.'**
  String get appTagline;

  /// No description provided for @splashTagline.
  ///
  /// In tr, this message translates to:
  /// **'wellness. elevated.'**
  String get splashTagline;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hoş Geldin'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sağlıklı bir yaşam için su takibin, öğünlerin ve günlük rutinlerin tek bir yerde.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingWelcomeCta.
  ///
  /// In tr, this message translates to:
  /// **'Başlayalım'**
  String get onboardingWelcomeCta;

  /// No description provided for @onboardingAlreadyHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabım var'**
  String get onboardingAlreadyHaveAccount;

  /// No description provided for @onboardingGoalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedefin ne?'**
  String get onboardingGoalTitle;

  /// No description provided for @onboardingGoalSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sana özel bir plan oluşturalım.'**
  String get onboardingGoalSubtitle;

  /// No description provided for @onboardingGoalLoseWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo vermek'**
  String get onboardingGoalLoseWeight;

  /// No description provided for @onboardingGoalGainMuscle.
  ///
  /// In tr, this message translates to:
  /// **'Kas kazanmak'**
  String get onboardingGoalGainMuscle;

  /// No description provided for @onboardingGoalStayHealthy.
  ///
  /// In tr, this message translates to:
  /// **'Sağlıklı kalmak'**
  String get onboardingGoalStayHealthy;

  /// No description provided for @onboardingGoalEatBetter.
  ///
  /// In tr, this message translates to:
  /// **'Daha iyi beslenme'**
  String get onboardingGoalEatBetter;

  /// No description provided for @onboardingGoalDrinkMore.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla su içmek'**
  String get onboardingGoalDrinkMore;

  /// No description provided for @onboardingGoalBuildHabits.
  ///
  /// In tr, this message translates to:
  /// **'Alışkanlık oluşturmak'**
  String get onboardingGoalBuildHabits;

  /// No description provided for @onboardingLifestyleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yaşam tarzın nasıl?'**
  String get onboardingLifestyleTitle;

  /// No description provided for @onboardingLifestyleSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük su ve kalori hedefini buna göre ayarlayalım.'**
  String get onboardingLifestyleSubtitle;

  /// No description provided for @onboardingLifestyleSedentary.
  ///
  /// In tr, this message translates to:
  /// **'Hareketsiz'**
  String get onboardingLifestyleSedentary;

  /// No description provided for @onboardingLifestyleSedentaryDesc.
  ///
  /// In tr, this message translates to:
  /// **'Masabaşı çalışıyorum, az hareket'**
  String get onboardingLifestyleSedentaryDesc;

  /// No description provided for @onboardingLifestyleLight.
  ///
  /// In tr, this message translates to:
  /// **'Hafif aktif'**
  String get onboardingLifestyleLight;

  /// No description provided for @onboardingLifestyleLightDesc.
  ///
  /// In tr, this message translates to:
  /// **'Haftada 1-3 gün egzersiz'**
  String get onboardingLifestyleLightDesc;

  /// No description provided for @onboardingLifestyleModerate.
  ///
  /// In tr, this message translates to:
  /// **'Orta aktif'**
  String get onboardingLifestyleModerate;

  /// No description provided for @onboardingLifestyleModerateDesc.
  ///
  /// In tr, this message translates to:
  /// **'Haftada 3-5 gün egzersiz'**
  String get onboardingLifestyleModerateDesc;

  /// No description provided for @onboardingLifestyleVery.
  ///
  /// In tr, this message translates to:
  /// **'Çok aktif'**
  String get onboardingLifestyleVery;

  /// No description provided for @onboardingLifestyleVeryDesc.
  ///
  /// In tr, this message translates to:
  /// **'Haftada 6-7 gün yoğun antrenman'**
  String get onboardingLifestyleVeryDesc;

  /// No description provided for @onboardingWaterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük su hedefin?'**
  String get onboardingWaterTitle;

  /// No description provided for @onboardingWaterSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen hedef {amount} litre.'**
  String onboardingWaterSubtitle(String amount);

  /// No description provided for @onboardingRoutineTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hangi rutinleri takip etmek istiyorsun?'**
  String get onboardingRoutineTitle;

  /// No description provided for @onboardingRoutineSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İstediğin zaman değiştirebilirsin.'**
  String get onboardingRoutineSubtitle;

  /// No description provided for @routineMeditation.
  ///
  /// In tr, this message translates to:
  /// **'Meditasyon'**
  String get routineMeditation;

  /// No description provided for @routineExercise.
  ///
  /// In tr, this message translates to:
  /// **'Egzersiz'**
  String get routineExercise;

  /// No description provided for @routineSleep.
  ///
  /// In tr, this message translates to:
  /// **'Uyku düzeni'**
  String get routineSleep;

  /// No description provided for @routineReading.
  ///
  /// In tr, this message translates to:
  /// **'Okuma'**
  String get routineReading;

  /// No description provided for @routineNoPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon molası'**
  String get routineNoPhone;

  /// No description provided for @routineVitamins.
  ///
  /// In tr, this message translates to:
  /// **'Vitamin/ilaç'**
  String get routineVitamins;

  /// No description provided for @routineStretch.
  ///
  /// In tr, this message translates to:
  /// **'Esneme'**
  String get routineStretch;

  /// No description provided for @routineColdShower.
  ///
  /// In tr, this message translates to:
  /// **'Soğuk duş'**
  String get routineColdShower;

  /// No description provided for @onboardingNotificationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcılar açık olsun mu?'**
  String get onboardingNotificationTitle;

  /// No description provided for @onboardingNotificationSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Su içme ve rutin hatırlatmaları için bildirimler.'**
  String get onboardingNotificationSubtitle;

  /// No description provided for @onboardingNotificationEnable.
  ///
  /// In tr, this message translates to:
  /// **'Evet, açık kalsın'**
  String get onboardingNotificationEnable;

  /// No description provided for @onboardingNotificationSkip.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi değil'**
  String get onboardingNotificationSkip;

  /// No description provided for @onboardingPremiumTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vitra Premium'**
  String get onboardingPremiumTitle;

  /// No description provided for @onboardingPremiumSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'AI fotoğraf analizi, sınırsız istatistik ve daha fazlası.'**
  String get onboardingPremiumSubtitle;

  /// No description provided for @onboardingPremiumFeature1.
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız AI yemek analizi'**
  String get onboardingPremiumFeature1;

  /// No description provided for @onboardingPremiumFeature2.
  ///
  /// In tr, this message translates to:
  /// **'30 ve 90 günlük istatistikler'**
  String get onboardingPremiumFeature2;

  /// No description provided for @onboardingPremiumFeature3.
  ///
  /// In tr, this message translates to:
  /// **'Öncelikli destek'**
  String get onboardingPremiumFeature3;

  /// No description provided for @onboardingPremiumCta.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz dene'**
  String get onboardingPremiumCta;

  /// No description provided for @onboardingPremiumSkip.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz devam et'**
  String get onboardingPremiumSkip;

  /// No description provided for @buttonNext.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get buttonNext;

  /// No description provided for @buttonBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get buttonBack;

  /// No description provided for @buttonSkip.
  ///
  /// In tr, this message translates to:
  /// **'Atla'**
  String get buttonSkip;

  /// No description provided for @buttonDone.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get buttonDone;

  /// No description provided for @buttonSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get buttonSave;

  /// No description provided for @buttonCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get buttonCancel;

  /// No description provided for @authSignIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get authSignUp;

  /// No description provided for @authEmail.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get authPassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi unuttum'**
  String get authForgotPassword;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In tr, this message translates to:
  /// **'Misafir olarak devam et'**
  String get authContinueAsGuest;

  /// No description provided for @authOrContinueWith.
  ///
  /// In tr, this message translates to:
  /// **'veya şununla devam et'**
  String get authOrContinueWith;

  /// No description provided for @authGoogleSignIn.
  ///
  /// In tr, this message translates to:
  /// **'Google ile giriş yap'**
  String get authGoogleSignIn;

  /// No description provided for @authAppleSignIn.
  ///
  /// In tr, this message translates to:
  /// **'Apple ile giriş yap'**
  String get authAppleSignIn;

  /// No description provided for @dashboardGreetingMorning.
  ///
  /// In tr, this message translates to:
  /// **'Günaydın'**
  String get dashboardGreetingMorning;

  /// No description provided for @dashboardGreetingAfternoon.
  ///
  /// In tr, this message translates to:
  /// **'İyi öğleden sonralar'**
  String get dashboardGreetingAfternoon;

  /// No description provided for @dashboardGreetingEvening.
  ///
  /// In tr, this message translates to:
  /// **'İyi akşamlar'**
  String get dashboardGreetingEvening;

  /// No description provided for @dashboardTodayProgress.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü ilerleme'**
  String get dashboardTodayProgress;

  /// No description provided for @dashboardWater.
  ///
  /// In tr, this message translates to:
  /// **'Su'**
  String get dashboardWater;

  /// No description provided for @dashboardCalories.
  ///
  /// In tr, this message translates to:
  /// **'Kalori'**
  String get dashboardCalories;

  /// No description provided for @dashboardRoutines.
  ///
  /// In tr, this message translates to:
  /// **'Rutin'**
  String get dashboardRoutines;

  /// No description provided for @waterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Su Takibi'**
  String get waterTitle;

  /// No description provided for @waterGoal.
  ///
  /// In tr, this message translates to:
  /// **'{current} / {goal} ml'**
  String waterGoal(int current, int goal);

  /// No description provided for @waterAddQuick.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Ekle'**
  String get waterAddQuick;

  /// No description provided for @waterAddCustom.
  ///
  /// In tr, this message translates to:
  /// **'Özel Miktar'**
  String get waterAddCustom;

  /// No description provided for @waterHistory.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü Su'**
  String get waterHistory;

  /// No description provided for @mealTitle.
  ///
  /// In tr, this message translates to:
  /// **'Öğün Takibi'**
  String get mealTitle;

  /// No description provided for @mealBreakfast.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In tr, this message translates to:
  /// **'Öğle'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In tr, this message translates to:
  /// **'Akşam'**
  String get mealDinner;

  /// No description provided for @mealSnack.
  ///
  /// In tr, this message translates to:
  /// **'Ara Öğün'**
  String get mealSnack;

  /// No description provided for @mealAddPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğrafla Analiz Et'**
  String get mealAddPhoto;

  /// No description provided for @mealAddManual.
  ///
  /// In tr, this message translates to:
  /// **'Manuel Ekle'**
  String get mealAddManual;

  /// No description provided for @routineTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rutinlerim'**
  String get routineTitle;

  /// No description provided for @routineStreak.
  ///
  /// In tr, this message translates to:
  /// **'{count} günlük seri'**
  String routineStreak(int count);

  /// No description provided for @routineCompleted.
  ///
  /// In tr, this message translates to:
  /// **'{done}/{total} tamamlandı'**
  String routineCompleted(int done, int total);

  /// No description provided for @statsTitle.
  ///
  /// In tr, this message translates to:
  /// **'İstatistikler'**
  String get statsTitle;

  /// No description provided for @stats7Days.
  ///
  /// In tr, this message translates to:
  /// **'7 Gün'**
  String get stats7Days;

  /// No description provided for @stats30Days.
  ///
  /// In tr, this message translates to:
  /// **'30 Gün'**
  String get stats30Days;

  /// No description provided for @stats90Days.
  ///
  /// In tr, this message translates to:
  /// **'90 Gün'**
  String get stats90Days;

  /// No description provided for @statsPremiumRequired.
  ///
  /// In tr, this message translates to:
  /// **'Premium üyelik gerekiyor'**
  String get statsPremiumRequired;

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @settingsProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get settingsProfile;

  /// No description provided for @settingsGoals.
  ///
  /// In tr, this message translates to:
  /// **'Hedefler'**
  String get settingsGoals;

  /// No description provided for @settingsNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get settingsNotifications;

  /// No description provided for @settingsPremium.
  ///
  /// In tr, this message translates to:
  /// **'Premium'**
  String get settingsPremium;

  /// No description provided for @settingsLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get settingsLanguage;

  /// No description provided for @settingsSignOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get settingsSignOut;

  /// No description provided for @premiumTitle.
  ///
  /// In tr, this message translates to:
  /// **'Premium\'a Geç'**
  String get premiumTitle;

  /// No description provided for @premiumWeekly.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık'**
  String get premiumWeekly;

  /// No description provided for @premiumMonthly.
  ///
  /// In tr, this message translates to:
  /// **'Aylık'**
  String get premiumMonthly;

  /// No description provided for @premiumYearly.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık'**
  String get premiumYearly;

  /// No description provided for @premiumBestValue.
  ///
  /// In tr, this message translates to:
  /// **'En iyi değer'**
  String get premiumBestValue;

  /// No description provided for @premiumRestore.
  ///
  /// In tr, this message translates to:
  /// **'Satın almayı geri yükle'**
  String get premiumRestore;

  /// No description provided for @premiumFreeTrial.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün ücretsiz dene'**
  String premiumFreeTrial(int days);

  /// No description provided for @errorGeneral.
  ///
  /// In tr, this message translates to:
  /// **'Bir şeyler ters gitti. Tekrar dene.'**
  String get errorGeneral;

  /// No description provided for @errorNoInternet.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok'**
  String get errorNoInternet;

  /// No description provided for @errorRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get errorRetry;

  /// No description provided for @emptyStateNoData.
  ///
  /// In tr, this message translates to:
  /// **'Henüz veri yok'**
  String get emptyStateNoData;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
