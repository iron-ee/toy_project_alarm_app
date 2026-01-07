import 'package:alarm_app/core/service/notification_service.dart';
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

  // 알람 추가 로직
  Future<void> addAlarm({
    required DateTime time,
    required String message,
    required List<int> activeDays, // 추가됨
  }) async {
    final int alarmId =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 100000000;

    final newAlarm = AlarmModel(
      id: alarmId.toString(),
      time: time,
      ttsMessage: message,
      activeDays: activeDays, // 모델에도 저장
    );

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(alarmRepositoryProvider);
      await repository.saveAlarm(newAlarm);

      final notiService = ref.read(notificationServiceProvider);
      await notiService.requestPermission();

      // 수정된 scheduleAlarm 호출
      await notiService.scheduleAlarm(
        alarmId: alarmId,
        title: "알람",
        body: message,
        time: time,
        activeDays: activeDays,
      );

      return repository.getAlarms();
    });
  }

  // 삭제 로직 수정
  Future<void> deleteAlarm(String id) async {
    final repository = ref.read(alarmRepositoryProvider);
    final notiService = ref.read(notificationServiceProvider);

    // 1. 알림 예약 취소 (DB 삭제 전에 해야 ID로 찾을 수 있음, 여기서는 ID만 있으면 됨)
    await notiService.cancelAlarm(int.parse(id));

    // 2. DB 삭제
    await repository.deleteAlarm(id);

    // 3. 목록 갱신
    state = await AsyncValue.guard(() => repository.getAlarms());
  }
}
