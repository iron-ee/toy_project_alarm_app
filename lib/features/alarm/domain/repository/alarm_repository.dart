import 'package:alarm_app/features/alarm/data/model/alarm_model.dart';

abstract class AlarmRepository {
  Future<List<AlarmModel>> getAlarms();
  Future<void> saveAlarm(AlarmModel alarm);
  Future<void> deleteAlarm(String id);
}
