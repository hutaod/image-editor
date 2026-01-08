// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventRecordAdapter extends TypeAdapter<EventRecord> {
  @override
  final int typeId = 5;

  @override
  EventRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventRecord(
      id: fields[0] as String,
      eventId: fields[1] as String,
      type: fields[2] as RecordType,
      textContent: fields[3] as String?,
      imagePaths: (fields[4] as List).cast<String>(),
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime?,
      location: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EventRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.eventId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.textContent)
      ..writeByte(4)
      ..write(obj.imagePaths)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.location);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecordTypeAdapter extends TypeAdapter<RecordType> {
  @override
  final int typeId = 4;

  @override
  RecordType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecordType.photo;
      case 1:
        return RecordType.text;
      case 2:
        return RecordType.mixed;
      default:
        return RecordType.photo;
    }
  }

  @override
  void write(BinaryWriter writer, RecordType obj) {
    switch (obj) {
      case RecordType.photo:
        writer.writeByte(0);
        break;
      case RecordType.text:
        writer.writeByte(1);
        break;
      case RecordType.mixed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
