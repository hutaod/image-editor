// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 2;

  @override
  Event read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Event(
      id: fields[0] as String,
      title: fields[1] as String,
      date: fields[2] as DateTime,
      note: fields[4] as String?,
      isLunar: fields[5] as bool,
      lunarYear: fields[6] as int?,
      lunarMonth: fields[7] as int?,
      lunarDay: fields[8] as int?,
      lunarLeap: fields[9] as bool?,
      recurrenceUnit: fields[10] as RecurrenceUnit,
      recurrenceInterval: fields[11] as int,
      kind: fields[12] as EventKind,
      isHidden: fields[13] as bool,
      isDefaultEvent: fields[14] as bool,
      calendarEventId: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.isLunar)
      ..writeByte(6)
      ..write(obj.lunarYear)
      ..writeByte(7)
      ..write(obj.lunarMonth)
      ..writeByte(8)
      ..write(obj.lunarDay)
      ..writeByte(9)
      ..write(obj.lunarLeap)
      ..writeByte(10)
      ..write(obj.recurrenceUnit)
      ..writeByte(11)
      ..write(obj.recurrenceInterval)
      ..writeByte(12)
      ..write(obj.kind)
      ..writeByte(13)
      ..write(obj.isHidden)
      ..writeByte(14)
      ..write(obj.isDefaultEvent)
      ..writeByte(15)
      ..write(obj.calendarEventId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EventKindAdapter extends TypeAdapter<EventKind> {
  @override
  final int typeId = 6;

  @override
  EventKind read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EventKind.birthday;
      case 1:
        return EventKind.anniversary;
      case 2:
        return EventKind.countdown;
      default:
        return EventKind.birthday;
    }
  }

  @override
  void write(BinaryWriter writer, EventKind obj) {
    switch (obj) {
      case EventKind.birthday:
        writer.writeByte(0);
        break;
      case EventKind.anniversary:
        writer.writeByte(1);
        break;
      case EventKind.countdown:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventKindAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurrenceUnitAdapter extends TypeAdapter<RecurrenceUnit> {
  @override
  final int typeId = 3;

  @override
  RecurrenceUnit read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurrenceUnit.none;
      case 1:
        return RecurrenceUnit.year;
      case 2:
        return RecurrenceUnit.month;
      case 3:
        return RecurrenceUnit.week;
      default:
        return RecurrenceUnit.none;
    }
  }

  @override
  void write(BinaryWriter writer, RecurrenceUnit obj) {
    switch (obj) {
      case RecurrenceUnit.none:
        writer.writeByte(0);
        break;
      case RecurrenceUnit.year:
        writer.writeByte(1);
        break;
      case RecurrenceUnit.month:
        writer.writeByte(2);
        break;
      case RecurrenceUnit.week:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
