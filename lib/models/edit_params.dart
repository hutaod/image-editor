/// 编辑参数
class EditParams {
  final CropParams? crop;
  final BackgroundParams? background;
  final AdjustParams? adjust;

  const EditParams({
    this.crop,
    this.background,
    this.adjust,
  });

  Map<String, dynamic> toMap() {
    return {
      'crop': crop?.toMap(),
      'background': background?.toMap(),
      'adjust': adjust?.toMap(),
    };
  }

  factory EditParams.fromMap(Map<String, dynamic> map) {
    return EditParams(
      crop: map['crop'] != null ? CropParams.fromMap(map['crop'] as Map<String, dynamic>) : null,
      background: map['background'] != null
          ? BackgroundParams.fromMap(map['background'] as Map<String, dynamic>)
          : null,
      adjust: map['adjust'] != null
          ? AdjustParams.fromMap(map['adjust'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// 裁剪参数
class CropParams {
  final double left;
  final double top;
  final double width;
  final double height;
  final double aspectRatio;

  const CropParams({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.aspectRatio,
  });

  Map<String, dynamic> toMap() {
    return {
      'left': left,
      'top': top,
      'width': width,
      'height': height,
      'aspectRatio': aspectRatio,
    };
  }

  factory CropParams.fromMap(Map<String, dynamic> map) {
    return CropParams(
      left: (map['left'] as num).toDouble(),
      top: (map['top'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      aspectRatio: (map['aspectRatio'] as num).toDouble(),
    );
  }
}

/// 背景替换参数
class BackgroundParams {
  final String color; // 颜色值（hex）
  final double tolerance; // 容差（0-1）
  final List<EraseRegion>? manualErase; // 手动擦除区域

  const BackgroundParams({
    required this.color,
    required this.tolerance,
    this.manualErase,
  });

  Map<String, dynamic> toMap() {
    return {
      'color': color,
      'tolerance': tolerance,
      'manualErase': manualErase?.map((e) => e.toMap()).toList(),
    };
  }

  factory BackgroundParams.fromMap(Map<String, dynamic> map) {
    return BackgroundParams(
      color: map['color'] as String,
      tolerance: (map['tolerance'] as num).toDouble(),
      manualErase: map['manualErase'] != null
          ? (map['manualErase'] as List)
              .map((e) => EraseRegion.fromMap(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

/// 手动擦除区域
class EraseRegion {
  final double x;
  final double y;
  final double radius;

  const EraseRegion({
    required this.x,
    required this.y,
    required this.radius,
  });

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'radius': radius,
    };
  }

  factory EraseRegion.fromMap(Map<String, dynamic> map) {
    return EraseRegion(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      radius: (map['radius'] as num).toDouble(),
    );
  }
}

/// 图像调节参数
class AdjustParams {
  final double brightness; // -1.0 到 1.0
  final double contrast; // -1.0 到 1.0
  final double saturation; // -1.0 到 1.0
  final double sharpness; // 0.0 到 1.0
  final double denoise; // 0.0 到 1.0

  const AdjustParams({
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.sharpness = 0.0,
    this.denoise = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
      'sharpness': sharpness,
      'denoise': denoise,
    };
  }

  factory AdjustParams.fromMap(Map<String, dynamic> map) {
    return AdjustParams(
      brightness: (map['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (map['contrast'] as num?)?.toDouble() ?? 0.0,
      saturation: (map['saturation'] as num?)?.toDouble() ?? 0.0,
      sharpness: (map['sharpness'] as num?)?.toDouble() ?? 0.0,
      denoise: (map['denoise'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
