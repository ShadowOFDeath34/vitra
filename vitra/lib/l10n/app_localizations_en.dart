// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Vitra';

  @override
  String get appTagline => 'wellness. elevated.';

  @override
  String get splashTagline => 'wellness. elevated.';

  @override
  String get onboardingWelcomeTitle => 'Welcome';

  @override
  String get onboardingWelcomeSubtitle =>
      'Track your water, meals, and daily routines — all in one place.';

  @override
  String get onboardingWelcomeCta => 'Get Started';

  @override
  String get onboardingAlreadyHaveAccount => 'I already have an account';

  @override
  String get onboardingGoalTitle => 'What\'s your goal?';

  @override
  String get onboardingGoalSubtitle => 'Let\'s build a plan just for you.';

  @override
  String get onboardingGoalLoseWeight => 'Lose weight';

  @override
  String get onboardingGoalGainMuscle => 'Gain muscle';

  @override
  String get onboardingGoalStayHealthy => 'Stay healthy';

  @override
  String get onboardingGoalEatBetter => 'Eat better';

  @override
  String get onboardingGoalDrinkMore => 'Drink more water';

  @override
  String get onboardingGoalBuildHabits => 'Build healthy habits';

  @override
  String get onboardingLifestyleTitle => 'How active are you?';

  @override
  String get onboardingLifestyleSubtitle =>
      'We\'ll set your water and calorie goals accordingly.';

  @override
  String get onboardingLifestyleSedentary => 'Sedentary';

  @override
  String get onboardingLifestyleSedentaryDesc => 'Desk job, little movement';

  @override
  String get onboardingLifestyleLight => 'Lightly active';

  @override
  String get onboardingLifestyleLightDesc => 'Exercise 1-3 days a week';

  @override
  String get onboardingLifestyleModerate => 'Moderately active';

  @override
  String get onboardingLifestyleModerateDesc => 'Exercise 3-5 days a week';

  @override
  String get onboardingLifestyleVery => 'Very active';

  @override
  String get onboardingLifestyleVeryDesc => 'Intense training 6-7 days a week';

  @override
  String get onboardingWaterTitle => 'Daily water goal?';

  @override
  String onboardingWaterSubtitle(String amount) {
    return 'Recommended goal is $amount liters.';
  }

  @override
  String get onboardingRoutineTitle => 'Which routines do you want to track?';

  @override
  String get onboardingRoutineSubtitle => 'You can change these anytime.';

  @override
  String get routineMeditation => 'Meditation';

  @override
  String get routineExercise => 'Exercise';

  @override
  String get routineSleep => 'Sleep schedule';

  @override
  String get routineReading => 'Reading';

  @override
  String get routineNoPhone => 'Phone break';

  @override
  String get routineVitamins => 'Vitamins/meds';

  @override
  String get routineStretch => 'Stretching';

  @override
  String get routineColdShower => 'Cold shower';

  @override
  String get onboardingNotificationTitle => 'Enable reminders?';

  @override
  String get onboardingNotificationSubtitle =>
      'Get notified to drink water and complete your routines.';

  @override
  String get onboardingNotificationEnable => 'Yes, keep them on';

  @override
  String get onboardingNotificationSkip => 'Not now';

  @override
  String get onboardingPremiumTitle => 'Vitra Premium';

  @override
  String get onboardingPremiumSubtitle =>
      'AI photo analysis, unlimited stats and more.';

  @override
  String get onboardingPremiumFeature1 => 'Unlimited AI meal analysis';

  @override
  String get onboardingPremiumFeature2 => '30 and 90-day statistics';

  @override
  String get onboardingPremiumFeature3 => 'Priority support';

  @override
  String get onboardingPremiumCta => 'Try free';

  @override
  String get onboardingPremiumSkip => 'Continue for free';

  @override
  String get buttonNext => 'Continue';

  @override
  String get buttonBack => 'Back';

  @override
  String get buttonSkip => 'Skip';

  @override
  String get buttonDone => 'Done';

  @override
  String get buttonSave => 'Save';

  @override
  String get buttonCancel => 'Cancel';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authSignUp => 'Create Account';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authForgotPassword => 'Forgot password';

  @override
  String get authContinueAsGuest => 'Continue as guest';

  @override
  String get authOrContinueWith => 'or continue with';

  @override
  String get authGoogleSignIn => 'Sign in with Google';

  @override
  String get authAppleSignIn => 'Sign in with Apple';

  @override
  String get dashboardGreetingMorning => 'Good morning';

  @override
  String get dashboardGreetingAfternoon => 'Good afternoon';

  @override
  String get dashboardGreetingEvening => 'Good evening';

  @override
  String get dashboardTodayProgress => 'Today\'s progress';

  @override
  String get dashboardWater => 'Water';

  @override
  String get dashboardCalories => 'Calories';

  @override
  String get dashboardRoutines => 'Routines';

  @override
  String get waterTitle => 'Water Tracker';

  @override
  String waterGoal(int current, int goal) {
    return '$current / $goal ml';
  }

  @override
  String get waterAddQuick => 'Quick Add';

  @override
  String get waterAddCustom => 'Custom Amount';

  @override
  String get waterHistory => 'Today\'s Water';

  @override
  String get mealTitle => 'Meal Tracker';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealSnack => 'Snack';

  @override
  String get mealAddPhoto => 'Analyze with Photo';

  @override
  String get mealAddManual => 'Add Manually';

  @override
  String get routineTitle => 'My Routines';

  @override
  String routineStreak(int count) {
    return '$count-day streak';
  }

  @override
  String routineCompleted(int done, int total) {
    return '$done/$total completed';
  }

  @override
  String get statsTitle => 'Statistics';

  @override
  String get stats7Days => '7 Days';

  @override
  String get stats30Days => '30 Days';

  @override
  String get stats90Days => '90 Days';

  @override
  String get statsPremiumRequired => 'Premium membership required';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsGoals => 'Goals';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPremium => 'Premium';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get premiumTitle => 'Go Premium';

  @override
  String get premiumWeekly => 'Weekly';

  @override
  String get premiumMonthly => 'Monthly';

  @override
  String get premiumYearly => 'Yearly';

  @override
  String get premiumBestValue => 'Best value';

  @override
  String get premiumRestore => 'Restore purchase';

  @override
  String premiumFreeTrial(int days) {
    return 'Try free for $days days';
  }

  @override
  String get errorGeneral => 'Something went wrong. Please try again.';

  @override
  String get errorNoInternet => 'No internet connection';

  @override
  String get errorRetry => 'Try Again';

  @override
  String get emptyStateNoData => 'No data yet';
}
