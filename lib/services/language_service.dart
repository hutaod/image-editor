import 'package:shared_preferences/shared_preferences.dart';

/// 语言服务
class LanguageService {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static LanguageService get to => _instance;

  // 本地存储的键名
  static const String _languageKey = 'app_language';

  /// 获取当前语言设置
  String getCurrentLanguage() {
    try {
      // 这里可以从SharedPreferences获取，或者使用应用的语言设置
      // 暂时返回默认值，后续可以集成到应用的语言设置中
      return 'zh'; // 默认中文
    } catch (e) {
      print('获取语言设置失败: $e');
      return 'en'; // 失败时返回英文
    }
  }

  /// 设置语言
  Future<void> setLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      print('语言设置已保存: $languageCode');
    } catch (e) {
      print('保存语言设置失败: $e');
    }
  }

  /// 获取保存的语言设置
  Future<String> getSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey) ?? 'zh';
    } catch (e) {
      print('获取保存的语言设置失败: $e');
      return 'zh';
    }
  }
}
