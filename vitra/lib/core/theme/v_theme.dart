import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Tema token'ları (ThemeExtension) ─────────────────────────────────────────

@immutable
class VColors extends ThemeExtension<VColors> {
  const VColors({
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.primary,
    required this.primaryGlow,
    required this.primarySurface,
    required this.accent,
    required this.text,
    required this.textSub,
    required this.textMuted,
    required this.isDark,
    required this.calorieSurface,
    required this.waterSurface,
    required this.habitSurface,
    required this.coachSurface,
    required this.streakSurface,
  });

  final Color bg;
  final Color surface;
  final Color surfaceHigh;
  final Color border;
  final Color primary;
  final Color primaryGlow;
  final Color primarySurface;
  final Color accent;
  final Color text;
  final Color textSub;
  final Color textMuted;
  final bool isDark;
  // Feature surface renkleri — tema-aware
  final Color calorieSurface;
  final Color waterSurface;
  final Color habitSurface;
  final Color coachSurface;
  final Color streakSurface;

  @override
  VColors copyWith({
    Color? bg, Color? surface, Color? surfaceHigh, Color? border,
    Color? primary, Color? primaryGlow, Color? primarySurface, Color? accent,
    Color? text, Color? textSub, Color? textMuted, bool? isDark,
    Color? calorieSurface, Color? waterSurface, Color? habitSurface,
    Color? coachSurface, Color? streakSurface,
  }) => VColors(
    bg:            bg            ?? this.bg,
    surface:       surface       ?? this.surface,
    surfaceHigh:   surfaceHigh   ?? this.surfaceHigh,
    border:        border        ?? this.border,
    primary:       primary       ?? this.primary,
    primaryGlow:   primaryGlow   ?? this.primaryGlow,
    primarySurface:primarySurface?? this.primarySurface,
    accent:        accent        ?? this.accent,
    text:          text          ?? this.text,
    textSub:       textSub       ?? this.textSub,
    textMuted:     textMuted     ?? this.textMuted,
    isDark:        isDark        ?? this.isDark,
    calorieSurface:calorieSurface?? this.calorieSurface,
    waterSurface:  waterSurface  ?? this.waterSurface,
    habitSurface:  habitSurface  ?? this.habitSurface,
    coachSurface:  coachSurface  ?? this.coachSurface,
    streakSurface: streakSurface ?? this.streakSurface,
  );

  @override
  VColors lerp(VColors? other, double t) {
    if (other == null) return this;
    return VColors(
      bg:             Color.lerp(bg,            other.bg,            t)!,
      surface:        Color.lerp(surface,        other.surface,       t)!,
      surfaceHigh:    Color.lerp(surfaceHigh,    other.surfaceHigh,   t)!,
      border:         Color.lerp(border,         other.border,        t)!,
      primary:        Color.lerp(primary,        other.primary,       t)!,
      primaryGlow:    Color.lerp(primaryGlow,    other.primaryGlow,   t)!,
      primarySurface: Color.lerp(primarySurface, other.primarySurface,t)!,
      accent:         Color.lerp(accent,         other.accent,        t)!,
      text:           Color.lerp(text,           other.text,          t)!,
      textSub:        Color.lerp(textSub,        other.textSub,       t)!,
      textMuted:      Color.lerp(textMuted,      other.textMuted,     t)!,
      isDark:         t < 0.5 ? isDark : other.isDark,
      calorieSurface: Color.lerp(calorieSurface, other.calorieSurface,t)!,
      waterSurface:   Color.lerp(waterSurface,   other.waterSurface,  t)!,
      habitSurface:   Color.lerp(habitSurface,   other.habitSurface,  t)!,
      coachSurface:   Color.lerp(coachSurface,   other.coachSurface,  t)!,
      streakSurface:  Color.lerp(streakSurface,  other.streakSurface, t)!,
    );
  }
}

// ── BuildContext extension (kısa erişim) ─────────────────────────────────────

extension VThemeX on BuildContext {
  VColors get vt => Theme.of(this).extension<VColors>()!;
}

// ── Tema tanımları ────────────────────────────────────────────────────────────

enum VitraTheme {
  pearl,      // İnci        (krem + teal — açık) — varsayılan
  midnight,   // Gece Yarısı (navy + teal)
  obsidian,   // Obsidyen    (siyah + indigo)
  aurora,     // Kuzey Işığı (koyu mor + yeşil)
  roseGold,   // Gül Altını  (koyu kırmızı-siyah + gül)
}

