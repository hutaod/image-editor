import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 设置键名常量
class SettingsKeys {
  static const String notificationsEnabled = 'notifications_enabled';
  static const String advanceReminderEnabled = 'advance_reminder_enabled';
  static const String advanceReminderDays = 'advance_reminder_days';
  static const String autoBackupEnabled = 'auto_backup_enabled';
  static const String lastBackupTime = 'last_backup_time';
}

// 设置状态类
class SettingsState {
  final bool notificationsEnabled;
  final bool advanceReminderEnabled;
  final int advanceReminderDays;
  final bool autoBackupEnabled;
  final DateTime? lastBackupTime;

  const SettingsState({
    this.notificationsEnabled = true,
    this.advanceReminderEnabled = true,
    this.advanceReminderDays = 1,
    this.autoBackupEnabled = false,
    this.lastBackupTime,
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? advanceReminderEnabled,
    int? advanceReminderDays,
    bool? autoBackupEnabled,
    DateTime? lastBackupTime,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      advanceReminderEnabled:
          advanceReminderEnabled ?? this.advanceReminderEnabled,
      advanceReminderDays: advanceReminderDays ?? this.advanceReminderDays,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
    );
  }
}

// 设置状态管理器
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  late SharedPreferences _prefs;

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      notificationsEnabled:
          _prefs.getBool(SettingsKeys.notificationsEnabled) ?? true,
      advanceReminderEnabled:
          _prefs.getBool(SettingsKeys.advanceReminderEnabled) ?? true,
      advanceReminderDays: _prefs.getInt(SettingsKeys.advanceReminderDays) ?? 1,
      autoBackupEnabled:
          _prefs.getBool(SettingsKeys.autoBackupEnabled) ?? false,
      lastBackupTime: _prefs.getString(SettingsKeys.lastBackupTime) != null
          ? DateTime.parse(_prefs.getString(SettingsKeys.lastBackupTime)!)
          : null,
    );
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool(
      SettingsKeys.notificationsEnabled,
      state.notificationsEnabled,
    );
    await _prefs.setBool(
      SettingsKeys.advanceReminderEnabled,
      state.advanceReminderEnabled,
    );
    await _prefs.setInt(
      SettingsKeys.advanceReminderDays,
      state.advanceReminderDays,
    );
    await _prefs.setBool(
      SettingsKeys.autoBackupEnabled,
      state.autoBackupEnabled,
    );
    if (state.lastBackupTime != null) {
      await _prefs.setString(
        SettingsKeys.lastBackupTime,
        state.lastBackupTime!.toIso8601String(),
      );
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setAdvanceReminderEnabled(bool enabled) async {
    state = state.copyWith(advanceReminderEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setAdvanceReminderDays(int days) async {
    state = state.copyWith(advanceReminderDays: days);
    await _saveSettings();
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    state = state.copyWith(autoBackupEnabled: enabled);
    await _saveSettings();
  }

  Future<void> updateLastBackupTime() async {
    state = state.copyWith(lastBackupTime: DateTime.now());
    await _saveSettings();
  }
}

// Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);


