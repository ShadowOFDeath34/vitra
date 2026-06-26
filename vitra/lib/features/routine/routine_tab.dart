import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/v_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/daily_log_provider.dart';
import '../../core/providers/premium_provider.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../shared/widgets/aurora_bg.dart';
import '../../shared/widgets/neon_ring.dart';

final _weekRoutineLogsProvider = FutureProvider.autoDispose<Map<String, bool>>((ref) {
  return FirestoreService.instance.fetchWeekRoutineLogs(days: 7);
});

class RoutineTab extends ConsumerStatefulWidget {
  const RoutineTab({super.key});

  @override
  ConsumerState<RoutineTab> createState() => _RoutineTabState();
}

class _RoutineTabState extends ConsumerState<RoutineTab> {
  late final ConfettiController _confetti;
  bool _wasAllDone = false;
  Map<String, Map<String, int>> _routineTimes = {};

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _routineTimes = LocalStorageService.instance.routineNotifTimes;
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _handleTimeTap(String routineId, String routineLabel) async {
    final existing = _routineTimes[routineId];

    if (existing != null) {
      // Zaten saat var — değiştir veya kaldır
      final action = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          final vc = context.vt;
          final h  = existing['hour']!.toString().padLeft(2, '0');
          final m  = existing['minute']!.toString().padLeft(2, '0');
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(routineLabel,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: vc.text)),
                  const SizedBox(height: 4),
                  Text('Mevcut bildirim saati: $h:$m',
                      style: TextStyle(fontSize: 13, color: vc.textSub)),
                  const SizedBox(height: 20),
                  _SheetOption(
                    icon: Icons.edit_rounded,
                    label: 'Saati Değiştir',
                    color: vc.primary,
                    onTap: () => Navigator.pop(ctx, 'change'),
                  ),
                  const SizedBox(height: 8),
                  _SheetOption(
                    icon: Icons.notifications_off_rounded,
                    label: 'Bildirimi Kaldır',
                    color: const Color(0xFFEF4444),
                    onTap: () => Navigator.pop(ctx, 'remove'),
                  ),
                ],
              ),
            ),
          );
        },
      );
      if (action == 'remove') {
        await _clearRoutineTime(routineId);
      } else if (action == 'change') {
        await _pickTime(routineId, routineLabel, existing);
      }
    } else {
      await _pickTime(routineId, routineLabel, null);
    }
  }

  Future<void> _pickTime(
    String routineId,
    String routineLabel,
    Map<String, int>? existing,
  ) async {
    final initial = TimeOfDay(
      hour:   existing?['hour']   ?? 8,
      minute: existing?['minute'] ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: '$routineLabel bildirimi',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    await _setRoutineTime(routineId, routineLabel, picked.hour, picked.minute);
  }

  Future<void> _setRoutineTime(
    String routineId,
    String routineLabel,
    int hour,
    int minute,
  ) async {
    await LocalStorageService.instance.setRoutineNotifTime(routineId, hour, minute);
    await NotificationService.instance.requestPermission();
    await NotificationService.instance.scheduleRoutineNotification(
      routineId:     routineId,
      routineLabel:  routineLabel,
      hour:          hour,
      minute:        minute,
    );
    setState(() {
      _routineTimes = Map.from(_routineTimes)..[routineId] = {'hour': hour, 'minute': minute};
    });
  }

  Future<void> _clearRoutineTime(String routineId) async {
    await LocalStorageService.instance.removeRoutineNotifTime(routineId);
    await NotificationService.instance.cancelRoutineNotification(routineId);
    setState(() {
      _routineTimes = Map.from(_routineTimes)..remove(routineId);
    });
  }

  Future<void> _handleToggle(String id) async {
    final log       = ref.read(dailyLogProvider);
    final routine   = log.routines.firstWhere((r) => r.id == id, orElse: () => log.routines.first);
    final wasDone   = routine.done;
    final isPremium = ref.read(isPremiumProvider);

    ref.read(dailyLogProvider.notifier).toggleRoutine(id);

    // Premium kullanıcıya rutin tamamlandığında AI tepkisi göster
    if (!wasDone && isPremium && mounted) {
      final reaction = await AIService.instance.getRoutineReaction(
        routineName: routine.label,
        completed: true,
        streakDays: log.streakDays,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(reaction,
                        style: const TextStyle(
                            fontSize: 13, height: 1.4)),
                  ),
                ],
              ),
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc       = context.vt;
    final log      = ref.watch(dailyLogProvider);
    final routines = log.routines;
    final done     = log.routinesDoneCount;
    final total    = routines.length;
    final progress = total > 0 ? done / total : 0.0;
    final allDone  = total > 0 && done == total;
    final notifier = ref.read(dailyLogProvider.notifier);

    if (allDone && !_wasAllDone) {
      _confetti.play();
    }
    _wasAllDone = allDone;

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Aurora Hero ─────────────────────────────────────
              SliverToBoxAdapter(
                child: _RoutineHero(
                  streakDays: log.streakDays,
                  done:       done,
                  total:      total,
                  progress:   progress,
                  allDone:    allDone,
                ),
              ),

              // ── Bu Hafta ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _WeekCard(todayDone: allDone, vc: vc),
                ),
              ),

              // ── Rutin Listesi ────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _RoutineListCard(
                    routines:              routines,
                    vc:                    vc,
                    routineTimes:          _routineTimes,
                    onToggle:              (id) => _handleToggle(id),
                    onDelete:              (id) => notifier.removeRoutine(id),
                    onAdd:                 (label) => notifier.addCustomRoutine(label),
                    onTimeTap:             (id, label) => _handleTimeTap(id, label),
                    onReorder:             (o, n) => notifier.reorderRoutines(o, n),
                    disabledDefaults:      notifier.disabledDefaultRoutines,
                    onEnableDefault:       (id) => notifier.enableDefaultRoutine(id),
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            gravity: 0.2,
            emissionFrequency: 0.05,
            colors: [
              vc.primary,
              const Color(0xFFF59E0B),
              const Color(0xFF10B981),
              const Color(0xFFEC4899),
              const Color(0xFF8B5CF6),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Routine Aurora Hero ───────────────────────────────────────────────────────

class _RoutineHero extends StatelessWidget {
  final int streakDays;
  final int done;
  final int total;
  final double progress;
  final bool allDone;

  const _RoutineHero({
    required this.streakDays,
    required this.done,
    required this.total,
    required this.progress,
    required this.allDone,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;

    return AuroraBg(
      primaryColor: AppColors.habits,
      secondaryColor: vc.primary,
      accentColor: AppColors.streak,
      primaryOpacity: 0.18,
      duration: const Duration(seconds: 11),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              vc.surfaceHigh.withValues(alpha: 0.55),
              vc.bg.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: Row(
          children: [
            // Neon ring — rutin ilerleme
            NeonRing(
              progress: progress,
              color: allDone ? AppColors.success : AppColors.habits,
              trackColor: AppColors.habits.withValues(alpha: 0.10),
              size: 160,
              strokeWidth: 13,
              glowRadius: 14,
              animationDuration: const Duration(milliseconds: 1200),
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    allDone ? '✓' : '$done',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: allDone ? AppColors.success : vc.text,
                      height: 1,
                      letterSpacing: -2,
                    ),
                  ),
                  if (!allDone)
                    Text(
                      '/ $total',
                      style: TextStyle(
                        fontSize: 12,
                        color: vc.textSub,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    allDone ? 'Harika!' : 'rutin',
                    style: TextStyle(
                      fontSize: 11,
                      color: allDone ? AppColors.success : vc.textMuted,
                      fontWeight:
                          allDone ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            // Sağ bilgi kolonu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rutinler',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: vc.text,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    allDone
                        ? 'Bugünkü tüm rutinleri\ntamamladın!'
                        : '${(progress * 100).round()}% tamamlandı',
                    style: TextStyle(
                      fontSize: 13,
                      color: allDone ? AppColors.success : vc.textSub,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Seri badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFBB6E),
                          Color(0xFFFF7A45),
                          Color(0xFFFF5722),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7A45).withValues(alpha: 0.40),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '$streakDays gün serisi',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header (artık kullanılmıyor) ──────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int streakDays;
  final VColors vc;
  const _Header({required this.streakDays, required this.vc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Rutinler',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: vc.text,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFFF6D00),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '$streakDays gün',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF6D00),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Progress Card ─────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final int done;
  final int total;
  final double progress;
  final VColors vc;

  const _ProgressCard({
    required this.done,
    required this.total,
    required this.progress,
    required this.vc,
  });

  @override
  Widget build(BuildContext context) {
    final allDone = done == total && total > 0;
    final pct     = (progress * 100).round();

    return _Card(
      vc: vc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Bugünkü Ilerleme',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: vc.text,
                ),
              ),
              const Spacer(),
              Text(
                '$done/$total tamamlandı',
                style: TextStyle(fontSize: 13, color: vc.textSub),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: vc.primarySurface,
              valueColor: AlwaysStoppedAnimation<Color>(vc.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            allDone
                ? 'Harika! Bugün tüm rutinlerini tamamladın!'
                : '$pct% tamamlandı',
            style: TextStyle(
              fontSize: 12,
              color: allDone ? vc.primary : vc.textSub,
              fontWeight: allDone ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Week Card ─────────────────────────────────────────────────────────────────

class _WeekCard extends ConsumerWidget {
  final bool todayDone;
  final VColors vc;
  const _WeekCard({required this.todayDone, required this.vc});

  static const _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now   = DateTime.now();
    final today = now.weekday;
    final histAsync = ref.watch(_weekRoutineLogsProvider);
    final hist = histAsync.valueOrNull ?? {};

    return _Card(
      vc: vc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bu Hafta',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: vc.text,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final dayNum  = i + 1;
              final isToday = dayNum == today;
              final isPast  = dayNum < today;

              // Past day date key
              final d = now.subtract(Duration(days: today - dayNum));
              final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
              final pastDone = hist[key];

              Color circleBg;
              Color borderColor;
              Widget? child;

              if (isToday) {
                circleBg    = todayDone ? vc.primary : vc.primarySurface;
                borderColor = vc.primary;
                child = todayDone
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : null;
              } else if (isPast) {
                if (pastDone == true) {
                  circleBg    = const Color(0xFF22C55E);
                  borderColor = const Color(0xFF22C55E);
                  child       = const Icon(Icons.check_rounded, color: Colors.white, size: 14);
                } else if (pastDone == false) {
                  circleBg    = Colors.red.withValues(alpha: 0.12);
                  borderColor = Colors.red.withValues(alpha: 0.3);
                  child       = Center(
                    child: Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                } else {
                  // No data yet (loading)
                  circleBg    = vc.primarySurface;
                  borderColor = vc.primarySurface;
                  child       = null;
                }
              } else {
                circleBg    = Colors.transparent;
                borderColor = vc.textMuted.withValues(alpha: 0.4);
                child       = null;
              }

              return Column(
                children: [
                  Text(
                    _days[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isToday ? vc.primary : vc.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleBg,
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: child != null ? Center(child: child) : null,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Routine List ──────────────────────────────────────────────────────────────

class _RoutineListCard extends StatelessWidget {
  final List<RoutineEntry> routines;
  final VColors vc;
  final Map<String, Map<String, int>> routineTimes;
  final void Function(String id) onToggle;
  final void Function(String id) onDelete;
  final void Function(String label) onAdd;
  final void Function(String id, String label) onTimeTap;
  final void Function(int oldIndex, int newIndex) onReorder;
  final List<RoutineEntry> disabledDefaults;
  final void Function(String id) onEnableDefault;

  const _RoutineListCard({
    required this.routines,
    required this.vc,
    required this.routineTimes,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
    required this.onTimeTap,
    required this.onReorder,
    required this.disabledDefaults,
    required this.onEnableDefault,
  });

  static const _icons = <String, IconData>{
    'vitamin':      Icons.medication_rounded,
    'cold_shower':  Icons.shower_rounded,
    'meditation':   Icons.self_improvement_rounded,
    'morning_ex':   Icons.fitness_center_rounded,
    'daily_plan':   Icons.checklist_rounded,
    'water_goal':   Icons.water_drop_rounded,
    'walk':         Icons.directions_walk_rounded,
    'lunch_walk':   Icons.park_rounded,
    'fruit_veg':    Icons.apple_rounded,
    'read':         Icons.menu_book_rounded,
    'reflection':   Icons.edit_note_rounded,
    'sleep_time':   Icons.bedtime_rounded,
    'no_screen':    Icons.mobile_off_rounded,
    'breathing':    Icons.air_rounded,
    'stretch':      Icons.accessibility_new_rounded,
  };

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rutin Ekle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'örn. Kitap oku, Egzersiz yap...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final label = controller.text.trim();
              if (label.isNotEmpty) onAdd(label);
              Navigator.pop(ctx);
            },
            child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      vc: vc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Günlük Rutinler',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: vc.text,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showAddDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: vc.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: vc.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Ekle',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: vc.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (routines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.checklist_rounded,
                      size: 44,
                      color: vc.textMuted.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Henüz rutin yok',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: vc.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Alışkanlık ekleyerek başla.',
                      style: TextStyle(fontSize: 12, color: vc.textMuted),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => onAdd(''),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: vc.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: vc.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 16, color: vc.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Rutin Ekle',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: vc.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: onReorder,
              proxyDecorator: (child, _, animation) => Material(
                elevation: 0,
                color: Colors.transparent,
                child: child,
              ),
              children: [
                for (final r in routines)
                  _RoutineRow(
                    key: ValueKey(r.id),
                    entry:     r,
                    icon:      _icons[r.id] ?? Icons.check_circle_outline_rounded,
                    vc:        vc,
                    time:      routineTimes[r.id],
                    onToggle:  () => onToggle(r.id),
                    onDelete:  () => onDelete(r.id),
                    onTimeTap: () => onTimeTap(r.id, r.label),
                  ),
              ],
            ),
          if (disabledDefaults.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Kaldırılan Varsayılan Rutinler',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: vc.textMuted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: disabledDefaults.map((r) => GestureDetector(
                onTap: () => onEnableDefault(r.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: vc.surfaceHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: vc.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: vc.primary),
                      const SizedBox(width: 5),
                      Text(
                        r.label,
                        style: TextStyle(fontSize: 12, color: vc.textSub, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  final RoutineEntry entry;
  final IconData icon;
  final VColors vc;
  final Map<String, int>? time;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final VoidCallback onTimeTap;

  const _RoutineRow({
    super.key,
    required this.entry,
    required this.icon,
    required this.vc,
    required this.onTimeTap,
    this.time,
    required this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
      ),
      confirmDismiss: (_) async {
        if (onDelete == null) return false;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Rutini Sil'),
            content: Text('"${entry.label}" rutinini silmek istiyor musun?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sil',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        );
        return confirm ?? false;
      },
      onDismissed: (_) => onDelete?.call(),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: entry.done ? 0.55 : 1.0,
        child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: entry.done ? vc.primary : vc.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: entry.done ? Colors.white : vc.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: entry.done
                            ? vc.textMuted.withValues(alpha: 0.6)
                            : vc.text,
                      ),
                    ),
                    if (entry.isCustom)
                      Text(
                        'Özel rutin · sola kaydır sil',
                        style: TextStyle(fontSize: 10, color: vc.textMuted),
                      ),
                  ],
                ),
              ),
              // Bildirim saati chip'i
              GestureDetector(
                onTap: onTimeTap,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: time != null ? vc.primarySurface : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: time != null
                          ? vc.primary.withValues(alpha: 0.3)
                          : vc.textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        time != null
                            ? Icons.notifications_active_rounded
                            : Icons.add_alarm_rounded,
                        size: 13,
                        color: time != null ? vc.primary : vc.textMuted,
                      ),
                      if (time != null) ...[
                        const SizedBox(width: 3),
                        Text(
                          '${time!['hour']!.toString().padLeft(2, '0')}:${time!['minute']!.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: vc.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: entry.done ? vc.primary : Colors.transparent,
                  border: Border.all(
                    color: entry.done ? vc.primary : vc.textMuted,
                    width: 2,
                  ),
                ),
                child: entry.done
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// ── Sheet Option ──────────────────────────────────────────────────────────────

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Kart Wrapper ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final VColors vc;
  const _Card({required this.child, required this.vc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vc.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
