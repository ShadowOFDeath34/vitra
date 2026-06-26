// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Vitra';

  @override
  String get appTagline => 'wellness. elevated.';

  @override
  String get splashTagline => 'wellness. elevated.';

  @override
  String get onboardingWelcomeTitle => 'Hoş Geldin';

  @override
  String get onboardingWelcomeSubtitle =>
      'Sağlıklı bir yaşam için su takibin, öğünlerin ve günlük rutinlerin tek bir yerde.';

  @override
  String get onboardingWelcomeCta => 'Başlayalım';

  @override
  String get onboardingAlreadyHaveAccount => 'Zaten hesabım var';

  @override
  String get onboardingGoalTitle => 'Hedefin ne?';

  @override
  String get onboardingGoalSubtitle => 'Sana özel bir plan oluşturalım.';

  @override
  String get onboardingGoalLoseWeight => 'Kilo vermek';

  @override
  String get onboardingGoalGainMuscle => 'Kas kazanmak';

  @override
  String get onboardingGoalStayHealthy => 'Sağlıklı kalmak';

  @override
  String get onboardingGoalEatBetter => 'Daha iyi beslenme';

  @override
  String get onboardingGoalDrinkMore => 'Daha fazla su içmek';

  @override
  String get onboardingGoalBuildHabits => 'Alışkanlık oluşturmak';

  @override
  String get onboardingLifestyleTitle => 'Yaşam tarzın nasıl?';

  @override
  String get onboardingLifestyleSubtitle =>
      'Günlük su ve kalori hedefini buna göre ayarlayalım.';

  @override
  String get onboardingLifestyleSedentary => 'Hareketsiz';

  @override
  String get onboardingLifestyleSedentaryDesc =>
      'Masabaşı çalışıyorum, az hareket';

  @override
  String get onboardingLifestyleLight => 'Hafif aktif';

  @override
  String get onboardingLifestyleLightDesc => 'Haftada 1-3 gün egzersiz';

  @override
  String get onboardingLifestyleModerate => 'Orta aktif';

  @override
  String get onboardingLifestyleModerateDesc => 'Haftada 3-5 gün egzersiz';

  @override
  String get onboardingLifestyleVery => 'Çok aktif';

  @override
  String get onboardingLifestyleVeryDesc => 'Haftada 6-7 gün yoğun antrenman';

  @override
  String get onboardingWaterTitle => 'Günlük su hedefin?';

  @override
  String onboardingWaterSubtitle(String amount) {
    return 'Önerilen hedef $amount litre.';
  }

  @override
  String get onboardingRoutineTitle =>
      'Hangi rutinleri takip etmek istiyorsun?';

  @override
  String get onboardingRoutineSubtitle => 'İstediğin zaman değiştirebilirsin.';

  @override
  String get routineMeditation => 'Meditasyon';

  @override
  String get routineExercise => 'Egzersiz';

  @override
  String get routineSleep => 'Uyku düzeni';

  @override
  String get routineReading => 'Okuma';

  @override
  String get routineNoPhone => 'Telefon molası';

  @override
  String get routineVitamins => 'Vitamin/ilaç';

  @override
  String get routineStretch => 'Esneme';

  @override
  String get routineColdShower => 'Soğuk duş';

  @override
  String get onboardingNotificationTitle => 'Hatırlatıcılar açık olsun mu?';

  @override
  String get onboardingNotificationSubtitle =>
      'Su içme ve rutin hatırlatmaları için bildirimler.';

  @override
  String get onboardingNotificationEnable => 'Evet, açık kalsın';

  @override
  String get onboardingNotificationSkip => 'Şimdi değil';

  @override
  String get onboardingPremiumTitle => 'Vitra Premium';

  @override
  String get onboardingPremiumSubtitle =>
      'AI fotoğraf analizi, sınırsız istatistik ve daha fazlası.';

  @override
  String get onboardingPremiumFeature1 => 'Sınırsız AI yemek analizi';

  @override
  String get onboardingPremiumFeature2 => '30 ve 90 günlük istatistikler';

  @override
  String get onboardingPremiumFeature3 => 'Öncelikli destek';

  @override
  String get onboardingPremiumCta => 'Ücretsiz dene';

  @override
  String get onboardingPremiumSkip => 'Ücretsiz devam et';

  @override
  String get buttonNext => 'Devam';

  @override
  String get buttonBack => 'Geri';

  @override
  String get buttonSkip => 'Atla';

  @override
  String get buttonDone => 'Tamam';

  @override
  String get buttonSave => 'Kaydet';

  @override
  String get buttonCancel => 'İptal';

  @override
  String get authSignIn => 'Giriş Yap';

  @override
  String get authSignUp => 'Kayıt Ol';

  @override
  String get authEmail => 'E-posta';

  @override
  String get authPassword => 'Şifre';

  @override
  String get authForgotPassword => 'Şifremi unuttum';

  @override
  String get authContinueAsGuest => 'Misafir olarak devam et';

  @override
  String get authOrContinueWith => 'veya şununla devam et';

  @override
  String get authGoogleSignIn => 'Google ile giriş yap';

  @override
  String get authAppleSignIn => 'Apple ile giriş yap';

  @override
  String get dashboardGreetingMorning => 'Günaydın';

  @override
  String get dashboardGreetingAfternoon => 'İyi öğleden sonralar';

  @override
  String get dashboardGreetingEvening => 'İyi akşamlar';

  @override
  String get dashboardTodayProgress => 'Bugünkü ilerleme';

  @override
  String get dashboardWater => 'Su';

  @override
  String get dashboardCalories => 'Kalori';

  @override
  String get dashboardRoutines => 'Rutin';

  @override
  String get waterTitle => 'Su Takibi';

  @override
  String waterGoal(int current, int goal) {
    return '$current / $goal ml';
  }

  @override
  String get waterAddQuick => 'Hızlı Ekle';

  @override
  String get waterAddCustom => 'Özel Miktar';

  @override
  String get waterHistory => 'Bugünkü Su';

  @override
  String get mealTitle => 'Öğün Takibi';

  @override
  String get mealBreakfast => 'Kahvaltı';

  @override
  String get mealLunch => 'Öğle';

  @override
  String get mealDinner => 'Akşam';

  @override
  String get mealSnack => 'Ara Öğün';

  @override
  String get mealAddPhoto => 'Fotoğrafla Analiz Et';

  @override
  String get mealAddManual => 'Manuel Ekle';

  @override
  String get routineTitle => 'Rutinlerim';

  @override
  String routineStreak(int count) {
    return '$count günlük seri';
  }

  @override
  String routineCompleted(int done, int total) {
    return '$done/$total tamamlandı';
  }

  @override
  String get statsTitle => 'İstatistikler';

  @override
  String get stats7Days => '7 Gün';

  @override
  String get stats30Days => '30 Gün';

  @override
  String get stats90Days => '90 Gün';

  @override
  String get statsPremiumRequired => 'Premium üyelik gerekiyor';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsProfile => 'Profil';

  @override
  String get settingsGoals => 'Hedefler';

  @override
  String get settingsNotifications => 'Bildirimler';

  @override
  String get settingsPremium => 'Premium';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsSignOut => 'Çıkış Yap';

  @override
  String get premiumTitle => 'Premium\'a Geç';

  @override
  String get premiumWeekly => 'Haftalık';

  @override
  String get premiumMonthly => 'Aylık';

  @override
  String get premiumYearly => 'Yıllık';

  @override
  String get premiumBestValue => 'En iyi değer';

  @override
  String get premiumRestore => 'Satın almayı geri yükle';

  @override
  String premiumFreeTrial(int days) {
    return '$days gün ücretsiz dene';
  }

  @override
  String get errorGeneral => 'Bir şeyler ters gitti. Tekrar dene.';

  @override
  String get errorNoInternet => 'İnternet bağlantısı yok';

  @override
  String get errorRetry => 'Tekrar Dene';

  @override
  String get emptyStateNoData => 'Henüz veri yok';
}
