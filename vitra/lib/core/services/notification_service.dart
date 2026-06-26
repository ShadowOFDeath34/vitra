import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Tüm yerel bildirim işlemleri buradan geçer.
/// Desteklenen bildirimler:
///   - Su içme hatırlatıcısı (her N saatte bir, özelleştirilebilir)
///   - Rutin hatırlatıcısı (gün içinde bir kez, saati ayarlanabilir)
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Bildirim ID'leri — her tür için sabit ID kullanmak güncellemeyi kolaylaştırır
  static const _waterChannelId   = 'vitra_water';
  static const _routineChannelId = 'vitra_routine';

  // Su bildirimleri: 100-199 arası ID blok
  // Rutin bildirimi: 200

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    // Türkiye saati varsayılan
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (_) {
      // timezone DB yüklenemezse sistem saati kullanılır
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Android kanalları
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _waterChannelId,
            'Su Hatırlatıcıları',
            description: 'Günlük su içme hatırlatıcıları',
            importance: Importance.defaultImportance,
          ),
        );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _routineChannelId,
            'Rutin Hatırlatıcıları',
            description: 'Günlük rutin tamamlama hatırlatıcısı',
            importance: Importance.defaultImportance,
          ),
        );

    _initialized = true;
  }

  /// Bildirim izni iste (iOS + Android 13+)
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  // ── Su Bildirimleri ────────────────────────────────────────────────────────

  static const _waterMessages = [
    ('Su içme vakti!',        'Bir bardak su seni bekliyor!'),
    ('Su içme zamanı!',        'Vücudun sana teşekkür edecek — içmeyi unutma!'),
    ('Su molası',             'Hedefine bir adım daha yaklaş, su iç!'),
    ('Hücrelerin susadı',     'Hücrelerini besle, bir yudum al.'),
    ('Enerji zamanı',         'Su içmek enerji verir — hadi başla!'),
    ('İlerliyorsun!',         'Günlük hedefe doğru gidiyorsun, devam et!'),
    ('Kısa bir mola',         'Bir mola ver, bir bardak su iç.'),
    ('Zihin + beden',         'Zihnin temiz, vücudun diri — su içmeyi unutma!'),
    ('Tam zamanı',            'Şu an tam zamanı — bir bardak su!'),
    ('Sağlıklı gün',          'Sağlıklı bir gün için su şart.'),
    ('Metabolizma',           'Metabolizmanı çalıştır, su iç!'),
    ('Sıradaki görev',        'Sıradaki görevin: bir bardak su!'),
  ];

  /// Kalkış–yatış penceresi arasında 8 eşit aralıkta su bildirimi planlar.
  /// Her bildirim farklı motivasyon mesajı kullanır.
  Future<void> scheduleWaterRemindersForWindow({
    int wakeHour    = 7,
    int wakeMinute  = 0,
    int sleepHour   = 23,
    int sleepMinute = 0,
  }) async {
    if (!_initialized) await init();
    await cancelWaterReminders();

    final wakeMinutes  = wakeHour  * 60 + wakeMinute;
    final sleepMinutes = sleepHour * 60 + sleepMinute;
    final windowMinutes = sleepMinutes - wakeMinutes;

    // Geçersiz pencere varsa sessizce çık
    if (windowMinutes < 60) return;

    // 8 eşit parça — 0..7 arası, son nokta yatış saatinde değil ondan önce
    const count = 8;
    final intervalMinutes = windowMinutes ~/ count;

    if (kDebugMode) {
      debugPrint('[Notifications] Su bildirimleri: $wakeHour:${wakeMinute.toString().padLeft(2,'0')} – $sleepHour:${sleepMinute.toString().padLeft(2,'0')}, her ${intervalMinutes}dk');
    }

    final now = tz.TZDateTime.now(tz.local);

    for (var i = 0; i < count; i++) {
      final totalMin = wakeMinutes + i * intervalMinutes;
      final h = totalMin ~/ 60;
      final m = totalMin % 60;

      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final msg = _waterMessages[i % _waterMessages.length];

      await _plugin.zonedSchedule(
        100 + i,
        msg.$1,
        msg.$2,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _waterChannelId,
            'Su Hatırlatıcıları',
            channelDescription: 'Günlük su içme hatırlatıcıları',
            icon: '@mipmap/ic_launcher',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Eski API — geriye dönük uyumluluk için korunur.
  Future<void> scheduleWaterReminders({
    int intervalHours = 2,
    int startHour     = 7,
    int endHour       = 23,
  }) => scheduleWaterRemindersForWindow(
        wakeHour: startHour,
        sleepHour: endHour,
      );

  Future<void> cancelWaterReminders() async {
    for (var id = 100; id < 200; id++) {
      await _plugin.cancel(id);
    }
  }

  // ── Rutin Bildirimi ────────────────────────────────────────────────────────

  /// Her gün [hour]:[minute]'te rutin hatırlatıcısı planlar.
  Future<void> scheduleRoutineReminder({
    int hour   = 20,
    int minute = 0,
  }) async {
    if (!_initialized) await init();

    await _plugin.cancel(200);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      200,
      'Rutinlerini tamamladın mı?',
      'Bugünkü rutinlerin seni bekliyor. Bir göz at!',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _routineChannelId,
          'Rutin Hatırlatıcıları',
          channelDescription: 'Günlük rutin tamamlama hatırlatıcısı',
          icon: '@mipmap/ic_launcher',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelRoutineReminder() async => _plugin.cancel(200);

  // ── Bireysel Rutin Bildirimleri ───────────────────────────────────────────

  // ID aralığı 300-399 — rutin ID'sinden deterministik türetilir
  int _routineNotifId(String routineId) =>
      300 + (routineId.hashCode.abs() % 100);

  /// Belirli bir rutin için günlük bildirim planlar.
  Future<void> scheduleRoutineNotification({
    required String routineId,
    required String routineLabel,
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) await init();

    final id = _routineNotifId(routineId);
    await _plugin.cancel(id);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      routineLabel,
      '$routineLabel zamanı geldi — hadi yapalım!',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _routineChannelId,
          'Rutin Hatırlatıcıları',
          channelDescription: 'Günlük rutin tamamlama hatırlatıcısı',
          icon: '@mipmap/ic_launcher',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelRoutineNotification(String routineId) async =>
      _plugin.cancel(_routineNotifId(routineId));

  // ── Tümünü İptal ──────────────────────────────────────────────────────────

  Future<void> cancelAll() async => _plugin.cancelAll();
}
