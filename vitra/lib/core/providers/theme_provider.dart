import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/v_theme.dart';

const _kThemeKey = 'vitra_theme';

final themeProvider =
    StateNotifierProvider<ThemeNotifier, VitraTheme>((ref) => ThemeNotifier());

class ThemeNotifier extends StateNotifier<VitraTheme> {
  ThemeNotifier() : super(VitraTheme.pearl) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);
    if (saved != null) {
      final found = VitraTheme.values.where((t) => t.name == saved).firstOrNull;
      if (found != null) state = found;
    }
  }

  Future<void> setTheme(VitraTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, theme.name);
  }
}
