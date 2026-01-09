import 'dart:async';
import 'dart:developer';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:alarm_app/features/alarm/presentation/provider/ringing_state_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibration/vibration.dart';

part 'alarm_service.g.dart';

@riverpod
AlarmService alarmService(Ref ref) {
  // Provider가 사용되지 않아도 파괴되지 않도록 유지
  final link = ref.keepAlive();
  final service = AlarmService(ref);
  ref.onDispose(() {
    service.dispose();
  });
  return service;
}

class AlarmService {
  final Ref _ref;

  //
  StreamSubscription<AlarmSet>? _ringingSubscription;

  AlarmService(this._ref);

  /// 1. 초기화
  Future<void> init() async {
    // 내부적으로 AlarmStorage 및 Platform Binding 초기화
    await Alarm.init();

    // ringing ValueStream을 구독하여 알람 울림 감지
    _ringingSubscription = Alarm.ringing.listen((alarmSet) async {
      if (alarmSet.alarms.isNotEmpty) {
        // 새로운 알람이 울리면, 기존에 울리고 있던 다른 알람들을 모두 정지
        // 이를 통해 "뒤에 오는 알람이 우선순위"를 갖게 함
        if (alarmSet.alarms.length > 1) {
          final newAlarm = alarmSet.alarms.last;
          for (final oldAlarm in alarmSet.alarms) {
            if (oldAlarm.id != newAlarm.id) {
              await Alarm.stop(oldAlarm.id);
              log("이전 알람(ID: ${oldAlarm.id})을 새로운 알람을 위해 종료");
            }
          }
        }

        // 현재 울리고 있는 알람들 중 가장 최근 것
        final activeAlarm = alarmSet.alarms.last;

        // 진동 발생
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(pattern: [0, 500, 200, 500]);
        }

        // 상태 업데이트 (UI에서 이 값을 보고 울림 화면을 띄울 수 있음)
        _ref.read(ringingStateProvider.notifier).setRinging(activeAlarm);
        log("알람 울림 시작: ID ${activeAlarm.id}");

        // loopAudio가 false일 때, 일정 시간 후 자동으로 알람 상태 종료
        // 소리가 약 10~15초라고 가정하면, 그 후엔 자동으로 꺼지도록 타이머를 돌린다.
        // 사용자가 '끄기'를 누르지 않아도 상태가 정리되도록 함
        Timer(const Duration(seconds: 20), () async {
          if (await Alarm.isRinging(activeAlarm.id)) {
            await Alarm.stop(activeAlarm.id);
            log("알람(ID: ${activeAlarm.id})이 20초 경과로 자동 종료");
          }
        });

        // [TTS 실행 로직 위치]
        // _ref.read(ttsServiceProvider).speak(activeAlarm.notificationSettings.body);
      } else {
        // 울리는 알림이 없으면 상태 초기화
        _ref.read(ringingStateProvider.notifier).clear();
      }
    });
  }

  //
  void dispose() {
    _ringingSubscription?.cancel();
    log('AlarmService 리소스 해제');
  }

  /// 2. 권한 요청 (v5 Alarm 클래스에 메서드가 없으므로 직접 구현)
  Future<void> requestPermission() async {
    // 1. 일반 알림 권한 (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // 2. 정확한 알람 권한 체크 (Android 12+)
    // permission_handler 11.0.0+ 기준 scheduleExactAlarm 사용
    final alarmStatus = await Permission.scheduleExactAlarm.status;
    if (alarmStatus.isDenied) {
      log("정확한 알람 권한 요청 중...");
      await Permission.scheduleExactAlarm.request();
    }

    // 3. 배터리 최적화 제외 요청 (알람 앱의 생명줄)
    // 이 권한은 거절되어 있을 경우 시스템 설정 팝업을 띄웁니다.
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      log("배터리 최적화 제외 요청 중...");
      await Permission.ignoreBatteryOptimizations.request();
    }

    // 4. 다른 앱 위에 표시 (잠금화면/사용 중 RingView 노출용)
    if (await Permission.systemAlertWindow.isDenied) {
      log("다른 앱 위에 표시 권한 요청 중...");
      await Permission.systemAlertWindow.request();
    }
  }

  /// 사용자가 설정을 수동으로 켰는지 확인하기 위한 유틸리티
  Future<bool> checkAllPermissions() async {
    final n = await Permission.notification.isGranted;
    final a = await Permission.scheduleExactAlarm.isGranted;
    final b = await Permission.ignoreBatteryOptimizations.isGranted;

    return n && a && b;
  }

  /// 3. 알람 스케줄링
  Future<void> scheduleAlarm({
    required int alarmId,
    required String title,
    required String body,
    required DateTime time,
    required List<int> activeDays,
    String? soundName,
  }) async {
    // Assets 경로 구성 (확장자 mp3 권장)
    String audioPath = 'assets/sounds/launch_notice_1.wav';
    if (soundName != null && soundName.isNotEmpty) {
      final fileName = soundName.contains('.') ? soundName : '$soundName.wav';
      audioPath = 'assets/sounds/$fileName';
    }

    if (activeDays.isEmpty) {
      // 1회성 알람
      DateTime scheduledDate = _calculateNextDateTime(time);
      await _setAlarm(alarmId, scheduledDate, title, body, audioPath);
    } else {
      // 요일 반복 알람
      for (final day in activeDays) {
        DateTime scheduledDate = _calculateNextWeekdayDateTime(day, time);
        final int notificationId = alarmId * 10 + day;
        await _setAlarm(notificationId, scheduledDate, title, body, audioPath);
      }
    }
  }

  /// 4. 실제 Alarm.set 호출 로직
  Future<void> _setAlarm(
    int id,
    DateTime dateTime,
    String title,
    String body,
    String audioPath,
  ) async {
    // fade 효과
    final volumeSettings = VolumeSettings.fade(
      fadeDuration: const Duration(seconds: 2),
      volumeEnforced: false, // 사용자가 볼륨을 낮추지 못하게 강제하는 속성
      // volume: 0.5, // 0.0 ~ 1.0
    );

    // 알림 설정
    final notificationSettings = NotificationSettings(
      title: title,
      body: body,
      stopButton: '끄기', // 알림창에 표시될 중지 버튼
    );

    // 전체 알람 설정 객체
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: audioPath,
      volumeSettings: volumeSettings,
      notificationSettings: notificationSettings,
      loopAudio: false,
      // 반복 여부
      vibrate: false,
      // 진동 활성화 여부
      androidFullScreenIntent: true,
      // 잠금 화면 위로 띄우기
      warningNotificationOnKill: true,
      // 앱 종료 시 경고
      androidStopAlarmOnTermination: false,
      // 앱이 꺼져도 알람 유지
      allowAlarmOverlap: true, // 알람 중복 활성화 여부
    );

    // 새 알람 예약 시 기존 동일 ID는 확실히 지우고 시작
    // 알람 등록 (이미 같은 ID가 있다면 set 내부에서 stop 후 재등록함)
    await Alarm.stop(id);
    await Alarm.set(alarmSettings: alarmSettings);

    log("알람 예약 완료: $dateTime (ID: $id)");
  }

  /// 알람 취소
  Future<void> cancelAlarm(int alarmId) async {
    List<Future> stopRequests = [Alarm.stop(alarmId)];
    for (int i = 1; i <= 7; i++) {
      stopRequests.add(Alarm.stop(alarmId * 10 + i));
    }
    await Future.wait(stopRequests); // 병렬로 취소 처리
  }

  // --- 날짜 계산 유틸리티 ---

  DateTime _calculateNextDateTime(DateTime time) {
    final now = DateTime.now();
    final nowTrimmed = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      0,
      0,
    );

    // 현재 시간(분 단위까지)보다 이전이라면 내일로 설정
    if (scheduledDate.isBefore(nowTrimmed)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  DateTime _calculateNextWeekdayDateTime(int dayOfWeek, DateTime time) {
    DateTime scheduledDate = _calculateNextDateTime(time);
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
