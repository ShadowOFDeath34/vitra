import 'package:cloud_firestore/cloud_firestore.dart';

/// MET (Metabolic Equivalent of Task) tabanlı egzersiz logu.
/// Kalori = MET × ağırlık_kg × süre_saat
class ExerciseEntry {
  final String id;
  final String name;
  final String category; // 'cardio' | 'strength' | 'flexibility' | 'other'
  final double met;
  final int durationMin;
  final int caloriesBurned;
  final DateTime time;

  const ExerciseEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.met,
    required this.durationMin,
    required this.caloriesBurned,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'id':             id,
        'name':           name,
        'category':       category,
        'met':            met,
        'durationMin':    durationMin,
        'caloriesBurned': caloriesBurned,
        'time':           Timestamp.fromDate(time),
      };

  factory ExerciseEntry.fromJson(Map<String, dynamic> json) {
    final ts = json['time'];
    return ExerciseEntry(
      id:             json['id'] as String,
      name:           json['name'] as String,
      category:       json['category'] as String? ?? 'other',
      met:            (json['met'] as num).toDouble(),
      durationMin:    json['durationMin'] as int,
      caloriesBurned: json['caloriesBurned'] as int,
      time: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  /// Bilimsel MET değerleriyle hazır aktivite listesi.
  static const presets = [
    // ── Kardiyo ──────────────────────────────────────────────────────────────
    (name: 'Yürüyüş (hafif)',        category: 'cardio',      met: 3.5),
    (name: 'Yürüyüş (hızlı)',        category: 'cardio',      met: 5.0),
    (name: 'Hafif koşu (jog)',        category: 'cardio',      met: 7.0),
    (name: 'Koşu (orta tempo)',       category: 'cardio',      met: 9.8),
    (name: 'Koşu (hızlı)',            category: 'cardio',      met: 12.5),
    (name: 'Koşu (maraton)',          category: 'cardio',      met: 13.5),
    (name: 'Sprint',                  category: 'cardio',      met: 23.0),
    (name: 'Bisiklet (hafif)',        category: 'cardio',      met: 5.8),
    (name: 'Bisiklet (orta)',         category: 'cardio',      met: 7.5),
    (name: 'Bisiklet (hızlı)',        category: 'cardio',      met: 10.0),
    (name: 'Yüzme (yavaş)',           category: 'cardio',      met: 6.0),
    (name: 'Yüzme (hızlı)',           category: 'cardio',      met: 8.0),
    (name: 'Atlama ipi',              category: 'cardio',      met: 12.3),
    (name: 'HIIT',                    category: 'cardio',      met: 14.0),
    (name: 'Aerobik',                 category: 'cardio',      met: 7.3),
    (name: 'Zumba / Dans dersi',      category: 'cardio',      met: 6.5),
    (name: 'Dans',                    category: 'cardio',      met: 5.5),
    (name: 'Merdiven çıkma',          category: 'cardio',      met: 8.0),
    (name: 'Eliptik',                 category: 'cardio',      met: 5.5),
    (name: 'Yürüyüş bandı',          category: 'cardio',      met: 6.0),
    (name: 'Kürek çekme (rowing)',    category: 'cardio',      met: 8.5),
    (name: 'Futbol',                  category: 'cardio',      met: 10.0),
    (name: 'Basketbol',               category: 'cardio',      met: 8.0),
    (name: 'Tenis',                   category: 'cardio',      met: 7.3),
    (name: 'Voleybol',                category: 'cardio',      met: 4.0),
    (name: 'Badminton',               category: 'cardio',      met: 5.5),
    (name: 'Yüzme (serbest stil)',    category: 'cardio',      met: 9.8),
    (name: 'Boks (vuruş çantası)',    category: 'cardio',      met: 9.8),
    (name: 'Kickboks',                category: 'cardio',      met: 10.0),
    (name: 'Dağ yürüyüşü (trekking)',category: 'cardio',      met: 6.0),
    (name: 'Kayak',                   category: 'cardio',      met: 7.0),
    // ── Güç ──────────────────────────────────────────────────────────────────
    (name: 'Ağırlık antrenmanı',      category: 'strength',    met: 5.0),
    (name: 'Ağırlık (yoğun)',         category: 'strength',    met: 6.0),
    (name: 'CrossFit',                category: 'strength',    met: 13.0),
    (name: 'Bodyweight antrenman',    category: 'strength',    met: 4.5),
    (name: 'Fonksiyonel antrenman',   category: 'strength',    met: 5.5),
    (name: 'Halter',                  category: 'strength',    met: 4.0),
    (name: 'Güreş / Dövüş sanatı',   category: 'strength',    met: 9.0),
    (name: 'Şınav / Mekik devresi',  category: 'strength',    met: 5.5),
    // ── Esneklik & Denge ─────────────────────────────────────────────────────
    (name: 'Yoga (restoratif)',       category: 'flexibility', met: 2.5),
    (name: 'Yoga (güç / vinyasa)',    category: 'flexibility', met: 4.0),
    (name: 'Pilates',                 category: 'flexibility', met: 3.0),
    (name: 'Pilates (yoğun)',         category: 'flexibility', met: 4.0),
    (name: 'Tai Chi',                 category: 'flexibility', met: 3.5),
    (name: 'Germe / Stretching',      category: 'flexibility', met: 2.5),
    // ── Diğer ────────────────────────────────────────────────────────────────
    (name: 'Ev işleri',               category: 'other',       met: 3.5),
    (name: 'Bahçe işleri',            category: 'other',       met: 4.5),
    (name: 'Yüklü taşıma / Nakliye', category: 'other',       met: 4.0),
    (name: 'Köpek gezdirme',          category: 'other',       met: 3.5),
    (name: 'Kaya tırmanışı',          category: 'other',       met: 8.0),
  ];

  /// Egzersiz sırasında kaybedilen tahmini su (ml).
  /// Formül: (MET / 7.0) × 500 ml × (süre / 60 dk)
  int get waterLossMl => ((met / 7.0) * 500.0 * durationMin / 60.0).round();

  static int calcCalories({
    required double met,
    required int durationMin,
    required double weightKg,
  }) {
    return (met * weightKg * (durationMin / 60)).round();
  }
}
