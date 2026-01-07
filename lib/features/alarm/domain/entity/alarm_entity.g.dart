// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmEntityAdapter extends TypeAdapter<AlarmEntity> {
  @override
  final typeId = 0;

  @override
  AlarmEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmEntity(
      id: fields[0] as String,
      time: fields[1] as DateTime,
      isEnabled: fields[2] as bool,
      ttsMessage: fields[3] as String,
      activeDays: (fields[4] as List).cast<int>(),
      title: fields[5] as String,
      soundName: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmEntity obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.time)
      ..writeByte(2)
      ..write(obj.isEnabled)
      ..writeByte(3)
      ..write(obj.ttsMessage)
      ..writeByte(4)
      ..write(obj.activeDays)
      ..writeByte(5)
      ..write(obj.title)
      ..writeByte(6)
      ..write(obj.soundName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
