import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers/theme_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
            ),
      body: ListView(
      children: [
        const SizedBox(height: 8),
          // 外观设置
          _buildSectionHeader('外观'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主题模式'),
            subtitle: const Text('选择浅色、深色或跟随系统'),
            trailing: DropdownButton<AppThemeMode>(
              value: ref.watch(themeModeProvider),
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setMode(value);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: AppThemeMode.system,
                  child: Text('跟随系统'),
                ),
                DropdownMenuItem(
                  value: AppThemeMode.light,
                  child: Text('浅色'),
                ),
                DropdownMenuItem(
                  value: AppThemeMode.dark,
                  child: Text('深色'),
                ),
              ],
            ),
          ),
        const Divider(),
        // 关于
          _buildSectionHeader('关于'),
        ListTile(
          leading: const Icon(Icons.info),
            title: const Text('关于应用'),
            subtitle: const Text('查看应用版本和说明'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showAboutDialog(context),
        ),
        const SizedBox(height: 20),
      ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (context.mounted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                  Icons.image,
                  size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
              const SizedBox(width: 16),
            Expanded(
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                      '图片编辑器',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '版本 ${packageInfo.version}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
                  ],
              ),
            ),
          ],
        ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '一款简洁美观的图片编辑应用，提供去水印和图片拼接功能。',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                Text(
                  '主要功能：',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text('• 智能去水印'),
                Text('• 图片拼接（横向、纵向、网格）'),
                Text('• 简洁美观的界面设计'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    }
  }
}
