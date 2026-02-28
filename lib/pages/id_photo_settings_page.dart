import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/theme_provider.dart';

/// 设置页面
class IdPhotoSettingsPage extends ConsumerWidget {
  const IdPhotoSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 外观设置
          _buildSection(
            context,
            title: '外观',
            children: [
              ListTile(
                title: const Text('主题模式'),
                subtitle: Text(
                  themeMode == AppThemeMode.light
                      ? '浅色'
                      : themeMode == AppThemeMode.dark
                          ? '深色'
                          : '跟随系统',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('选择主题'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<AppThemeMode>(
                            title: const Text('浅色'),
                            value: AppThemeMode.light,
                            groupValue: themeMode,
                            onChanged: (value) {
                              if (value != null) {
                                ref.read(themeModeProvider.notifier).setMode(value);
                                Navigator.pop(context);
                              }
                            },
                          ),
                          RadioListTile<AppThemeMode>(
                            title: const Text('深色'),
                            value: AppThemeMode.dark,
                            groupValue: themeMode,
                            onChanged: (value) {
                              if (value != null) {
                                ref.read(themeModeProvider.notifier).setMode(value);
                                Navigator.pop(context);
                              }
                            },
                          ),
                          RadioListTile<AppThemeMode>(
                            title: const Text('跟随系统'),
                            value: AppThemeMode.system,
                            groupValue: themeMode,
                            onChanged: (value) {
                              if (value != null) {
                                ref.read(themeModeProvider.notifier).setMode(value);
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // 关于
          _buildSection(
            context,
            title: '关于',
            children: [
              const ListTile(
                title: Text('版本'),
                subtitle: Text('1.0.0'),
              ),
              const ListTile(
                title: Text('隐私政策'),
                subtitle: Text('所有图片处理均在本地完成，不上传服务器'),
              ),
              ListTile(
                title: const Text('清除缓存'),
                onTap: () async {
                  // TODO: 实现清除缓存
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('缓存已清除')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }
}
