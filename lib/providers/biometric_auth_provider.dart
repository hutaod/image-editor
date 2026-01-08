import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/biometric_auth_service.dart';
import '../models/event.dart';
import 'event_provider.dart';

/// 生物识别验证状态
class BiometricAuthState {
  final bool isAuthenticated;
  final bool isSupported;
  final bool hasAvailableBiometrics;
  final String? primaryBiometricName;
  final String? lastError;

  BiometricAuthState({
    this.isAuthenticated = false,
    this.isSupported = false,
    this.hasAvailableBiometrics = false,
    this.primaryBiometricName,
    this.lastError,
  });

  BiometricAuthState copyWith({
    bool? isAuthenticated,
    bool? isSupported,
    bool? hasAvailableBiometrics,
    String? primaryBiometricName,
    String? lastError,
  }) {
    return BiometricAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isSupported: isSupported ?? this.isSupported,
      hasAvailableBiometrics:
          hasAvailableBiometrics ?? this.hasAvailableBiometrics,
      primaryBiometricName: primaryBiometricName ?? this.primaryBiometricName,
      lastError: lastError ?? this.lastError,
    );
  }
}

/// 生物识别验证状态管理
class BiometricAuthNotifier extends StateNotifier<BiometricAuthState> {
  BiometricAuthNotifier() : super(BiometricAuthState()) {
    // 延迟初始化，避免阻塞应用启动
    Future.microtask(_initialize);
  }

  final BiometricAuthService _authService = BiometricAuthService();

  /// 初始化检查设备支持情况
  Future<void> _initialize() async {
    try {
      final isSupported = await _authService.isDeviceSupported();
      final hasAvailableBiometrics = await _authService
          .hasAvailableBiometrics();
      final primaryBiometricName = hasAvailableBiometrics
          ? await _authService.getPrimaryBiometricName()
          : null;

      if (mounted) {
        state = state.copyWith(
          isSupported: isSupported,
          hasAvailableBiometrics: hasAvailableBiometrics,
          primaryBiometricName: primaryBiometricName,
        );
      }
    } catch (e) {
      // 如果初始化失败，保持默认状态
      print('Debug: 生物识别服务初始化失败: $e');
    }
  }

  /// 执行生物识别验证
  Future<bool> authenticate({
    String? reason,
    String? cancelButton,
    String? goToSettingsButton,
    String? goToSettingsDescription,
  }) async {
    print('Debug: BiometricAuthNotifier.authenticate 开始');

    final result = await _authService.authenticate(
      reason: reason,
      cancelButton: cancelButton,
      goToSettingsButton: goToSettingsButton,
      goToSettingsDescription: goToSettingsDescription,
    );

    print('Debug: 验证结果 - success: ${result.success}, error: ${result.error}');

    state = state.copyWith(
      isAuthenticated: result.success,
      lastError: result.success ? null : result.error,
    );

    print(
      'Debug: 状态已更新 - isAuthenticated: ${state.isAuthenticated}, lastError: ${state.lastError}',
    );

    return result.success;
  }

  /// 重置验证状态（用于登出或超时）
  void reset() {
    state = state.copyWith(isAuthenticated: false, lastError: null);
  }

  /// 检查是否可以显示隐藏事件
  bool canShowHiddenEvents() {
    return state.isAuthenticated && state.hasAvailableBiometrics;
  }
}

/// 生物识别验证状态 Provider
final biometricAuthProvider =
    StateNotifierProvider<BiometricAuthNotifier, BiometricAuthState>(
      (ref) => BiometricAuthNotifier(),
    );

/// 过滤后的事件列表 Provider
final filteredEventsProvider = Provider<List<Event>>((ref) {
  final events = ref.watch(eventsProvider);
  final authState = ref.watch(biometricAuthProvider);

  // 如果已验证，显示所有事件
  if (authState.isAuthenticated) {
    return events;
  }

  // 如果没有可用的生物识别，也显示所有事件（避免功能不可用）
  if (!authState.hasAvailableBiometrics) {
    return events;
  }

  // 否则过滤掉隐藏的事件
  return events.where((event) => !event.isHidden).toList();
});
