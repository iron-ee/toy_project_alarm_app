import 'package:alarm_app/core/constants/app_constants.dart';
import 'package:alarm_app/features/alarm/domain/entity/alarm_entity.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'alarm_data_source.g.dart';

@riverpod
AlarmLocalDataSource alarmLocalDataSource(Ref ref) {
  return AlarmLocalDataSource();
}

class AlarmLocalDataSource {
  Future<Box<AlarmEntity>> _getBox() async {
    if (Hive.isBoxOpen(AppConstants.alarmBoxName)) {
      return Hive.box<AlarmEntity>(AppConstants.alarmBoxName);
    } else {
      return await Hive.openBox<AlarmEntity>(AppConstants.alarmBoxName);
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