extension VitraThemeExt on VitraTheme {
  String get displayName => const {
    VitraTheme.midnight: 'Gece Yarısı',
    VitraTheme.obsidian: 'Obsidyen',
    VitraTheme.aurora:   'Kuzey Işığı',
    VitraTheme.pearl:    'İnci',
    VitraTheme.roseGold: 'Gül Altını',
  }[this]!;

  String get emoji => const {
    VitraTheme.midnight: '🌑',
    VitraTheme.obsidian: '⚡',
    VitraTheme.aurora:   '🌌',
    VitraTheme.pearl:    '☀️',
    VitraTheme.roseGold: '🌹',
  }[this]!;

  VColors get colors => const {
    VitraTheme.midnight: _midnight,
    VitraTheme.obsidian: _obsidian,
    VitraTheme.aurora:   _aurora,
    VitraTheme.pearl:    _pearl,
    VitraTheme.roseGold: _roseGold,
  }[this]!;

  // Tema önizleme gradyanı (seçici kartında kullanılır)
  List<Color> get previewColors => {
    VitraTheme.midnight: [const Color(0xFF080D18), const Color(0xFF14C2A8)],
    VitraTheme.obsidian: [const Color(0xFF0A0A0A), const Color(0xFF6366F1)],
    VitraTheme.aurora:   [const Color(0xFF0D0B1E), const Color(0xFF8B5CF6)],
    VitraTheme.pearl:    [const Color(0xFFF8F7F2), const Color(0xFF0D9B8A)],
    VitraTheme.roseGold: [const Color(0xFF150C10), const Color(0xFFF43F5E)],
  }[this]!;
}

// ── 1. Gece Yarısı (Midnight) ─────────────────────────────────────────────────
const _midnight = VColors(
  bg:            Color(0xFF080D18),
  surface:       Color(0xFF0F1623),
  surfaceHigh:   Color(0xFF161E30),
  border:        Color(0xFF1E293B),
  primary:       Color(0xFF14C2A8),
  primaryGlow:   Color(0xFF14C2A8),
  primarySurface:Color(0xFF0A2421),
  accent:        Color(0xFFD4AF37),
  text:          Color(0xFFF1F5F9),
  textSub:       Color(0xFF94A3B8),
  textMuted:     Color(0xFF475569),
  isDark:        true,
  calorieSurface:Color(0xFF280F08),
  waterSurface:  Color(0xFF071D2A),
  habitSurface:  Color(0xFF160E30),
  coachSurface:  Color(0xFF100F35),
  streakSurface: Color(0xFF1F1008),
);

// ── 2. Obsidyen (Obsidian) ────────────────────────────────────────────────────
const _obsidian = VColors(
  bg:            Color(0xFF080808),
  surface:       Color(0xFF111111),
  surfaceHigh:   Color(0xFF1A1A1A),
  border:        Color(0xFF2A2A2A),
  primary:       Color(0xFF818CF8),
  primaryGlow:   Color(0xFF6366F1),
  primarySurface:Color(0xFF10103A),
  accent:        Color(0xFFE879F9),
  text:          Color(0xFFF8FAFC),
  textSub:       Color(0xFF94A3B8),
  textMuted:     Color(0xFF52525B),
  isDark:        true,
  calorieSurface:Color(0xFF1E0C08),
  waterSurface:  Color(0xFF071520),
  habitSurface:  Color(0xFF0F0C28),
  coachSurface:  Color(0xFF0D0C2C),
  streakSurface: Color(0xFF180F06),
);

// ── 3. Kuzey Işığı (Aurora) ───────────────────────────────────────────────────
const _aurora = VColors(
  bg:            Color(0xFF0D0B1E),
  surface:       Color(0xFF131028),
  surfaceHigh:   Color(0xFF1C1838),
  border:        Color(0xFF2D2A50),
  primary:       Color(0xFFA78BFA),
  primaryGlow:   Color(0xFF8B5CF6),
  primarySurface:Color(0xFF1A1035),
  accent:        Color(0xFF34D399),
  text:          Color(0xFFF0EEFF),
  textSub:       Color(0xFF9CA3AF),
  textMuted:     Color(0xFF4B5563),
  isDark:        true,
  calorieSurface:Color(0xFF22100A),
  waterSurface:  Color(0xFF091822),
  habitSurface:  Color(0xFF160E2E),
  coachSurface:  Color(0xFF0E0D30),
  streakSurface: Color(0xFF1C1008),
);

