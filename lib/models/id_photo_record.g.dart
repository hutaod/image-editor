// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'id_photo_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IdPhotoRecordAdapter extends TypeAdapter<IdPhotoRecord> {
  @override
  final int typeId = 0;

  @override
  IdPhotoRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IdPhotoRecord(
      id: fields[0] as String,
      originalImagePath: fields[1] as String?,
      processedImagePath: fields[2] as String?,
      templateId: fields[3] as String,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      editParams: (fields[6] as Map?)?.cast<String, dynamic>(),
      thumbnailPath: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, IdPhotoRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.originalImagePath)
      ..writeByte(2)
      ..write(obj.processedImagePath)
      ..writeByte(3)
      ..write(obj.templateId)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.editParams)
      ..writeByte(7)
      ..write(obj.thumbnailPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdPhotoRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
