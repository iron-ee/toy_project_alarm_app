import 'dart:developer';
import 'dart:io';

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

  // 1. 초기화 (앱 시작 시 호출)
  Future<void> init() async {
    // Timezone DB 초기화
    tz.initializeTimeZones();

    // 기기의 현재 타임존 가져오기
    try {
      final TimezoneInfo timezoneInfo =
          await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;

      log("현재 기기 타임존: $timeZoneName");
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      log("타임존 설정 실패: $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Android 설정: 아이콘 파일명 (android/app/src/main/res/drawable/app_icon.png 필요)
    // 없으면 기본 'mipmap/ic_launcher' 사용 가능하지만, 투명 배경 아이콘 권장
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false, // 나중에 명시적으로 요청함
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
          // TTS 서비스 호출
          _ref.read(ttsServiceProvider).speak(payload);
        }
      },
    );
  }

  // 2. 권한 요청 (설정 화면이나 앱 최초 실행 시 호출)
  Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // 1. (기존) 알림 표시 권한 (Android 13+ POST_NOTIFICATIONS)
      await androidImplementation?.requestNotificationsPermission();

      // 2. [추가] 정확한 알람 스케줄링 권한 요청 (Android 12+)
      // 이 함수를 호출하면, 권한이 없을 경우 시스템 설정 화면으로 이동시킬 수 있습니다.
      await androidImplementation?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // 3. 알람 스케줄링 (핵심 기능)
  Future<void> scheduleAlarm({
    required int alarmId, // DB에 저장된 알람 ID
    required String title,
    required String body,
    required DateTime time, // 사용자가 설정한 시간 (날짜는 무시하고 시/분만 사용)
    required List<int> activeDays, // [1, 2, 3...] (1=월요일)
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // 1. 반복 요일이 없는 경우 (1회성 알람)
    if (activeDays.isEmpty) {
      // 설정된 시/분으로 오늘 날짜 생성
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // 만약 이미 지난 시간이라면 내일로 설정
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _scheduleOneShot(alarmId, title, body, scheduledDate);
    }
    // 2. 반복 요일이 있는 경우 (매주 반복)
    else {
      for (final day in activeDays) {
        // 해당 요일의 다음 발생 시간 계산
        tz.TZDateTime scheduledDate = _nextInstanceOfDay(day, time);

        // ID 생성 규칙: 알람ID * 10 + 요일인덱스 (예: ID 5, 월요일(1) -> 51)
        // 이렇게 해야 요일별로 개별 취소/수정이 가능함
        final int notificationId = alarmId * 10 + day;

        await _scheduleRepeated(notificationId, title, body, scheduledDate);
      }
    }
  }

  // 내부 함수: 다음 요일 계산 로직
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

  // 내부 함수: 1회성 알람 등록
  Future<void> _scheduleOneShot(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledDate,
  ) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails(), // 공통 Details 분리
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: body,
    );
  }

  // 내부 함수: 반복 알람 등록 (matchDateTimeComponents 사용)
  Future<void> _scheduleRepeated(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledDate,
  ) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // ★ 핵심: 요일과 시간이 같을 때마다 반복
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: body,
    );
  }

  // 공통 Notification Details
  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_channel_id',
        '기상/업무 알람',
        channelDescription: '알람 기능을 위한 채널입니다.',
        importance: Importance.max,
        priority: Priority.high,
        // sound: RawResourceAndroidNotificationSound('launch_comment_bgm'),
      ),
      iOS: DarwinNotificationDetails(
        // sound: 'launch_comment_bgm.wav',
        presentSound: true,
      ),
    );
  }

  // 알람 취소 (반복 알람까지 고려해서 모두 취소)
  Future<void> cancelAlarm(int alarmId) async {
    // 1회성 알람 취소 시도
    await _plugin.cancel(alarmId);
    // 반복 알람(요일별 ID) 취소 시도 (1~7)
    for (int i = 1; i <= 7; i++) {
      await _plugin.cancel(alarmId * 10 + i);
    }
  }
}
