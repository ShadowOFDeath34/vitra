import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/v_theme.dart';

class OnboardingRoutineStep extends StatelessWidget {
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback onNext;

  const OnboardingRoutineStep({
    super.key,
    required this.selectedIds,
    required this.onChanged,
    required this.onNext,
  });

  static const _categories = [
    _Category(
      label: 'Sabah',
      emoji: '🌅',
      routines: [
        _Routine('vitamin',     'Vitamin iç',          'Her sabah vitamin ve takviye al',     Icons.medication_rounded,        Color(0xFF10B981)),
        _Routine('cold_shower', 'Soğuk duş',            'Metabolizmayı uyandır, zihnini açar', Icons.shower_rounded,             Color(0xFF06B6D4)),
        _Routine('meditation',  'Sabah meditasyonu',    'Günde 10 dakika zihnini dinlendir',   Icons.self_improvement_rounded,   Color(0xFF8B5CF6)),
        _Routine('morning_ex',  'Sabah egzersizi',      'Güne enerjik başla',                  Icons.fitness_center_rounded,     Color(0xFFF59E0B)),
        _Routine('daily_plan',  'Günlük plan yap',      'Günün önceliklerini belirle',         Icons.checklist_rounded,          Color(0xFF3B82F6)),
      ],
    ),
    _Category(
      label: 'Gün içi',
      emoji: '☀️',
      routines: [
        _Routine('water_goal',  'Su hedefine ulaş',     'Günlük su hedefini tamamla',          Icons.water_drop_rounded,         Color(0xFF0EA5E9)),
        _Routine('walk',        '10.000 adım',           'Gün içinde aktif kal',                Icons.directions_walk_rounded,    Color(0xFF22C55E)),
        _Routine('lunch_walk',  'Öğle yürüyüşü',        'Öğleden sonra kısa yürüyüş yap',     Icons.park_rounded,               Color(0xFF84CC16)),
        _Routine('fruit_veg',   'Meyve/sebze ye',        'Günde en az 5 porsiyon',              Icons.apple_rounded,              Color(0xFFEF4444)),
      ],
    ),
    _Category(
      label: 'Akşam',
      emoji: '🌙',
      routines: [
        _Routine('read',        'Kitap oku',             'Her gün en az 20 dakika oku',         Icons.menu_book_rounded,          Color(0xFF8B5CF6)),
        _Routine('reflection',  'Günlük reflection',     'Günü değerlendir, minnet yaz',        Icons.edit_note_rounded,          Color(0xFFF59E0B)),
        _Routine('sleep_time',  'Uyku saatini koru',     'Düzenli uyku biyolojik saatini korur',Icons.bedtime_rounded,            Color(0xFF6366F1)),
        _Routine('no_screen',   'Dijital detoks',        'Yatmadan 1 saat önce ekran yok',      Icons.mobile_off_rounded,         Color(0xFF64748B)),
        _Routine('breathing',   'Nefes egzersizi',       '4-7-8 nefes tekniği ile rahatla',     Icons.air_rounded,                Color(0xFF06B6D4)),
        _Routine('stretch',     'Stretching yap',        'Kasları gevşet, esnekliği artır',     Icons.accessibility_new_rounded,  Color(0xFF10B981)),
      ],
    ),
  ];

  void _toggle(String id) {
    final updated = List<String>.from(selectedIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Günlük alışkanlıkların',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: vc.text,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Hangi rutinleri takip etmek istersin?',
          style: TextStyle(fontSize: 15, color: vc.textSub),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: ListView(
            children: [
              for (final cat in _categories) ...[
                _CategoryHeader(label: cat.label, emoji: cat.emoji),
                const SizedBox(height: 8),
                for (final r in cat.routines)
                  _RoutineRow(
                    routine: r,
                    selected: selectedIds.contains(r.id),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _toggle(r.id);
                    },
                  ),
                const SizedBox(height: 12),
              ],

              // İpucu
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: vc.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded,
                        size: 16, color: vc.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Uygulama içinden istediğin kadar özel rutin ekleyebilirsin.',
                        style: TextStyle(
                          fontSize: 12,
                          color: vc.primary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onNext,
            child: Text(
              selectedIds.isEmpty ? 'Atla' : 'Devam Et',
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String label;
  final String emoji;
  const _CategoryHeader({required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: vc.textSub,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _RoutineRow extends StatelessWidget {
  final _Routine routine;
  final bool selected;
  final VoidCallback onTap;

  const _RoutineRow({
    required this.routine,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? routine.color.withValues(alpha: 0.08)
              : vc.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? routine.color.withValues(alpha: 0.5) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: routine.color.withValues(alpha: selected ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(routine.icon, color: routine.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? vc.text : vc.text,
                    ),
                  ),
                  Text(
                    routine.description,
                    style: TextStyle(fontSize: 11, color: vc.textSub),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? routine.color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected
                      ? routine.color
                      : vc.textMuted.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Category {
  final String label;
  final String emoji;
  final List<_Routine> routines;
  const _Category({required this.label, required this.emoji, required this.routines});
}

class _Routine {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  const _Routine(this.id, this.label, this.description, this.icon, this.color);
}
