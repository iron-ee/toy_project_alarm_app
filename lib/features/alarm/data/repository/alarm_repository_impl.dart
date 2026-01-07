import 'package:alarm_app/features/alarm/data/data_source/alarm_data_source.dart';
import 'package:alarm_app/features/alarm/data/model/alarm_model.dart';
import 'package:alarm_app/features/alarm/domain/entity/alarm_entity.dart';
import 'package:alarm_app/features/alarm/domain/repository/alarm_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'alarm_repository_impl.g.dart';

@riverpod
AlarmRepository alarmRepository(Ref ref) {
  final localDataSource = ref.watch(alarmLocalDataSourceProvider);
  return AlarmRepositoryImpl(localDataSource);
}

class AlarmRepositoryImpl implements AlarmRepository {
  final AlarmLocalDataSource _localDataSource;

  AlarmRepositoryImpl(this._localDataSource);

  @override
  Future<List<AlarmModel>> getAlarms() async {
    // Hive에서 Entity 리스트를 가져와서 Model로 변환
    final entities = await _localDataSource.getAlarms();
    return entities.map((e) => e.toModel()).toList();
  }

  @override
  Future<void> saveAlarm(AlarmModel alarm) async {
    // Model을 Entity로 변환해서 Hive에 저장
    final entity = AlarmEntity.fromModel(alarm);
    await _localDataSource.saveAlarm(entity);
  }

  @override
  Future<void> deleteAlarm(String id) async {
    // Hive에서 삭제
    await _localDataSource.deleteAlarm(id);
  }
}
