import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/v_theme.dart';
import '../../core/providers/daily_log_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/providers/premium_provider.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/local_storage_service.dart';
import '../../shared/widgets/aurora_bg.dart';

// Haftalık rapor — ilk kullanımdan 1 hafta sonra başlar, haftada 1 üretilir
final _weeklyReportProvider = FutureProvider<String>((ref) async {
  final ls = LocalStorageService.instance;

  // Henüz 1 hafta olmadıysa: bilgilendirici mesaj döner, AI çağrısı olmaz
  final firstUse = ls.firstUseDate;
  if (firstUse == null) return _weeklyNotReadyText;
  final daysSinceStart = DateTime.now().difference(firstUse).inDays;
  if (daysSinceStart < 7) return _weeklyNotReadyText;

  // Cache kontrolü — aynı hafta içinde tekrar üretme
  final cached = ls.cachedWeeklyReport;
  if (cached != null) return cached;

  // Cache yok → Firestore'dan gerçek 7-gün verisi çek
  final profile = ref.read(userProfileProvider);
  final log     = ref.read(dailyLogProvider);
  final history = await FirestoreService.instance.fetchLastNDays(7);

  double totalCalPct = 0, totalWatPct = 0, totalRutPct = 0;
  int calDays = 0, watDays = 0, rutDays = 0;

  for (final data in history.values) {
    final consumed     = (data['caloriesConsumed'] as num?)?.toInt() ?? 0;
    final waterMl      = (data['waterConsumedMl']  as num?)?.toInt() ?? 0;
    final routinesList = data['routines'] as List<dynamic>? ?? [];
    final total        = routinesList.length;
    final done         = routinesList.where((r) => r['isDone'] == true).length;

    if (profile.calorieGoal > 0 && consumed > 0) {
      totalCalPct += (consumed / profile.calorieGoal * 100).clamp(0, 100);
      calDays++;
    }
    if (profile.waterGoalMl > 0 && waterMl > 0) {
      totalWatPct += (waterMl / profile.waterGoalMl * 100).clamp(0, 100);
      watDays++;
    }
    if (total > 0) {
      totalRutPct += (done / total * 100);
      rutDays++;
    }
  }

  final avgCal = calDays > 0 ? totalCalPct / calDays : 0.0;
  final avgWat = watDays > 0 ? totalWatPct / watDays : 0.0;
  final avgRut = rutDays > 0 ? totalRutPct / rutDays : 0.0;

  final report = await AIService.instance.getWeeklyReport(
    calorieGoal:              profile.calorieGoal,
    avgCaloriesPercent:       avgCal,
    avgWaterPercent:          avgWat,
    routineCompletionPercent: avgRut,
    bestStreakDays:           log.streakDays,
  );

  await ls.saveWeeklyReportCache(report);
  return report;
});

const _weeklyNotReadyText = '''
Haftalık raporun hazır değil.

Vitra, anlamlı bir haftalık analiz için 7 gün veriye ihtiyaç duyuyor. Bu süre dolduğunda burada kişisel bir rapor göreceksin: hangi alanlarda güçlüsün, nerede sürçüyorsun, ve somut öneriler.

Şimdilik yap: bugünkü rutinini tamamla, su hedefine ulaş, bir şeyler ye ve kaydet.
''';


// ── Chat mesaj modeli — kalıcı saklama destekli ───────────────────────────────

class _ChatMessage {
  final String   text;
  final bool     isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'role': isUser ? 'user' : 'assistant',
    'text': text,
    'ts':   timestamp.millisecondsSinceEpoch,
  };

  factory _ChatMessage.fromMap(Map<String, dynamic> m) => _ChatMessage(
    text:      m['text'] as String? ?? '',
    isUser:    m['role'] == 'user',
    timestamp: m['ts'] != null
        ? DateTime.fromMillisecondsSinceEpoch(m['ts'] as int)
        : DateTime.now(),
  );
}