// ── 4. İnci (Pearl) — Açık tema ───────────────────────────────────────────────
const _pearl = VColors(
  bg:            Color(0xFFF8F7F2),
  surface:       Color(0xFFFFFFFF),
  surfaceHigh:   Color(0xFFF3F2EC),
  border:        Color(0xFFE5E3D8),
  primary:       Color(0xFF0D9B8A),
  primaryGlow:   Color(0xFF14C2A8),
  primarySurface:Color(0xFFE8F5F3),
  accent:        Color(0xFFD4AF37),
  text:          Color(0xFF1A1A2E),
  textSub:       Color(0xFF6B7280),
  textMuted:     Color(0xFF9CA3AF),
  isDark:        false,
  calorieSurface:Color(0xFFFFEEEB),
  waterSurface:  Color(0xFFE8F4FC),
  habitSurface:  Color(0xFFF0ECFF),
  coachSurface:  Color(0xFFEEEEFF),
  streakSurface: Color(0xFFFFF3E8),
);

// ── 5. Gül Altını (Rose Gold) ─────────────────────────────────────────────────
const _roseGold = VColors(
  bg:            Color(0xFF12080D),
  surface:       Color(0xFF1E0F17),
  surfaceHigh:   Color(0xFF2A1420),
  border:        Color(0xFF3D1F2D),
  primary:       Color(0xFFF43F5E),
  primaryGlow:   Color(0xFFE11D48),
  primarySurface:Color(0xFF2C0A14),
  accent:        Color(0xFFFBBF24),
  text:          Color(0xFFFFF1F5),
  textSub:       Color(0xFFB0899A),
  textMuted:     Color(0xFF6B4455),
  isDark:        true,
  calorieSurface:Color(0xFF280A14),
  waterSurface:  Color(0xFF08152A),
  habitSurface:  Color(0xFF1A0A1E),
  coachSurface:  Color(0xFF150A28),
  streakSurface: Color(0xFF200B08),
);

// ── ThemeData üretici ─────────────────────────────────────────────────────────

class VThemeBuilder {
  VThemeBuilder._();

  static ThemeData build(VitraTheme theme) {
    final c  = theme.colors;
    final tt = GoogleFonts.plusJakartaSansTextTheme(TextTheme(
      displayLarge:  TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: c.text, letterSpacing: -1.5),
      displayMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: c.text, letterSpacing: -1),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: c.text, letterSpacing: -0.5),
      headlineMedium:TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text, letterSpacing: -0.3),
      titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text, letterSpacing: -0.2),
      titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text),
      titleSmall:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textSub),
      bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: c.text),
      bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: c.textSub),
      bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: c.textMuted),
      labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text),
      labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.textSub),
      labelSmall:    TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: c.textMuted, letterSpacing: 0.5),
    ));

    return ThemeData(
      useMaterial3: true,
      brightness: c.isDark ? Brightness.dark : Brightness.light,
      extensions: [c],
      colorScheme: ColorScheme(
        brightness:  c.isDark ? Brightness.dark : Brightness.light,
        primary:     c.primary,
        secondary:   c.accent,
        surface:     c.surface,
        error:       const Color(0xFFF87171),
        onPrimary:   Colors.white,
        onSecondary: c.isDark ? Colors.black : Colors.white,
        onSurface:   c.text,
        onError:     Colors.white,
      ),
      scaffoldBackgroundColor: c.bg,
      textTheme: tt,
      primaryTextTheme: tt,

      appBarTheme: AppBarTheme(
        backgroundColor:        c.bg,
        elevation:              0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.text),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: c.text, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          minimumSize:     const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation:       0,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:     true,
        fillColor:  c.surfaceHigh,
        border:         OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.border)),
        enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.border)),
        focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.primary, width: 1.5)),
        hintStyle:      GoogleFonts.plusJakartaSans(color: c.textMuted, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      cardTheme: CardThemeData(
        color:   c.surface,
        elevation: 0,
        shape:   RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.border.withValues(alpha: 0.6)),
        ),
        margin: EdgeInsets.zero,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: c.border.withValues(alpha: 0.5), thickness: 1, space: 1,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : c.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? c.primary
              : c.border,
        ),
      ),
    );
  }
}
