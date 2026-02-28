import '../models/id_photo_template.dart';

/// 模板服务
class TemplateService {
  static List<IdPhotoTemplate>? _templates;

  /// 获取所有模板
  static List<IdPhotoTemplate> getAllTemplates() {
    _templates ??= IdPhotoTemplate.getDefaultTemplates();
    return _templates!;
  }

  /// 根据 ID 获取模板
  static IdPhotoTemplate? getTemplateById(String id) {
    final templates = getAllTemplates();
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 根据国家获取模板
  static List<IdPhotoTemplate> getTemplatesByCountry(String? country) {
    if (country == null) return getAllTemplates();
    return getAllTemplates().where((t) => t.country == country).toList();
  }

  /// 获取免费模板
  static List<IdPhotoTemplate> getFreeTemplates() {
    return getAllTemplates().where((t) => !t.isPremium).toList();
  }

  /// 获取付费模板
  static List<IdPhotoTemplate> getPremiumTemplates() {
    return getAllTemplates().where((t) => t.isPremium).toList();
  }

  /// 毫米转像素（根据 DPI）
  static int mmToPx(double mm, int dpi) {
    // 1 inch = 25.4 mm
    // pixels = (mm / 25.4) * dpi
    return ((mm / 25.4) * dpi).round();
  }

  /// 像素转毫米（根据 DPI）
  static double pxToMm(int px, int dpi) {
    // mm = (px / dpi) * 25.4
    return (px / dpi) * 25.4;
  }
}
