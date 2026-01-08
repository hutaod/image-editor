import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 支持的语言
enum SupportedLocale {
  system('system', '跟随系统'),
  english('en', 'English'),
  chinese('zh', '中文');

  const SupportedLocale(this.code, this.displayName);
  final String code;
  final String displayName;

  Locale? get locale {
    switch (this) {
      case SupportedLocale.system:
        return null; // 返回 null 表示跟随系统
      case SupportedLocale.english:
        return const Locale('en');
      case SupportedLocale.chinese:
        return const Locale('zh');
    }
  }
}

// 本地化状态
class LocalizationState {
  final SupportedLocale selectedLocale;
  final Locale? currentLocale;

  const LocalizationState({required this.selectedLocale, this.currentLocale});

  LocalizationState copyWith({
    SupportedLocale? selectedLocale,
    Locale? currentLocale,
  }) {
    return LocalizationState(
      selectedLocale: selectedLocale ?? this.selectedLocale,
      currentLocale: currentLocale ?? this.currentLocale,
    );
  }
}

// 本地化状态管理器
class LocalizationNotifier extends StateNotifier<LocalizationState> {
  LocalizationNotifier()
    : super(const LocalizationState(selectedLocale: SupportedLocale.system)) {
    _loadSettings();
  }

  late SharedPreferences _prefs;

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    final savedLocaleCode = _prefs.getString('selected_locale') ?? 'system';
    final selectedLocale = SupportedLocale.values.firstWhere(
      (locale) => locale.code == savedLocaleCode,
      orElse: () => SupportedLocale.system,
    );

    state = LocalizationState(selectedLocale: selectedLocale);
    await _updateCurrentLocale();
  }

  Future<void> _saveSettings() async {
    await _prefs.setString('selected_locale', state.selectedLocale.code);
  }

  Future<void> _updateCurrentLocale() async {
    Locale? newLocale;

    if (state.selectedLocale == SupportedLocale.system) {
      // 获取系统语言
      final systemLocale = PlatformDispatcher.instance.locale;
      if (systemLocale.languageCode == 'zh') {
        newLocale = const Locale('zh');
      } else {
        newLocale = const Locale('en');
      }
    } else {
      newLocale = state.selectedLocale.locale;
    }

    if (newLocale != state.currentLocale) {
      state = state.copyWith(currentLocale: newLocale);
    }
  }

  Future<void> setLocale(SupportedLocale locale) async {
    state = state.copyWith(selectedLocale: locale);
    await _updateCurrentLocale();
    await _saveSettings();
  }

  // 获取当前语言代码
  String get currentLanguageCode {
    return state.currentLocale?.languageCode ?? 'en';
  }

  // 检查是否为中文
  bool get isChinese {
    return currentLanguageCode == 'zh';
  }

  // 检查是否为英文
  bool get isEnglish {
    return currentLanguageCode == 'en';
  }
}

// Provider
final localizationProvider =
    StateNotifierProvider<LocalizationNotifier, LocalizationState>(
      (ref) => LocalizationNotifier(),
    );

// 便捷访问器
final currentLocaleProvider = Provider<Locale?>((ref) {
  return ref.watch(localizationProvider).currentLocale;
});

final isChineseProvider = Provider<bool>((ref) {
  return ref.watch(localizationProvider.notifier).isChinese;
});

final isEnglishProvider = Provider<bool>((ref) {
  return ref.watch(localizationProvider.notifier).isEnglish;
});
