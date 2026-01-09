import 'package:alarm/alarm.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ringing_state_provider.g.dart';

// 현재 울리고 있는 알람 정보를 담는 프로바이더입니다.
// 초기값은 null이며, 알람이 울리면 해당 알람의 설정을 담게 됩니다.
@riverpod
class RingingState extends _$RingingState {
  @override
  AlarmSettings? build() => null;

  // 상태 업데이트 (알람 시작 시)
  void setRinging(AlarmSettings settings) {
    state = settings;
  }

  // 상태 초기화 (알람 중지 시)
  void clear() {
    state = null;
  }
}
