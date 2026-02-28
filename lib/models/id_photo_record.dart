import 'package:hive/hive.dart';

part 'id_photo_record.g.dart';

/// 证件照处理记录
@HiveType(typeId: 0)
class IdPhotoRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? originalImagePath; // 原始图片路径

  @HiveField(2)
  String? processedImagePath; // 处理后的图片路径

  @HiveField(3)
  String templateId; // 使用的模板ID

  @HiveField(4)
  DateTime createdAt; // 创建时间

  @HiveField(5)
  DateTime updatedAt; // 更新时间

  @HiveField(6)
  Map<String, dynamic>? editParams; // 编辑参数（裁剪、背景色等）

  @HiveField(7)
  String? thumbnailPath; // 缩略图路径

  IdPhotoRecord({
    required this.id,
    this.originalImagePath,
    this.processedImagePath,
    required this.templateId,
    required this.createdAt,
    required this.updatedAt,
    this.editParams,
    this.thumbnailPath,
  });

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalImagePath': originalImagePath,
      'processedImagePath': processedImagePath,
      'templateId': templateId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'editParams': editParams,
      'thumbnailPath': thumbnailPath,
    };
  }

  factory IdPhotoRecord.fromMap(Map<String, dynamic> map) {
    return IdPhotoRecord(
      id: map['id'] as String,
      originalImagePath: map['originalImagePath'] as String?,
      processedImagePath: map['processedImagePath'] as String?,
      templateId: map['templateId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      editParams: map['editParams'] as Map<String, dynamic>?,
      thumbnailPath: map['thumbnailPath'] as String?,
    );
  }

  /// 创建副本并更新
  IdPhotoRecord copyWith({
    String? id,
    String? originalImagePath,
    String? processedImagePath,
    String? templateId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? editParams,
    String? thumbnailPath,
  }) {
    return IdPhotoRecord(
      id: id ?? this.id,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      processedImagePath: processedImagePath ?? this.processedImagePath,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      editParams: editParams ?? this.editParams,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}
