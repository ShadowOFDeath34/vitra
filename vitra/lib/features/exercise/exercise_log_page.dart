import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/exercise_entry.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/v_theme.dart';

class ExerciseLogPage extends ConsumerStatefulWidget {
  const ExerciseLogPage({super.key});

  @override
  ConsumerState<ExerciseLogPage> createState() => _ExerciseLogPageState();
}

class _ExerciseLogPageState extends ConsumerState<ExerciseLogPage> {
  List<ExerciseEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries = await FirestoreService.instance.fetchExercises(DateTime.now());
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _delete(ExerciseEntry entry) async {
    await FirestoreService.instance.deleteExercise(entry);
    await _load();
  }

  void _showAddSheet() {
    final weightKg = ref.read(userProfileProvider).weightKg ?? 70.0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddExerciseSheet(
        weightKg: weightKg,
        onAdd: (entry) async {
          await FirestoreService.instance.saveExercise(entry);
          await _load();
        },
      ),
    );
  }

  int get _totalBurned => _entries.fold(0, (s, e) => s + e.caloriesBurned);
  int get _totalMinutes => _entries.fold(0, (s, e) => s + e.durationMin);

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;

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
          'Egzersiz Logu',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: vc.text,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _showAddSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: vc.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('Ekle',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: vc.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Günlük özet
                    if (_entries.isNotEmpty) ...[
                      _DailySummary(
                        vc: vc,
                        totalBurned: _totalBurned,
                        totalMinutes: _totalMinutes,
                        count: _entries.length,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Egzersiz listesi
                    if (_entries.isEmpty)
                      _EmptyState(vc: vc, onAdd: _showAddSheet)
                    else ...[
                      Text(
                        'Bugünün Aktiviteleri',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: vc.textSub,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._entries.map(
                        (e) => _ExerciseRow(
                          vc: vc,
                          entry: e,
                          onDelete: () => _delete(e),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Günlük Özet ──────────────────────────────────────────────────────────────

class _DailySummary extends StatelessWidget {
  final VColors vc;
  final int totalBurned;
  final int totalMinutes;
  final int count;

  const _DailySummary({
    required this.vc,
    required this.totalBurned,
    required this.totalMinutes,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEF4444).withValues(alpha: 0.1),
            const Color(0xFFEF4444).withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: Color(0xFFEF4444), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalBurned kcal yakıldı',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFEF4444),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count aktivite · $totalMinutes dakika',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: vc.textSub,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Egzersiz Satırı ───────────────────────────────────────────────────────────

class _ExerciseRow extends StatelessWidget {
  final VColors vc;
  final ExerciseEntry entry;
  final VoidCallback onDelete;

  const _ExerciseRow({
    required this.vc,
    required this.entry,
    required this.onDelete,
  });

  String get _categoryEmoji {
    return switch (entry.category) {
      'cardio'      => '🏃',
      'strength'    => '💪',
      'flexibility' => '🧘',
      _             => '⚡',
    };
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: vc.border),
      ),
      child: Row(
        children: [
          Text(_categoryEmoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: vc.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.durationMin} dk  ·  $timeStr',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: vc.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.caloriesBurned} kcal',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFEF4444),
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
  final VoidCallback onAdd;

  const _EmptyState({required this.vc, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.fitness_center_rounded, size: 52, color: vc.textMuted),
          const SizedBox(height: 14),
          Text(
            'Bugün egzersiz yok',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: vc.textSub,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aktiviteni ekle — yakılan kaloriyi izle.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: vc.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: vc.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Egzersiz Ekle',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Egzersiz Ekleme Sheet ─────────────────────────────────────────────────────

class _AddExerciseSheet extends StatefulWidget {
  final double weightKg;
  final Future<void> Function(ExerciseEntry) onAdd;

  const _AddExerciseSheet({required this.weightKg, required this.onAdd});

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  // Seçili preset veya null (özel giriş)
  int? _selectedPreset;
  final _nameCtrl     = TextEditingController();
  final _durationCtrl = TextEditingController(text: '30');
  bool _saving        = false;

  // Seçili preset bilgileri
  double get _met {
    if (_selectedPreset != null) {
      return ExerciseEntry.presets[_selectedPreset!].met;
    }
    return 5.0; // varsayılan
  }

  String get _name {
    if (_selectedPreset != null) {
      return ExerciseEntry.presets[_selectedPreset!].name;
    }
    return _nameCtrl.text.trim();
  }

  String get _category {
    if (_selectedPreset != null) {
      return ExerciseEntry.presets[_selectedPreset!].category;
    }
    return 'other';
  }

  int get _duration => int.tryParse(_durationCtrl.text) ?? 30;

  int get _previewCalories => ExerciseEntry.calcCalories(
        met: _met,
        durationMin: _duration,
        weightKg: widget.weightKg,
      );

  Future<void> _submit() async {
    final name = _name;
    if (name.isEmpty || _duration <= 0) return;
    setState(() => _saving = true);

    final entry = ExerciseEntry(
      id:             DateTime.now().millisecondsSinceEpoch.toString(),
      name:           name,
      category:       _category,
      met:            _met,
      durationMin:    _duration,
      caloriesBurned: _previewCalories,
      time:           DateTime.now(),
    );

    await widget.onAdd(entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: vc.textMuted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text('Egzersiz Ekle',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: vc.text,
              )),
          const SizedBox(height: 16),

          // Preset listesi
          Text('Aktivite Seç',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: vc.textSub,
                letterSpacing: 0.3,
              )),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: ExerciseEntry.presets.length,
              itemBuilder: (_, i) {
                final preset  = ExerciseEntry.presets[i];
                final sel     = _selectedPreset == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPreset = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? vc.primarySurface : vc.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? vc.primary : vc.border,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          switch (preset.category) {
                            'cardio'      => '🏃',
                            'strength'    => '💪',
                            'flexibility' => '🧘',
                            _             => '⚡',
                          },
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            preset.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                              color: sel ? vc.primary : vc.text,
                            ),
                          ),
                        ),
                        Text(
                          'MET ${preset.met}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: vc.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Süre
          Text('Süre (dakika)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: vc.textSub,
                letterSpacing: 0.3,
              )),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _durationCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: vc.text,
                  ),
                  decoration: InputDecoration(
                    hintText: '30',
                    suffixText: 'dk',
                    suffixStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: vc.textSub,
                    ),
                    filled: true,
                    fillColor: vc.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 14),
              // Önizleme kalori
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      '~$_previewCalories',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    Text(
                      'kcal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: vc.textSub,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_selectedPreset != null && !_saving) ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: vc.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: vc.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text('Ekle',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
