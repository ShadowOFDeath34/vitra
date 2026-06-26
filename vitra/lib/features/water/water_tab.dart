import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/v_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/daily_log_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/models/water_entry.dart';
import '../../shared/widgets/aurora_bg.dart';

class WaterTab extends ConsumerWidget {
  const WaterTab({super.key});

  static const _mlPerGlass = 250;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log     = ref.watch(dailyLogProvider);
    final profile = ref.watch(userProfileProvider);

    final consumed     = log.waterConsumedMl;
    final goalMl       = profile.waterGoalMl;
    // Bardak sayısı hedeften hesaplanır — en az 4, en fazla 20
    final glassesTotal = goalMl > 0
        ? (goalMl / _mlPerGlass).ceil().clamp(4, 20)
        : 8;
    final progress   = goalMl > 0
        ? (consumed / goalMl).clamp(0.0, 1.0)
        : 0.0;
    final remainingL = goalMl > 0
        ? ((goalMl - consumed) / 1000).clamp(0.0, goalMl / 1000)
        : 0.0;
    final glassesFilled =
        (consumed / _mlPerGlass).floor().clamp(0, glassesTotal);
    final isGoalReached = goalMl > 0 && consumed >= goalMl;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Aurora Hero ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _WaterHero(
              consumed: consumed,
              goalMl: goalMl,
              progress: progress,
              remainingL: remainingL,
              isGoalReached: isGoalReached,
            ),
          ),

          // ── Hızlı Ekle ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _PremiumQuickAdd(
                onAdd: (ml) =>
                    ref.read(dailyLogProvider.notifier).addWater(ml),
              ),
            ),
          ),

          // ── Bardak Sayacı ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _GlassCounter(
                glassesFilled: glassesFilled,
                glassesTotal: glassesTotal,
                onGlassTap: () =>
                    ref.read(dailyLogProvider.notifier).addWater(_mlPerGlass),
              ),
            ),
          ),

          // ── Kayıtlar ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _PremiumLogCard(
                entries: log.waterLog.reversed.toList(),
                onRemove: (id) =>
                    ref.read(dailyLogProvider.notifier).removeWaterEntry(id),
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }
}

// ── Water Hero — Aurora + Wave Ring ──────────────────────────────────────────

class _WaterHero extends StatefulWidget {
  final int consumed;
  final int goalMl;
  final double progress;
  final double remainingL;
  final bool isGoalReached;

  const _WaterHero({
    required this.consumed,
    required this.goalMl,
    required this.progress,
    required this.remainingL,
    required this.isGoalReached,
  });

  @override
  State<_WaterHero> createState() => _WaterHeroState();
}

