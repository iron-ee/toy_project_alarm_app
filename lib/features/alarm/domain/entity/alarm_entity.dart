import 'package:alarm_app/features/alarm/data/model/alarm_model.dart';
import 'package:hive_ce/hive.dart';

part 'alarm_entity.g.dart';

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
  @HiveField(4)
  final List<int> activeDays;
  @HiveField(5)
  final String title;
  @HiveField(6)
  final String? soundName;

  AlarmEntity({
    required this.id,
    required this.time,
    required this.isEnabled,
    required this.ttsMessage,
    required this.activeDays,
    required this.title,
    this.soundName,
  });

  factory AlarmEntity.fromModel(AlarmModel model) {
    return AlarmEntity(
      id: model.id,
      time: model.time,
      isEnabled: model.isEnabled,
      ttsMessage: model.ttsMessage ?? '',
      activeDays: model.activeDays ?? [],
      title: model.title,
      soundName: model.soundName,
    );
  }

  AlarmModel toModel() {
    return AlarmModel(
      id: id,
      time: time,
      isEnabled: isEnabled,
      ttsMessage: ttsMessage,
      activeDays: activeDays,
      title: title,
      soundName: soundName,
    );
  }
}
