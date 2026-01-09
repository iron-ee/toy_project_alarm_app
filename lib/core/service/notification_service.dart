import 'dart:developer';
import 'dart:io';
import 'dart:typed_data'; // Int32List

import 'package:alarm_app/core/constants/app_constants.dart';
import 'package:alarm_app/core/service/tts_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

part 'notification_service.g.dart';

@riverpod
NotificationService notificationService(Ref ref) {
  return NotificationService(ref);
}

class NotificationService {
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  // 1. 초기화
  Future<void> init() async {
    tz.initializeTimeZones();

    try {
      final TimezoneInfo timezoneInfo =
          await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      log("타임존 설정 실패: $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) async {
        log("알림 클릭됨: ${details.payload}");
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          _ref.read(ttsServiceProvider).speak(payload);
        }
      },
    );

    // [수정] 여기서 미리 채널을 만들지 않습니다.
    // 알람 예약 시점에 동적으로 만듭니다.
  }

  // [추가] 소리 파일명에 따라 전용 채널을 생성하는 함수
  Future<String> _createChannelForSound(String? soundName) async {
    // 1. 소리가 없으면 기본 채널 ID 반환
    if (soundName == null || soundName.isEmpty) {
      return AppConstants.channelDefaultId;
    }

    // 2. 소리 파일명을 포함한 고유한 채널 ID 생성
    // 예: alarm_custom_launch_notice_1
    final String dynamicChannelId = 'alarm_custom_$soundName';
    final String dynamicChannelName = '알람 ($soundName)';

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // 3. 해당 ID로 채널 생성 (이미 있으면 업데이트됨)
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      dynamicChannelId,
      dynamicChannelName,
      description: '사용자 지정 알림음입니다.',
      importance: Importance.max, // Max 중요도
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName),
      enableVibration: true,
      // [핵심] 알람 스트림 강제 지정
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await androidPlugin?.createNotificationChannel(channel);

    return dynamicChannelId; // 생성된 ID 반환
  }

  Future<void> requestPermission() async {
    // ... (기존 코드 동일) ...
    if (Platform.isAndroid) {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> scheduleAlarm({
    required int alarmId,
    required String title,
    required String body,
    required DateTime time,
    required List<int> activeDays,
    String? soundName,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    if (activeDays.isEmpty) {
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      await _scheduleOneShot(alarmId, title, body, scheduledDate, soundName);
    } else {
      for (final day in activeDays) {
        tz.TZDateTime scheduledDate = _nextInstanceOfDay(day, time);
        final int notificationId = alarmId * 10 + day;
        await _scheduleRepeated(
          notificationId,
          title,
          body,
          scheduledDate,
          soundName,
        );
      }
    }
  }

  // ... (날짜 계산 함수들은 기존과 동일, 생략) ...
  tz.TZDateTime _nextInstanceOfDay(int dayOfWeek, DateTime time) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTime(DateTime time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> _scheduleOneShot(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledDate,
    String? soundName,
  ) async {
    // [수정] 예약 직전에 채널을 생성하고 ID를 받아옵니다.
    final String channelId = await _createChannelForSound(soundName);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails(channelId, soundName), // ID 전달
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: body,
    );
  }

  Future<void> _scheduleRepeated(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledDate,
    String? soundName,
  ) async {
    // [수정] 예약 직전에 채널 생성
    final String channelId = await _createChannelForSound(soundName);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails(channelId, soundName), // ID 전달
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: body,
    );
  }

  // [수정] channelId를 인자로 받아서 그대로 사용
  NotificationDetails _notificationDetails(
    String channelId,
    String? soundName,
  ) {
    if (soundName != null && soundName.isNotEmpty) {
      String iosSound = soundName.contains('.') ? soundName : '$soundName.wav';

      return NotificationDetails(
        android: AndroidNotificationDetails(
          channelId, // 동적으로 생성된 채널 ID 사용
          '알람 ($soundName)', // 채널 이름 (사용자에게 보임)
          channelDescription: '사용자 지정 알림음입니다.',
          importance: Importance.max,
          priority: Priority.high,

          sound: RawResourceAndroidNotificationSound(soundName),

          // 알람 스트림 설정
          audioAttributesUsage: AudioAttributesUsage.alarm,
          category: AndroidNotificationCategory.alarm,

          fullScreenIntent: true,
          additionalFlags: Int32List.fromList(<int>[4]), // Insistent Flag
        ),
        iOS: DarwinNotificationDetails(
          sound: iosSound,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      );
    } else {
      // 기본음인 경우
      return NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.channelDefaultId, // 기본 채널 ID
          AppConstants.channelDefaultName,
          channelDescription: AppConstants.channelDefaultDesc,
          importance: Importance.max,
          priority: Priority.high,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          additionalFlags: Int32List.fromList(<int>[4]),
        ),
        iOS: DarwinNotificationDetails(
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      );
    }
  }

  Future<void> cancelAlarm(int alarmId) async {
    await _plugin.cancel(alarmId);
    for (int i = 1; i <= 7; i++) {
      await _plugin.cancel(alarmId * 10 + i);
    }
  }
}