class _WaterHeroState extends State<_WaterHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final consumedL = (widget.consumed / 1000).toStringAsFixed(2);

    return AuroraBg(
      primaryColor: AppColors.water,
      secondaryColor: const Color(0xFF0EA5E9),
      accentColor: const Color(0xFF7DC8FF),
      primaryOpacity: 0.18,
      duration: const Duration(seconds: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
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
        child: Column(
          children: [
            // Başlık
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Su Takibi',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: vc.text,
                          letterSpacing: -0.8,
                        ),
                      ),
                      if (widget.goalMl > 0)
                        Text(
                          'Hedef: ${(widget.goalMl / 1000).toStringAsFixed(1)} L',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.water,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                // Tamamlama durumu badge
                if (widget.isGoalReached)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.water.withValues(alpha: 0.40),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Hedef!',
                          style: TextStyle(
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

            const SizedBox(height: 28),

            // Büyük dalga gauge
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: widget.progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, animProgress, __) {
                return AnimatedBuilder(
                  animation: _waveCtrl,
                  builder: (_, __) => SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Dış glow halkası
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.water.withValues(
                                    alpha: 0.20 * animProgress),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        // Wave painter
                        CustomPaint(
                          size: const Size(220, 220),
                          painter: _WaveGaugePainter(
                            progress: animProgress,
                            wavePhase: _waveCtrl.value,
                            bgColor: vc.waterSurface,
                          ),
                        ),
                        // İç içerik
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.water_drop_rounded,
                              size: 22,
                              color: animProgress > 0.4
                                  ? Colors.white70
                                  : AppColors.water,
                            ),
                            const SizedBox(height: 4),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                  begin: 0,
                                  end: widget.consumed / 1000),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              builder: (_, v, __) => Text(
                                v.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: animProgress > 0.38
                                      ? Colors.white
                                      : vc.text,
                                  letterSpacing: -1.5,
                                  height: 1,
                                ),
                              ),
                            ),
                            Text(
                              'litre',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: animProgress > 0.38
                                    ? Colors.white70
                                    : vc.textSub,
                              ),
                            ),
                            if (widget.goalMl > 0 && !widget.isGoalReached) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (animProgress > 0.38
                                          ? Colors.white
                                          : AppColors.water)
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${widget.remainingL.toStringAsFixed(2)} L kaldı',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: animProgress > 0.38
                                        ? Colors.white
                                        : AppColors.water,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Progress bar
            if (widget.goalMl > 0) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 6,
                        color: AppColors.water.withValues(alpha: 0.12),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: widget.progress),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: v,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF7DC8FF),
                                      Color(0xFF38BDF8),
                                      Color(0xFF0EA5E9),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.water
                                          .withValues(alpha: 0.55),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(widget.progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.water,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Wave Gauge Painter (premium versiyon) ─────────────────────────────────────

class _WaveGaugePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color bgColor;

  const _WaveGaugePainter({required this.progress, required this.wavePhase, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);

    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius - 1)));

    // Arka plan
    canvas.drawCircle(
        center, radius, Paint()..color = bgColor);

    if (progress > 0) {
      final waterY = size.height * (1 - progress);
      final amplitude = size.height * 0.024;

      // 3 katmanlı dalga — derinlik + ışıltı hissi
      for (var layer = 0; layer < 3; layer++) {
        final phaseOff = layer * math.pi * 0.55;
        final opacity  = layer == 0 ? 0.90 : layer == 1 ? 0.60 : 0.35;
        final yOff     = layer * size.height * 0.010;
        final ampMod   = layer == 2 ? 0.7 : 1.0;

        final path = Path();
        for (double x = 0; x <= size.width; x++) {
          final y = waterY + yOff +
              amplitude * ampMod *
                  math.sin((x / size.width) * 2 * math.pi +
                      wavePhase * 2 * math.pi + phaseOff);
          if (x == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF60C8FF).withValues(alpha: opacity),
              const Color(0xFF0072C6).withValues(alpha: opacity),
            ],
          ).createShader(
              Rect.fromLTWH(0, waterY, size.width, size.height - waterY));
        canvas.drawPath(path, paint);
      }

      // Dalga üstü parlak çizgi
      final shimmerPath = Path();
      for (double x = 0; x <= size.width; x++) {
        final y = waterY +
            amplitude *
                math.sin((x / size.width) * 2 * math.pi +
                    wavePhase * 2 * math.pi);
        if (x == 0) {
          shimmerPath.moveTo(x, y);
        } else {
          shimmerPath.lineTo(x, y);
        }
      }
      canvas.drawPath(
        shimmerPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.45)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }

    canvas.restore();

    // Dış glow kenarlığı
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = AppColors.water.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Sert kenarlık
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = AppColors.water.withValues(alpha: 0.50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_WaveGaugePainter old) =>
      old.progress != progress || old.wavePhase != wavePhase || old.bgColor != bgColor;
}

// ── Premium Quick Add ─────────────────────────────────────────────────────────

class _PremiumQuickAdd extends StatefulWidget {
  final void Function(int ml) onAdd;

  const _PremiumQuickAdd({required this.onAdd});

  @override
  State<_PremiumQuickAdd> createState() => _PremiumQuickAddState();
}

