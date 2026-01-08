import 'package:hive/hive.dart';
import 'event.dart';

/// 兼容旧数据的RecurrenceUnit适配器
class RecurrenceUnitLegacyAdapter extends TypeAdapter<RecurrenceUnit> {
  @override
  final int typeId = 1; // 使用旧的typeId

  @override
  RecurrenceUnit read(BinaryReader reader) {
    final value = reader.read();

    // 如果是字符串，转换为枚举
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'none':
          return RecurrenceUnit.none;
        case 'year':
          return RecurrenceUnit.year;
        case 'month':
          return RecurrenceUnit.month;
        case 'week':
          return RecurrenceUnit.week;
        default:
          return RecurrenceUnit.none;
      }
    }

    // 如果是数字，按索引转换
    if (value is int) {
      switch (value) {
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

    // 如果已经是枚举，直接返回
    if (value is RecurrenceUnit) {
      return value;
    }

    // 默认返回none
    return RecurrenceUnit.none;
  }

  @override
  void write(BinaryWriter writer, RecurrenceUnit obj) {
    writer.write(obj.index);
  }
}