// ── Ana widget ────────────────────────────────────────────────────────────────

class CoachTab extends ConsumerStatefulWidget {
  const CoachTab({super.key});

  @override
  ConsumerState<CoachTab> createState() => _CoachTabState();
}

class _CoachTabState extends ConsumerState<CoachTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _chatCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _chatLoading = false;

  // Çoklu sohbet arşivi
  List<Map<String, dynamic>> _archivedConvs = [];
  bool _archivedLoaded = false;

  // Free limit — premium olmayan kullanıcı günde 5 mesaj
  static const _freeLimit = 5;
  int _coachUsedToday = 0;

  // Brifing — manuel yönetim (FutureProvider yerine, cache destekli)
  String? _briefingText;
  bool    _briefingError   = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _coachUsedToday = LocalStorageService.instance.coachChatTodayCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
      _loadBriefing();
      // Haftalık raporu arka planda ön yükle — sheet açıldığında hazır olsun
      ref.read(_weeklyReportProvider);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Kalıcı geçmiş yönetimi ────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    // Önce local'den yükle
    var stored = LocalStorageService.instance.coachChatHistory;

    // Local boşsa Firestore'dan dene (yeni cihaz / yeniden kurulum)
    if (stored.isEmpty) {
      final remote = await FirestoreService.instance.fetchCoachHistory();
      if (remote != null && remote.isNotEmpty) {
        stored = remote;
        // Local'e de kaydet
        await LocalStorageService.instance.saveCoachChatHistory(stored);
      }
    }

    if (stored.isEmpty || !mounted) return;
    setState(() {
      _messages.addAll(stored.map(_ChatMessage.fromMap).toList());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _saveHistory() async {
    final maps = _messages.map((m) => m.toMap()).toList();
    await LocalStorageService.instance.saveCoachChatHistory(maps);
    // Firestore'a da sync et (fire-and-forget)
    FirestoreService.instance.saveCoachHistory(maps);
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:   const Text('Sohbeti Sil'),
        content: const Text('Bu sohbet kalıcı olarak silinecek. Devam?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:     const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sil',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await LocalStorageService.instance.clearCoachChatHistory();
      FirestoreService.instance.clearCoachHistory();
      setState(() => _messages.clear());
    }
  }

  Future<void> _newConversation() async {
    if (_messages.isEmpty) return;
    // Mevcut sohbeti arşive kaydet
    final maps = _messages.map((m) => m.toMap()).toList();
    FirestoreService.instance.archiveConversation(maps);
    // Temizle
    await LocalStorageService.instance.clearCoachChatHistory();
    FirestoreService.instance.clearCoachHistory();
    if (!mounted) return;
    setState(() {
      _messages.clear();
      _archivedLoaded = false; // listeyi bir sonraki açılışta yenile
    });
  }

  Future<void> _loadArchivedConversations() async {
    if (_archivedLoaded) return;
    final list = await FirestoreService.instance.fetchConversationList();
    if (!mounted) return;
    setState(() {
      _archivedConvs  = list;
      _archivedLoaded = true;
    });
  }

  Future<void> _resumeConversation(String id) async {
    final messages = await FirestoreService.instance.loadConversation(id);
    if (messages == null || !mounted) return;
    // Mevcut sohbeti arşive kaydet (eğer varsa)
    if (_messages.isNotEmpty) {
      final maps = _messages.map((m) => m.toMap()).toList();
      FirestoreService.instance.archiveConversation(maps);
    }
    final parsed = messages.map(_ChatMessage.fromMap).toList();
    await LocalStorageService.instance.saveCoachChatHistory(messages);
    FirestoreService.instance.saveCoachHistory(messages);
    if (!mounted) return;
    setState(() {
      _messages.clear();
      _messages.addAll(parsed);
      _archivedLoaded = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _showConversationHistory() {
    _loadArchivedConversations();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ConversationHistorySheet(
        conversations: _archivedConvs,
        onResume: (id) {
          Navigator.pop(ctx);
          _resumeConversation(id);
        },
        onDelete: (id) async {
          await FirestoreService.instance.deleteConversation(id);
          if (mounted) {
            setState(() {
              _archivedConvs.removeWhere((c) => c['id'] == id);
            });
          }
        },
      ),
    );
  }

  // ── Brifing yükleme — cache kontrolü ─────────────────────────────────────

  Future<void> _loadBriefing() async {
    final cached = LocalStorageService.instance.cachedBriefing;
    if (cached != null && cached.isNotEmpty) {
      if (mounted) setState(() => _briefingText = cached);
      return;
    }

    if (!mounted) return;
    setState(() { _briefingError = false; });

    final log     = ref.read(dailyLogProvider);
    final profile = ref.read(userProfileProvider);

    try {
      final text = await AIService.instance.getDailyBriefing(
        calorieGoal:      profile.calorieGoal,
        caloriesConsumed: log.caloriesConsumed,
        waterGoalMl:      profile.waterGoalMl,
        waterConsumedMl:  log.waterConsumedMl,
        routinesDone:     log.routinesDoneCount,
        routinesTotal:    log.routines.length,
        streakDays:       log.streakDays,
        userName:         profile.userName.isNotEmpty ? profile.userName : null,
      );
      await LocalStorageService.instance.saveBriefingCache(text);
      if (mounted) setState(() { _briefingText = text; });
    } catch (_) {
      if (mounted) setState(() { _briefingError = true; });
    }
  }

  Future<void> _refreshBriefing() async {
    await LocalStorageService.instance.clearBriefingCache();
    if (!mounted) return;
    setState(() { _briefingText = null; _briefingError = false; });
    await _loadBriefing();
  }

  // ── Chat gönder ────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty || _chatLoading) return;

    final isPremium = ref.read(isPremiumProvider);

    // Free limit kontrolü
    if (!isPremium && _coachUsedToday >= _freeLimit) {
      setState(() {
        _messages.add(_ChatMessage(
          text: 'Bugünkü $_freeLimit mesaj hakkını kullandın. '
              'Premium\'a geçerek sınırsız koç desteği alabilirsin.',
          isUser: false,
        ));
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _chatLoading = true;
    });
    _chatCtrl.clear();
    _scrollToBottom();

    final log     = ref.read(dailyLogProvider);
    final profile = ref.read(userProfileProvider);

    // Sayacı artır
    if (isPremium) {
      await LocalStorageService.instance.incrementPremiumChatFlashCount();
    } else {
      await LocalStorageService.instance.incrementCoachChatCount();
      setState(() => _coachUsedToday++);
    }

    // Premium: son 30 mesaj, Free: son 12 mesaj
    final windowSize  = isPremium ? 30 : 12;
    final windowEnd   = _messages.length - 1;
    final windowStart = (windowEnd - windowSize).clamp(0, windowEnd);
    final history = _messages
        .sublist(windowStart, windowEnd)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'text': m.text})
        .toList();

    final String reply;
    if (isPremium) {
      // Günlük Flash limiti dolmadıysa Flash, dolduysa Lite
      final flashUsed  = LocalStorageService.instance.premiumChatFlashTodayCount;
      final useFlash   = flashUsed <= LocalStorageService.premiumDailyFlashLimit;
      reply = await AIService.instance.chat(
        userMessage:      text,
        calorieGoal:      profile.calorieGoal,
        caloriesConsumed: log.caloriesConsumed,
        waterGoalMl:      profile.waterGoalMl,
        waterConsumedMl:  log.waterConsumedMl,
        routinesDone:     log.routinesDoneCount,
        routinesTotal:    log.routines.length,
        streakDays:       log.streakDays,
        userName:         profile.userName.isNotEmpty ? profile.userName : null,
        history:          history,
        useFlash:         useFlash,
      );
    } else {
      reply = await AIService.instance.chatFree(
        userMessage:      text,
        calorieGoal:      profile.calorieGoal,
        caloriesConsumed: log.caloriesConsumed,
        waterGoalMl:      profile.waterGoalMl,
        waterConsumedMl:  log.waterConsumedMl,
        routinesDone:     log.routinesDoneCount,
        routinesTotal:    log.routines.length,
        streakDays:       log.streakDays,
      );
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _chatLoading = false;
    });
    _scrollToBottom();
    await _saveHistory();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildTodayTab(),
              _buildChatTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final vc      = context.vt;
    final log     = ref.watch(dailyLogProvider);
    final profile = ref.watch(userProfileProvider);

    final calPct = profile.calorieGoal > 0
        ? log.caloriesConsumed / profile.calorieGoal
        : 0.0;
    final watPct = profile.waterGoalMl > 0
        ? log.waterConsumedMl / profile.waterGoalMl
        : 0.0;
    final rutPct = log.routines.isNotEmpty
        ? log.routinesDoneCount / log.routines.length
        : 0.0;

    return SizedBox(
      height: 155,
      child: AuroraBg(
        primaryColor:   AppColors.coach,
        secondaryColor: vc.primary,
        accentColor:    AppColors.gold,
        primaryOpacity: vc.isDark ? 0.22 : 0.16,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.65, 1.0],
                    colors: [Colors.transparent, Colors.transparent, vc.bg],
                  ),
                ),
              ),
            ),
            Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColors.coach.withValues(alpha: 0.30),
                          AppColors.coach.withValues(alpha: 0.14),
                        ]),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: AppColors.coach.withValues(alpha: 0.45),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.coach.withValues(alpha: 0.32),
                            blurRadius: 14,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.psychology_rounded,
                          color: AppColors.coach, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Koçun',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: vc.text,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Kişisel sağlık koçun — her zaman burada',
                          style: TextStyle(fontSize: 12, color: vc.textSub),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _CoachStatChip(label: 'Kalori', pct: calPct, color: vc.primary),
                    const SizedBox(width: 8),
                    _CoachStatChip(label: 'Su', pct: watPct, color: AppColors.water),
                    const SizedBox(width: 8),
                    _CoachStatChip(label: 'Rutin', pct: rutPct, color: AppColors.gold),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildTabBar() {
    final vc = context.vt;
    return Container(
      color: vc.bg,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: vc.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: vc.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabCtrl,
          labelColor:            vc.primary,
          unselectedLabelColor:  vc.textMuted,
          indicatorColor:        Colors.transparent,
          dividerColor:          Colors.transparent,
          indicator: BoxDecoration(
            gradient: LinearGradient(colors: [
              vc.primary.withValues(alpha: 0.20),
              vc.primaryGlow.withValues(alpha: 0.12),
            ]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: vc.primary.withValues(alpha: 0.35)),
          ),
          indicatorSize:  TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          tabs: const [
            Tab(text: 'Bugün'),
            Tab(text: 'Sor'),
          ],
        ),
      ),
    );
  }

  // ── Bugün tab ─────────────────────────────────────────────────────────────

  Widget _buildTodayTab() {
    final vc      = context.vt;
    final log     = ref.watch(dailyLogProvider);
    final profile = ref.watch(userProfileProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _AiCard(
            icon:      Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFF59E0B),
            title:     _greetingTitle(),
            trailing:  _briefingText != null
                ? GestureDetector(
                    onTap: _refreshBriefing,
                    child: Icon(Icons.refresh_rounded,
                        size: 16, color: vc.textSub),
                  )
                : null,
            child: _buildBriefingContent(),
          ),
          const SizedBox(height: 16),

          _AiCard(
            icon:      Icons.bar_chart_rounded,
            iconColor: vc.primary,
            title:     'Bugünkü Durum',
            child: Column(
              children: [
                _StatRow(
                  label:   'Kalori',
                  value:   '${log.caloriesConsumed} / ${profile.calorieGoal} kcal',
                  percent: profile.calorieGoal > 0
                      ? log.caloriesConsumed / profile.calorieGoal
                      : 0,
                  color: vc.primary,
                ),
                const SizedBox(height: 10),
                _StatRow(
                  label:   'Su',
                  value:   '${(log.waterConsumedMl / 1000).toStringAsFixed(1)}L / ${(profile.waterGoalMl / 1000).toStringAsFixed(1)}L',
                  percent: profile.waterGoalMl > 0
                      ? log.waterConsumedMl / profile.waterGoalMl
                      : 0,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(height: 10),
                _StatRow(
                  label:   'Rutin',
                  value:   '${log.routinesDoneCount} / ${log.routines.length}',
                  percent: log.routines.isNotEmpty
                      ? log.routinesDoneCount / log.routines.length
                      : 0,
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: () => _tabCtrl.animateTo(2),
            child: Container(
              width:   double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color:         vc.primarySurface,
                borderRadius:  BorderRadius.circular(16),
                border:        Border.all(color: vc.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      color: vc.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Koçuna bir şey sor',
                        style: TextStyle(
                          fontSize:   14,
                          color:      vc.primary,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: vc.primary, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBriefingContent() {
    final vc = context.vt;
    if (_briefingError) {
      return Row(
        children: [
          Text('Yüklenemedi. ',
              style: TextStyle(color: vc.textSub, fontSize: 14)),
          GestureDetector(
            onTap: _loadBriefing,
            child: Text('Tekrar dene',
                style: TextStyle(
                    color:      vc.primary,
                    fontSize:   14,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      );
    }
    if (_briefingText != null) {
      return Text(
        _briefingText!,
        style: TextStyle(
          fontSize: 15,
          color:    vc.text,
          height:   1.6,
        ),
      );
    }
    return _shimmer();
  }

  // ── Bu Hafta tab ──────────────────────────────────────────────────────────

  // ── Sor tab (Chat) ────────────────────────────────────────────────────────

  Widget _buildChatTab() {
    final vc        = context.vt;
    final isPremium = ref.watch(isPremiumProvider);

    return Column(
      children: [
        if (!isPremium) _freeBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Row(
              children: [
                // Geçmiş konuşmalar
                GestureDetector(
                  onTap: _showConversationHistory,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded,
                          size: 15, color: vc.textSub.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text('Geçmiş',
                          style: TextStyle(fontSize: 12,
                              color: vc.textSub.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                const Spacer(),
                if (_messages.isNotEmpty) ...[
                  // Yeni sohbet
                  GestureDetector(
                    onTap: _newConversation,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline_rounded,
                            size: 15, color: vc.primary.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text('Yeni Sohbet',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: vc.primary.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Sil
                  GestureDetector(
                    onTap: _clearChat,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 15,
                            color: vc.textSub.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text('Sil',
                            style: TextStyle(
                                fontSize: 12,
                                color: vc.textSub.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        Expanded(
          child: _messages.isEmpty
              ? _chatEmpty()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _messages.length + (_chatLoading ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == _messages.length) return _typingIndicator();
                    return _ChatBubble(message: _messages[i]);
                  },
                ),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _freeBanner() {
    final vc        = context.vt;
    final remaining = (_freeLimit - _coachUsedToday).clamp(0, _freeLimit);
    final isOut     = remaining == 0;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/premium'),
      child: Container(
        margin:  const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:        isOut
              ? const Color(0xFFFEF2F2)
              : vc.primarySurface,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(
            color: isOut
                ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                : vc.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isOut ? Icons.block_rounded : Icons.auto_awesome_rounded,
              color: isOut ? const Color(0xFFEF4444) : vc.primary,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isOut
                    ? 'Bugünkü mesaj hakkın bitti. Premium\'a geç.'
                    : 'Bugün $remaining mesaj hakkın kaldı. Premium\'da sınırsız.',
                style: TextStyle(
                  fontSize: 12,
                  color: isOut ? const Color(0xFFEF4444) : vc.primary,
                ),
              ),
            ),
            Text('Yükselt →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isOut ? const Color(0xFFEF4444) : vc.primary,
                )),
          ],
        ),
      ),
    );
  }

  Widget _chatEmpty() {
    final vc      = context.vt;
    final log     = ref.read(dailyLogProvider);
    final profile = ref.read(userProfileProvider);
    final hour    = DateTime.now().hour;

    final suggestions = <String>[];
    if (hour < 12) {
      suggestions.addAll([
        'Bugün kahvaltıda ne yemeliyim?',
        'Güne nasıl başlamalıyım?',
      ]);
    } else if (hour < 17) {
      suggestions.addAll([
        'Öğleden sonra enerjimi nasıl tutarım?',
        'Bu saatte ne atıştırabilirim?',
      ]);
    } else {
      suggestions.addAll([
        'Akşam yemeği için ne önerirsin?',
        'Bugünü nasıl kapatsam iyi olur?',
      ]);
    }

    final calPct = profile.calorieGoal > 0
        ? log.caloriesConsumed / profile.calorieGoal
        : 0.0;
    final watPct = profile.waterGoalMl > 0
        ? log.waterConsumedMl / profile.waterGoalMl
        : 0.0;

    if (calPct > 0.9) {
      suggestions.add('Kalorim neredeyse doldu, ne yapmalıyım?');
    } else if (calPct < 0.3 && hour > 14) {
      suggestions.add('Az yedim, bunu nasıl telafi ederim?');
    }
    if (watPct < 0.5) {
      suggestions.add('Su içmeyi nasıl alışkanlık yaparım?');
    }
    if (log.streakDays >= 7) {
      suggestions.add('${log.streakDays} günlük serim ne anlama geliyor?');
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  64,
              height: 64,
              decoration: BoxDecoration(
                color:        vc.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.psychology_rounded,
                  color: vc.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Koçuna sor',
                style: TextStyle(
                    fontSize:   16,
                    fontWeight: FontWeight.w600,
                    color:      vc.text)),
            const SizedBox(height: 6),
            Text(
              'Beslenme, rutin, motivasyon — her konuda burada.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: vc.textSub),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing:   8,
              runSpacing: 8,
              alignment:  WrapAlignment.center,
              children:   suggestions.take(4).map((s) {
                return GestureDetector(
                  onTap: () {
                    _chatCtrl.text = s;
                    _sendMessage();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color:        vc.surface,
                      borderRadius: BorderRadius.circular(20),
                      border:       Border.all(
                          color: vc.border),
                    ),
                    child: Text(s,
                        style: TextStyle(
                            fontSize: 13, color: vc.text)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    final vc        = context.vt;
    final isPremium = ref.read(isPremiumProvider);
    final isOut     = !isPremium && _coachUsedToday >= _freeLimit;

    final bottomPad = MediaQuery.of(context).viewInsets.bottom > 0
        ? MediaQuery.of(context).viewInsets.bottom + 16
        : MediaQuery.of(context).padding.bottom + 16;

    if (isOut) {
      return Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
        decoration: BoxDecoration(
          color:  vc.surface,
          border: Border(top: BorderSide(color: vc.border)),
        ),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pushNamed('/premium'),
          child: Container(
            width:  double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [vc.primary, vc.primaryGlow]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color:      vc.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset:     const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
                SizedBox(width: 8),
                Text(
                  'Premium\'a Geç — Sınırsız Koç',
                  style: TextStyle(
                    color:      Colors.white,
                    fontSize:   14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
      decoration: BoxDecoration(
        color:  vc.surface,
        border: Border(top: BorderSide(color: vc.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Araç çubuğu — haftalık rapor butonu
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (!isPremium) {
                    Navigator.of(context).pushNamed('/premium');
                    return;
                  }
                  _showWeeklyReportSheet(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 13,
                        color: isPremium
                            ? const Color(0xFF8B5CF6)
                            : vc.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Haftalık Rapor',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPremium
                              ? const Color(0xFF8B5CF6)
                              : vc.textMuted,
                        ),
                      ),
                      if (!isPremium) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.lock_rounded, size: 10, color: vc.textMuted),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller:       _chatCtrl,
                  onSubmitted:      (_) => _sendMessage(),
                  textInputAction:  TextInputAction.send,
                  maxLines:         null,
                  style: TextStyle(fontSize: 15, color: vc.text),
                  decoration: InputDecoration(
                    hintText:  'Bugün nasıl hissediyorsunuz?',
                    hintStyle: TextStyle(color: vc.textMuted, fontSize: 14),
                    filled:    true,
                    fillColor: vc.surface,
                    border:    OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:   BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _chatLoading ? null : _sendMessage,
                child: Container(
                  width:  44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:  _chatLoading ? vc.textMuted : vc.primary,
                    shape:  BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }

  void _showWeeklyReportSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) {
          final vc = ctx.vt;
          final weekly = ref.watch(_weeklyReportProvider);
          return Container(
            decoration: BoxDecoration(
              color: vc.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: vc.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_month_rounded,
                            color: Color(0xFF8B5CF6), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Haftalık Rapor',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: vc.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: weekly.when(
                      data: (text) => Text(
                        text,
                        style: TextStyle(
                          fontSize: 15,
                          color: vc.text,
                          height: 1.6,
                        ),
                      ),
                      loading: () => _shimmer(),
                      error: (e, s) => Text(
                        'Rapor alınamadı.',
                        style: TextStyle(color: vc.textSub),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _typingIndicator() {
    final vc = context.vt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width:  32,
            height: 32,
            decoration: BoxDecoration(
              color:        vc.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.psychology_rounded,
                color: vc.primary, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color:        vc.surface,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(16),
                topRight:    Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft:  Radius.circular(4),
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _shimmer() {
    final vc = context.vt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          height: 14,
          width:  i == 2 ? 120 : double.infinity,
          decoration: BoxDecoration(
            color:        vc.textMuted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      )),
    );
  }

  String _greetingTitle() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Günaydın';
    if (h < 17) return 'İyi günler';
    return 'İyi akşamlar';
  }
}

// ── Yazıyor animasyonu (3 nokta pulses) ───────────────────────────────────────

// ── Coach Header Stat Chip ────────────────────────────────────────────────────

class _CoachStatChip extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;

  const _CoachStatChip({
    required this.label,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: vc.surface.withValues(alpha: vc.isDark ? 0.75 : 0.90),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '${(pct * 100).clamp(0, 999).round()}%',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: vc.textMuted),
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return SizedBox(
      width:  40,
      height: 16,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (i) {
              final t     = (_ctrl.value + i / 3) % 1.0;
              final scale = 0.5 + 0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width:  7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: vc.textSub,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ── Alt bileşenler ────────────────────────────────────────────────────────────

class _AiCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final Widget   child;
  final Widget?  trailing;

  const _AiCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        vc.surface,
        borderRadius: BorderRadius.circular(24),
        border:       Border.all(color: iconColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: iconColor.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width:  36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    iconColor.withValues(alpha: 0.22),
                    iconColor.withValues(alpha: 0.10),
                  ]),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: iconColor.withValues(alpha: 0.32)),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.22),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                      color:      vc.text,
                    )),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final double percent;
  final Color  color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontSize: 13, color: vc.textSub)),
            Text(value,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: vc.text)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value:            percent.clamp(0.0, 1.0),
          backgroundColor:  color.withValues(alpha: 0.12),
          valueColor:       AlwaysStoppedAnimation(color),
          borderRadius:     BorderRadius.circular(4),
          minHeight:        6,
        ),
      ],
    );
  }
}

// ── Premium kilit ekranı ──────────────────────────────────────────────────────

class _PremiumLockScreen extends StatelessWidget {
  final IconData     icon;
  final Color        iconColor;
  final String       title;
  final String       description;
  final VoidCallback onUpgrade;

  const _PremiumLockScreen({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  72,
              height: 72,
              decoration: BoxDecoration(
                color:        iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: iconColor, size: 34),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color:        const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.lock_rounded, size: 12, color: Color(0xFFF59E0B)),
                  SizedBox(width: 5),
                  Text('Premium',
                      style: TextStyle(
                        fontSize:      11,
                        fontWeight:    FontWeight.w700,
                        color:         Color(0xFFF59E0B),
                        letterSpacing: 0.5,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.w700,
                  color:      vc.text,
                )),
            const SizedBox(height: 10),
            Text(description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color:    vc.textSub,
                  height:   1.6,
                )),
            const SizedBox(height: 28),
            SizedBox(
              width:  double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onUpgrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: vc.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Premium\'a Geç',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width:  34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.coach.withValues(alpha: 0.30),
                  AppColors.coach.withValues(alpha: 0.14),
                ]),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.coach.withValues(alpha: 0.40)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.coach.withValues(alpha: 0.25),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: AppColors.coach, size: 17),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? LinearGradient(
                        colors: [vc.primary, vc.primaryGlow],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: message.isUser ? null : vc.surface,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(message.isUser ? 18 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 18),
                ),
                border: message.isUser
                    ? null
                    : Border.all(color: vc.border),
                boxShadow: [
                  BoxShadow(
                    color: message.isUser
                        ? vc.primary.withValues(alpha: 0.28)
                        : Colors.black.withValues(alpha: 0.14),
                    blurRadius: message.isUser ? 14 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  color: message.isUser ? Colors.white : vc.text,
                  height: 1.55,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Geçmiş Konuşmalar Sheet ───────────────────────────────────────────────────

class _ConversationHistorySheet extends StatelessWidget {
  final List<Map<String, dynamic>> conversations;
  final void Function(String id) onResume;
  final void Function(String id) onDelete;

  const _ConversationHistorySheet({
    required this.conversations,
    required this.onResume,
    required this.onDelete,
  });

  String _formatDate(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = (ts as dynamic).toDate() as DateTime;
      const m = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
          'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      return '${dt.day} ${m[dt.month]}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: vc.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            children: [
              Icon(Icons.history_rounded, color: vc.primary, size: 20),
              const SizedBox(width: 8),
              Text('Geçmiş Sohbetler',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: vc.text)),
            ],
          ),
          const SizedBox(height: 16),
          if (conversations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Arşivlenmiş sohbet yok.',
                    style: TextStyle(color: vc.textMuted, fontSize: 14)),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: conversations.length,
                itemBuilder: (_, i) {
                  final conv  = conversations[i];
                  final id    = conv['id'] as String;
                  final title = (conv['title'] as String? ?? '').isEmpty
                      ? 'Sohbet ${i + 1}'
                      : conv['title'] as String;
                  final date  = _formatDate(conv['createdAt']);
                  return Dismissible(
                    key: Key(id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: Colors.red.withValues(alpha: 0.12),
                      child: const Icon(Icons.delete_rounded,
                          color: Colors.red, size: 20),
                    ),
                    onDismissed: (_) => onDelete(id),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: vc.primarySurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.chat_bubble_outline_rounded,
                            color: vc.primary, size: 16),
                      ),
                      title: Text(title,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600, color: vc.text)),
                      subtitle: date.isEmpty ? null
                          : Text(date,
                              style: TextStyle(fontSize: 11, color: vc.textMuted)),
                      trailing: Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: vc.textMuted),
                      onTap: () => onResume(id),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
