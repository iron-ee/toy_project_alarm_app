import 'package:alarm_app/features/alarm/domain/entity/alarm_entity.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'alarm_data_source.g.dart';

@riverpod
AlarmLocalDataSource alarmLocalDataSource(Ref ref) {
  return AlarmLocalDataSource();
}

class AlarmLocalDataSource {
  // Box를 여는 로직
  Future<Box<AlarmEntity>> _getBox() async {
    // Hive 대신 hive_ce도 Hive 클래스명을 그대로 사용하므로 코드 변경 최소화됨
    if (Hive.isBoxOpen(kAlarmBoxName)) {
      return Hive.box<AlarmEntity>(kAlarmBoxName);
    } else {
      return await Hive.openBox<AlarmEntity>(kAlarmBoxName);
    }
  }

  Future<List<AlarmEntity>> getAlarms() async {
    final box = await _getBox();
    return box.values.toList();
  }

  Future<void> saveAlarm(AlarmEntity alarm) async {
    final box = await _getBox();
    await box.put(alarm.id, alarm);
  }

  Future<void> deleteAlarm(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
