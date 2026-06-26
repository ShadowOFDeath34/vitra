enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeX on MealType {
  String get label =>
      const ['Kahvaltı', 'Öğle Yemeği', 'Akşam Yemeği', 'Ara Öğün'][index];
  String get emoji =>
      const ['🌅', '☀️', '🌙', '🍎'][index];
}

enum PortionUnit { none, gram, cup, spoon, piece }

extension PortionUnitX on PortionUnit {
  String get label => const ['', 'gram', 'bardak', 'kaşık', 'adet'][index];
  String get short => const ['', 'g', 'bardak', 'kaşık', 'adet'][index];
}

class MealEntry {
  final String id;
  final String name;
  final MealType type;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int fiberG;
  final int sodiumMg;
  final int sugarG;
  final PortionUnit portionUnit;
  final double portionSize;
  final DateTime time;

  const MealEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.calories,
    this.proteinG   = 0,
    this.carbsG     = 0,
    this.fatG       = 0,
    this.fiberG     = 0,
    this.sodiumMg   = 0,
    this.sugarG     = 0,
    this.portionUnit = PortionUnit.none,
    this.portionSize = 1.0,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'id':          id,
        'name':        name,
        'type':        type.index,
        'calories':    calories,
        'proteinG':    proteinG,
        'carbsG':      carbsG,
        'fatG':        fatG,
        'fiberG':      fiberG,
        'sodiumMg':    sodiumMg,
        'sugarG':      sugarG,
        'portionUnit': portionUnit.index,
        'portionSize': portionSize,
        'time':        time.millisecondsSinceEpoch,
      };

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
        id:          json['id'] as String,
        name:        json['name'] as String,
        type:        MealType.values[json['type'] as int],
        calories:    json['calories'] as int,
        proteinG:    (json['proteinG']  as int?) ?? 0,
        carbsG:      (json['carbsG']    as int?) ?? 0,
        fatG:        (json['fatG']      as int?) ?? 0,
        fiberG:      (json['fiberG']    as int?) ?? 0,
        sodiumMg:    (json['sodiumMg']  as int?) ?? 0,
        sugarG:      (json['sugarG']    as int?) ?? 0,
        portionUnit: PortionUnit.values[(json['portionUnit'] as int?) ?? 0],
        portionSize: (json['portionSize'] as num?)?.toDouble() ?? 1.0,
        time:        DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
      );
}
