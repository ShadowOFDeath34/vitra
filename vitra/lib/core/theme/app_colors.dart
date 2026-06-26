import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Arka plan katmanları (Koyu Lüks) ──────────────────────────────────────
  static const background     = Color(0xFF080D18);  // En derin arka plan
  static const surface        = Color(0xFF0F1623);  // Kart/yüzey
  static const surfaceHigh    = Color(0xFF161E30);  // Yükseltilmiş kart
  static const surfaceBorder  = Color(0xFF1E293B);  // Hafif kenar çizgisi

  // ── Birincil (Teal/Zümrüt) ────────────────────────────────────────────────
  static const primary        = Color(0xFF14C2A8);  // Parlak teal
  static const primaryLight   = Color(0xFF2CD4BE);  // Açık teal
  static const primaryDark    = Color(0xFF0EA99A);  // Koyu teal
  static const primarySurface = Color(0xFF0A2421);  // Teal yüzeyi

  // ── Altın Aksan (diamond/premium his) ─────────────────────────────────────
  static const gold           = Color(0xFFD4AF37);
  static const goldLight      = Color(0xFFF0C842);
  static const goldSurface    = Color(0xFF221A08);

  // ── Metin ─────────────────────────────────────────────────────────────────
  static const textPrimary    = Color(0xFFF1F5F9);   // Neredeyse beyaz
  static const textSecondary  = Color(0xFF94A3B8);   // Soluk
  static const textMuted      = Color(0xFF475569);   // Çok soluk

  // Geriye dönük uyumluluk takma adları
  static const textDark   = textPrimary;
  static const textMedium = textSecondary;
  static const textLight  = textMuted;

  // ── Durum ─────────────────────────────────────────────────────────────────
  static const success    = Color(0xFF34D399);
  static const warning    = Color(0xFFFBBF24);
  static const error      = Color(0xFFF87171);

  // ── Özellik Renkleri ──────────────────────────────────────────────────────
  // Kalori (sıcak turuncu-kırmızı)
  static const calories        = Color(0xFFFF7A5C);
  static const caloriesDeep    = Color(0xFFE8543A);
  static const caloriesSurface = Color(0xFF280F08);
  static const caloriesLight   = caloriesSurface;  // geriye dönük uyumluluk

  // Su (parlak mavi)
  static const water        = Color(0xFF38BDF8);
  static const waterDeep    = Color(0xFF0EA5E9);
  static const waterSurface = Color(0xFF071D2A);
  static const waterLight   = waterSurface;  // geriye dönük uyumluluk

  // Rutin (mor)
  static const habits        = Color(0xFFA78BFA);
  static const habitsDeep    = Color(0xFF8B5CF6);
  static const habitsSurface = Color(0xFF160E30);
  static const habitsLight   = habitsSurface;  // geriye dönük uyumluluk

  // Koç (indigo)
  static const coach        = Color(0xFF818CF8);
  static const coachDeep    = Color(0xFF6366F1);
  static const coachSurface = Color(0xFF100F35);

  // Seri (turuncu)
  static const streak      = Color(0xFFFB923C);
  static const streakDeep  = Color(0xFFEA6B1A);

  // ── Cam Efektleri ─────────────────────────────────────────────────────────
  static Color glassWhite(double opacity) =>
      Colors.white.withValues(alpha: opacity);
  static Color glassPrimary(double opacity) =>
      primary.withValues(alpha: opacity);
  static Color glassBlack(double opacity) =>
      Colors.black.withValues(alpha: opacity);
}

// ── Gradyan Sabitleri ────────────────────────────────────────────────────────
class AppGradients {
  AppGradients._();

  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14C2A8), Color(0xFF0A8A79)],
  );

  static const gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4AF37), Color(0xFFF0C842), Color(0xFFB8960F)],
    stops: [0.0, 0.5, 1.0],
  );

  static const calories = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7A5C), Color(0xFFE8543A)],
  );

  static const water = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
  );

  static const habits = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
  );

  static const coach = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
  );

  static const streak = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFB923C), Color(0xFFEA6B1A)],
  );

  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF080D18), Color(0xFF0A0F1E)],
  );

  static const premiumCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF161E30), Color(0xFF0F1623)],
  );
}
