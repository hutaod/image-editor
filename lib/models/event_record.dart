import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'event_record.g.dart';

/// 事件记录类型
@HiveType(typeId: 4)
enum RecordType {
  @HiveField(0)
  photo,
  @HiveField(1)
  text,
  @HiveField(2)
  mixed,
}

/// 事件记录数据模型
@HiveType(typeId: 5)
class EventRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String eventId; // 关联的事件ID

  @HiveField(2)
  RecordType type;

  @HiveField(3)
  String? textContent; // 文字内容

  @HiveField(4)
  List<String> imagePaths; // 图片路径列表

  @HiveField(5)
  DateTime createdAt; // 创建时间

  @HiveField(6)
  DateTime? updatedAt; // 更新时间

  @HiveField(7)
  String? location; // 位置信息（可选）

  EventRecord({
    required this.id,
    required this.eventId,
    required this.type,
    this.textContent,
    this.imagePaths = const [],
    required this.createdAt,
    this.updatedAt,
    this.location,
  });

  /// 创建文字记录
  factory EventRecord.createText({
    required String id,
    required String eventId,
    required String textContent,
    String? location,
  }) {
    final now = DateTime.now();
    return EventRecord(
      id: id,
      eventId: eventId,
      type: RecordType.text,
      textContent: textContent,
      createdAt: now,
      location: location,
    );
  }

  /// 创建图片记录
  factory EventRecord.createPhoto({
    required String id,
    required String eventId,
    required List<String> imagePaths,
    String? location,
  }) {
    final now = DateTime.now();
    return EventRecord(
      id: id,
      eventId: eventId,
      type: RecordType.photo,
      imagePaths: imagePaths,
      createdAt: now,
      location: location,
    );
  }

  /// 创建混合记录（图片+文字）
  factory EventRecord.createMixed({
    required String id,
    required String eventId,
    required String textContent,
    required List<String> imagePaths,
    String? location,
  }) {
    final now = DateTime.now();
    return EventRecord(
      id: id,
      eventId: eventId,
      type: RecordType.mixed,
      textContent: textContent,
      imagePaths: imagePaths,
      createdAt: now,
      location: location,
    );
  }

  /// 更新记录
  void updateRecord({
    String? textContent,
    List<String>? imagePaths,
    String? location,
  }) {
    if (textContent != null) this.textContent = textContent;
    if (imagePaths != null) this.imagePaths = imagePaths;
    if (location != null) this.location = location;
    updatedAt = DateTime.now();
  }

  /// 获取格式化的创建时间
  String get formattedCreatedAt {
    return DateFormat('yyyy-MM-dd HH:mm').format(createdAt);
  }

  /// 获取格式化的更新时间
  String? get formattedUpdatedAt {
    return updatedAt != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(updatedAt!)
        : null;
  }

  /// 是否有图片
  bool get hasImages => imagePaths.isNotEmpty;

  /// 是否有文字内容
  bool get hasText => textContent != null && textContent!.isNotEmpty;

  /// 获取记录摘要（用于列表显示）
  String get summary {
    if (type == RecordType.photo) {
      return '📷 ${imagePaths.length}张照片';
    } else if (type == RecordType.text) {
      return textContent!.length > 50
          ? '${textContent!.substring(0, 50)}...'
          : textContent!;
    } else {
      // mixed
      final textSummary = textContent!.length > 30
          ? '${textContent!.substring(0, 30)}...'
          : textContent!;
      return '📷 ${imagePaths.length}张照片 + $textSummary';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'type': type.name,
    'textContent': textContent,
    'imagePaths': imagePaths,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'location': location,
  };

  static EventRecord fromJson(Map<String, dynamic> json) {
    return EventRecord(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      type: _parseRecordType(json['type'] as String),
      textContent: json['textContent'] as String?,
      imagePaths: List<String>.from(json['imagePaths'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      location: json['location'] as String?,
    );
  }

  static RecordType _parseRecordType(String name) {
    switch (name) {
      case 'photo':
        return RecordType.photo;
      case 'text':
        return RecordType.text;
      case 'mixed':
        return RecordType.mixed;
      default:
        return RecordType.text;
    }
  }
}