class _PremiumQuickAddState extends State<_PremiumQuickAdd> {
  static const _amounts = [150, 250, 330, 500];
  bool _showCustom = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submitCustom() {
    final val = int.tryParse(_ctrl.text);
    if (val != null && val > 0 && val <= 3000) {
      widget.onAdd(val);
      _ctrl.clear();
      setState(() => _showCustom = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return _PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.water.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_circle_rounded,
                    color: AppColors.water, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Hızlı Ekle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: vc.text,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _showCustom = !_showCustom;
                  if (_showCustom) {
                    Future.delayed(
                      const Duration(milliseconds: 50),
                      () => FocusScope.of(context).nextFocus(),
                    );
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _showCustom
                        ? AppColors.water.withValues(alpha: 0.15)
                        : vc.surfaceHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Özel miktar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _showCustom ? AppColors.water : vc.textSub,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: _amounts.map((ml) {
              final isLast = ml == _amounts.last;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 10),
                  child: _WaterButton(ml: ml, onTap: () => widget.onAdd(ml)),
                ),
              );
            }).toList(),
          ),
          // Özel miktar giriş alanı
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _showCustom
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: vc.surfaceHigh,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.water.withValues(alpha: 0.3),
                              ),
                            ),
                            child: TextField(
                              controller: _ctrl,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: vc.text,
                              ),
                              decoration: InputDecoration(
                                hintText: 'ml girin',
                                hintStyle: TextStyle(color: vc.textMuted),
                                suffixText: 'ml',
                                suffixStyle: TextStyle(
                                  color: vc.textSub,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) => _submitCustom(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _submitCustom,
                          child: Container(
                            height: 46,
                            width: 46,
                            decoration: BoxDecoration(
                              color: AppColors.water,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _WaterButton extends StatefulWidget {
  final int ml;
  final VoidCallback onTap;

  const _WaterButton({required this.ml, required this.onTap});

  @override
  State<_WaterButton> createState() => _WaterButtonState();
}

class _WaterButtonState extends State<_WaterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.water.withValues(alpha: 0.18),
                AppColors.waterDeep.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.water.withValues(alpha: 0.30),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.water.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.water_drop_rounded,
                  size: 18, color: AppColors.water),
              const SizedBox(height: 5),
              Text(
                '+${widget.ml}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.water,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'ml',
                style: TextStyle(fontSize: 9, color: vc.textSub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Glass Counter ─────────────────────────────────────────────────────────────

class _GlassCounter extends StatelessWidget {
  final int glassesFilled;
  final int glassesTotal;
  final VoidCallback onGlassTap;

  const _GlassCounter({
    required this.glassesFilled,
    required this.glassesTotal,
    required this.onGlassTap,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return _PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.water.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_drink_rounded,
                    color: AppColors.water, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Bardak Sayacı',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: vc.text,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.water.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.water.withValues(alpha: 0.25),
                    width: 0.7,
                  ),
                ),
                child: Text(
                  '$glassesFilled / $glassesTotal',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.water,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(glassesTotal, (i) {
              final filled      = i < glassesFilled;
              final isNext      = i == glassesFilled;
              return GestureDetector(
                onTap: isNext ? onGlassTap : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: filled
                        ? AppColors.water.withValues(alpha: 0.18)
                        : isNext
                            ? AppColors.water.withValues(alpha: 0.08)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: filled
                          ? AppColors.water.withValues(alpha: 0.45)
                          : isNext
                              ? AppColors.water.withValues(alpha: 0.20)
                              : vc.border.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                    boxShadow: filled
                        ? [
                            BoxShadow(
                              color: AppColors.water.withValues(alpha: 0.20),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        key: ValueKey(filled),
                        filled
                            ? Icons.local_drink_rounded
                            : Icons.local_drink_outlined,
                        color: filled
                            ? AppColors.water
                            : isNext
                                ? AppColors.water.withValues(alpha: 0.50)
                                : vc.textMuted.withValues(alpha: 0.40),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            'Her bardak yaklaşık 250 ml',
            style: TextStyle(fontSize: 11, color: vc.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Premium Log Card ──────────────────────────────────────────────────────────

class _PremiumLogCard extends StatelessWidget {
  final List<WaterEntry> entries;
  final void Function(String id) onRemove;

  const _PremiumLogCard({required this.entries, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return _PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.water.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_rounded,
                    color: AppColors.water, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Bugünkü Kayıtlar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: vc.text,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              if (entries.isNotEmpty)
                Text(
                  '${entries.length} kayıt',
                  style: TextStyle(fontSize: 12, color: vc.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.water_drop_outlined,
                        size: 36,
                        color: AppColors.water.withValues(alpha: 0.35)),
                    const SizedBox(height: 10),
                    Text(
                      'Henüz su içmedin — haydi başla!',
                      style: TextStyle(
                        fontSize: 13,
                        color: vc.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...entries.map(
              (e) => _PremiumLogRow(
                entry: e,
                onRemove: () => onRemove(e.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _PremiumLogRow extends StatelessWidget {
  final WaterEntry entry;
  final VoidCallback onRemove;

  const _PremiumLogRow({required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    final h = entry.time.hour.toString().padLeft(2, '0');
    final m = entry.time.minute.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.water.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.water.withValues(alpha: 0.20),
                width: 0.7,
              ),
            ),
            child: const Center(
              child: Icon(Icons.water_drop_rounded,
                  size: 16, color: AppColors.water),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$h:$m',
                style: TextStyle(
                  fontSize: 13,
                  color: vc.textSub,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'su içildi',
                style: TextStyle(fontSize: 10, color: vc.textMuted),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${entry.ml} ml',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.water,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 15,
                color: vc.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Premium Card Wrapper ──────────────────────────────────────────────────────

class _PCard extends StatelessWidget {
  final Widget child;
  const _PCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: vc.border.withValues(alpha: 0.7),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.water.withValues(alpha: 0.04),
            blurRadius: 36,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
