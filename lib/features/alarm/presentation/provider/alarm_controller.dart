import 'package:alarm_app/core/service/alarm_service.dart';
import 'package:alarm_app/features/alarm/data/model/alarm_model.dart';
import 'package:alarm_app/features/alarm/data/repository/alarm_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'alarm_controller.g.dart';

// AsyncNotifier를 상속받는 Controller 생성
@riverpod
class AlarmController extends _$AlarmController {
  // build 메서드는 초기 상태(State)를 정의
  @override
  Future<List<AlarmModel>> build() async {
    // Repository Provider를 읽어옵니다.
    final repository = ref.watch(alarmRepositoryProvider);
    return repository.getAlarms();
  }

  /// 알람 추가
  Future<void> addAlarm({
    required DateTime time,
    required String message,
    required List<int> activeDays,
    required String title,
    String? soundName,
  }) async {
    final int alarmId =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 100000000;

    final newAlarm = AlarmModel(
      id: alarmId.toString(),
      time: time,
      ttsMessage: message,
      activeDays: activeDays,
      title: title,
      soundName: soundName,
    );

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(alarmRepositoryProvider);
      await repository.saveAlarm(newAlarm);

      final alarmService = ref.read(alarmServiceProvider);
      await alarmService.requestPermission();

      await alarmService.scheduleAlarm(
        alarmId: alarmId,
        title: title,
        body: message,
        time: time,
        activeDays: activeDays,
        soundName: soundName,
      );

      return repository.getAlarms();
    });
  }

  /// 알람 ON/OFF 토글
  Future<void> toggleAlarm(AlarmModel alarm) async {
    // 1. 현재 상태 반전 (ON -> OFF, OFF -> ON)
    final newAlarm = alarm.copyWith(isEnabled: !alarm.isEnabled);

    // 2. DB 업데이트
    final repository = ref.read(alarmRepositoryProvider);
    await repository.saveAlarm(newAlarm); // id가 같으면 덮어쓰기 됨(Hive 특성)

    // 3. 알림 서비스 제어
    final alarmService = ref.read(alarmServiceProvider);

    if (newAlarm.isEnabled) {
      // ON: 다시 스케줄링
      await alarmService.scheduleAlarm(
        alarmId: int.parse(newAlarm.id), // ID는 정수형으로 변환
        title: newAlarm.title,
        body: newAlarm.ttsMessage ?? "",
        time: newAlarm.time,
        activeDays: newAlarm.activeDays ?? [],
        soundName: newAlarm.soundName,
      );
    } else {
      // OFF: 예약 취소
      await alarmService.cancelAlarm(int.parse(newAlarm.id));
    }

    // 4. UI 갱신 (DB 다시 읽기)
    state = await AsyncValue.guard(() => repository.getAlarms());
  }

  /// 알람 수정
  Future<void> editAlarm({
    required AlarmModel alarm, // 이미 ID가 있는 수정된 알람 객체
  }) async {
    final repository = ref.read(alarmRepositoryProvider);
    final alarmService = ref.read(alarmServiceProvider);

    // 1. 기존 알림 예약 취소 (시간이나 요일이 바뀌었을 수 있으므로)
    await alarmService.cancelAlarm(int.parse(alarm.id));

    // 2. DB 업데이트 (Hive는 같은 ID로 put하면 알아서 덮어씀)
    await repository.saveAlarm(alarm);

    // 3. 알림 다시 예약 (알람이 켜져있는 경우만)
    if (alarm.isEnabled) {
      await alarmService.requestPermission();
      await alarmService.scheduleAlarm(
        alarmId: int.parse(alarm.id),
        title: alarm.title,
        body: alarm.ttsMessage ?? "",
        time: alarm.time,
        activeDays: alarm.activeDays ?? [],
        soundName: alarm.soundName,
      );
    }

    // 4. UI 갱신
    state = await AsyncValue.guard(() => repository.getAlarms());
  }

  /// 알람 삭제
  Future<void> deleteAlarm(String id) async {
    final repository = ref.read(alarmRepositoryProvider);
    final alarmService = ref.read(alarmServiceProvider);

    // 1. 알림 예약 취소 (DB 삭제 전에 해야 ID로 찾을 수 있음, 여기서는 ID만 있으면 됨)
    await alarmService.cancelAlarm(int.parse(id));

    // 2. DB 삭제
    await repository.deleteAlarm(id);

    // 3. 목록 갱신
    state = await AsyncValue.guard(() => repository.getAlarms());
  }
}
