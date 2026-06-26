import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/weight_entry.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/v_theme.dart';

class WeightLogPage extends StatefulWidget {
  const WeightLogPage({super.key});

  @override
  State<WeightLogPage> createState() => _WeightLogPageState();
}

class _WeightLogPageState extends State<WeightLogPage> {
  List<WeightEntry> _entries = [];
  bool _loading = true;
  bool _saving  = false;

  final _weightCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries = await FirestoreService.instance.fetchWeightLog();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
      // Bugünün girişi varsa onu göster
      final todayKey = _todayKey();
      final todayEntry = entries.where((e) => e.dateKey == todayKey).firstOrNull;
      if (todayEntry != null) {
        _weightCtrl.text = todayEntry.weight.toStringAsFixed(1);
      }
    });
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    final w = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    if (w == null || w < 20 || w > 400) return;
    setState(() => _saving = true);
    await FirestoreService.instance.saveWeightEntry(w);
    await _load();
    if (!mounted) return;
    setState(() => _saving = false);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kilo kaydedildi'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _delete(WeightEntry entry) async {
    await FirestoreService.instance.deleteWeightEntry(entry.dateKey);
    await _load();
  }

  double? get _trend {
    if (_entries.length < 2) return null;
    return _entries.last.weight - _entries.first.weight;
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final trend = _trend;

    return Scaffold(
      backgroundColor: vc.bg,
      appBar: AppBar(
        backgroundColor: vc.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: vc.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kilo Takibi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: vc.text,
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: vc.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Giriş Kartı
                    _EntryCard(
                      vc: vc,
                      controller: _weightCtrl,
                      saving: _saving,
                      onSave: _save,
                    ),
                    const SizedBox(height: 20),

                    // Trend özeti
                    if (_entries.isNotEmpty) ...[
                      _SummaryRow(vc: vc, entries: _entries, trend: trend),
                      const SizedBox(height: 20),
                    ],

                    // Grafik
                    if (_entries.length >= 2) ...[
                      Text(
                        'Grafik',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: vc.textSub,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _WeightChart(entries: _entries, vc: vc),
                      const SizedBox(height: 24),
                    ],

                    // Geçmiş listesi
                    if (_entries.isNotEmpty) ...[
                      Text(
                        'Geçmiş',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: vc.textSub,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._entries.reversed.map(
                        (e) => _HistoryRow(
                          vc: vc,
                          entry: e,
                          onDelete: () => _delete(e),
                        ),
                      ),
                    ] else
                      _EmptyState(vc: vc),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Giriş Kartı ──────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final VColors vc;
  final TextEditingController controller;
  final bool saving;
  final VoidCallback onSave;

  const _EntryCard({
    required this.vc,
    required this.controller,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [vc.primary.withValues(alpha: 0.1), vc.primary.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vc.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bugünün kilonuzu girin',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: vc.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Günlük tartı alışkanlığı ilerlemeyi gösterir',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: vc.textSub),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                  ],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: vc.text,
                  ),
                  decoration: InputDecoration(
                    hintText: '70.0',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: vc.textMuted,
                    ),
                    suffixText: 'kg',
                    suffixStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: vc.textSub,
                    ),
                    filled: true,
                    fillColor: vc.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => onSave(),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: saving ? null : onSave,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: saving
                        ? vc.primary.withValues(alpha: 0.5)
                        : vc.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: vc.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: saving
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded,
                          color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Özet Satırı ──────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final VColors vc;
  final List<WeightEntry> entries;
  final double? trend;

  const _SummaryRow({
    required this.vc,
    required this.entries,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final current = entries.last.weight;
    final start   = entries.first.weight;
    final trendVal = trend;

    return Row(
      children: [
        Expanded(
          child: _StatChip(
            vc: vc,
            label: 'Güncel',
            value: '${current.toStringAsFixed(1)} kg',
            color: vc.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            vc: vc,
            label: 'Başlangıç',
            value: '${start.toStringAsFixed(1)} kg',
            color: vc.textSub,
          ),
        ),
        if (trendVal != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _StatChip(
              vc: vc,
              label: 'Değişim',
              value: '${trendVal >= 0 ? '+' : ''}${trendVal.toStringAsFixed(1)} kg',
              color: trendVal < 0
                  ? const Color(0xFF10B981)
                  : trendVal > 0
                      ? const Color(0xFFEF4444)
                      : vc.textSub,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final VColors vc;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.vc,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: vc.textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Grafik ────────────────────────────────────────────────────────────────────

class _WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final VColors vc;

  const _WeightChart({required this.entries, required this.vc});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
      ),
      child: CustomPaint(
        painter: _ChartPainter(entries: entries, primaryColor: vc.primary),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<WeightEntry> entries;
  final Color primaryColor;

  _ChartPainter({required this.entries, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;

    final weights = entries.map((e) => e.weight).toList();
    final minW    = weights.reduce(math.min);
    final maxW    = weights.reduce(math.max);
    final range   = (maxW - minW).clamp(1.0, double.infinity);

    // Kılavuz çizgileri
    final gridPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height - (size.height * i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Nokta koordinatları
    final pts = <Offset>[];
    for (int i = 0; i < entries.length; i++) {
      final x = size.width * i / (entries.length - 1);
      final y = size.height - ((entries[i].weight - minW) / range) * size.height;
      pts.add(Offset(x, y.clamp(2, size.height - 2)));
    }

    // Dolgu alanı
    final fillPath = Path()..moveTo(pts.first.dx, size.height);
    for (final p in pts) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(pts.last.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withValues(alpha: 0.2),
            primaryColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Çizgi
    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Noktalar
    final dotPaint = Paint()..color = primaryColor;
    final dotBg    = Paint()..color = Colors.white;
    for (final p in pts) {
      canvas.drawCircle(p, 5, dotBg);
      canvas.drawCircle(p, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.entries != entries;
}

// ── Geçmiş Satırı ────────────────────────────────────────────────────────────

class _HistoryRow extends StatelessWidget {
  final VColors vc;
  final WeightEntry entry;
  final VoidCallback onDelete;

  const _HistoryRow({
    required this.vc,
    required this.entry,
    required this.onDelete,
  });

  String get _dateLabel {
    final d = entry.date;
    final today = DateTime.now();
    if (d.year == today.year && d.month == today.month && d.day == today.day) {
      return 'Bugün';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) {
      return 'Dün';
    }
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: vc.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: vc.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _dateLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: vc.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${entry.weight.toStringAsFixed(1)} kg',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: vc.primary,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close_rounded, size: 18, color: vc.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Boş Durum ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VColors vc;
  const _EmptyState({required this.vc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.monitor_weight_outlined, size: 48, color: vc.textMuted),
          const SizedBox(height: 12),
          Text(
            'Henüz kilo girişi yok',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: vc.textSub,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'İlk kilonu yukarıdan gir — takip başlasın.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: vc.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
