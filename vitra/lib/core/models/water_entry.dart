class WaterEntry {
  final String id;
  final int ml;
  final DateTime time;

  const WaterEntry({
    required this.id,
    required this.ml,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ml': ml,
        'time': time.millisecondsSinceEpoch,
      };

  factory WaterEntry.fromJson(Map<String, dynamic> json) => WaterEntry(
        id: json['id'] as String,
        ml: json['ml'] as int,
        time: DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
      );
}
