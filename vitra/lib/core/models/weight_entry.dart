import 'package:cloud_firestore/cloud_firestore.dart';

class WeightEntry {
  final String dateKey;
  final double weight;
  final DateTime date;
  final bool isProtected;
  final String? label;

  const WeightEntry({
    required this.dateKey,
    required this.weight,
    required this.date,
    this.isProtected = false,
    this.label,
  });

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'date': Timestamp.fromDate(date),
        if (isProtected) 'protected': true,
        if (label != null) 'label': label,
      };

  static WeightEntry fromDoc(String dateKey, Map<String, dynamic> data) {
    final ts = data['date'];
    final date = ts is Timestamp ? ts.toDate() : DateTime.now();
    return WeightEntry(
      dateKey: dateKey,
      weight: (data['weight'] as num).toDouble(),
      date: date,
      isProtected: data['protected'] == true,
      label: data['label'] as String?,
    );
  }
}
