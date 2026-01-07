import 'package:alarm_app/features/alarm/data/model/alarm_model.dart';
import 'package:hive_ce/hive.dart';

part 'alarm_entity.g.dart';

const String kAlarmBoxName = 'alarm_box';

@HiveType(typeId: 0)
class AlarmEntity extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime time;

  @HiveField(2)
  final bool isEnabled;

  @HiveField(3)
  final String ttsMessage;

  AlarmEntity({
    required this.id,
    required this.time,
    required this.isEnabled,
    required this.ttsMessage,
  });

  factory AlarmEntity.fromModel(AlarmModel model) {
    return AlarmEntity(
      id: model.id,
      time: model.time,
      isEnabled: model.isEnabled,
      ttsMessage: model.ttsMessage ?? '',
    );
  }

  AlarmModel toModel() {
    return AlarmModel(
      id: id,
      time: time,
      isEnabled: isEnabled,
      ttsMessage: ttsMessage,
    );
  }
}
