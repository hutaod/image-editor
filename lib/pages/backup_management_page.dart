import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_export_import_service.dart';
import '../l10n/app_localizations.dart';

class BackupManagementPage extends StatefulWidget {
  const BackupManagementPage({super.key});

  @override
  State<BackupManagementPage> createState() => _BackupManagementPageState();
}

class _BackupManagementPageState extends State<BackupManagementPage> {
  final DataExportImportService _dataService = DataExportImportService();
  List<BackupFile> _backupFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final files = await _dataService.getBackupFiles();
      setState(() {
        _backupFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载备份文件失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createBackup() async {
    try {
      // 使用压缩包备份（包含图片）
      final filePath = await _dataService.exportToZipFile();
      if (mounted) {
        final fileName = filePath.split('/').last;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.createBackup}成功: $fileName (包含图片)'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBackupFiles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建备份失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importData() async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.importData),
        content: Text(AppLocalizations.of(context)!.importDataWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 获取ProviderContainer
      final container = ProviderScope.containerOf(context);
      await _dataService.importFromFile(container: container);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.importSuccess),
            backgroundColor: Colors.green,
          ),
        );
        _loadBackupFiles();
        // 不自动返回，让用户看到成功提示
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.importFailed(e.toString())}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup(BackupFile backupFile) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.restoreBackup),
        content: Text(AppLocalizations.of(context)!.restoreBackupWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 获取ProviderContainer
      final container = ProviderScope.containerOf(context);
      await _dataService.restoreBackupFile(
        backupFile.path,
        container: container,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.restoreSuccess),
            backgroundColor: Colors.green,
          ),
        );
        _loadBackupFiles();
        // 不自动返回，让用户看到成功提示
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复备份失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _shareBackup(BackupFile backupFile) async {
    try {
      await Share.shareXFiles([XFile(backupFile.path)]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportBackup(BackupFile backupFile) async {
    try {
      final sourceFile = File(backupFile.path);

      if (!await sourceFile.exists()) {
        throw Exception('备份文件不存在');
      }

      // 读取文件字节数据
      final bytes = await sourceFile.readAsBytes();

      // 使用 FilePicker 保存文件，传入字节数据
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '导出备份文件',
        fileName: backupFile.name,
        bytes: bytes,
        type: FileType.any,
      );

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('导出成功: ${result.split('/').last}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteBackup(BackupFile backupFile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteBackup),
        content: Text(AppLocalizations.of(context)!.deleteBackupWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _dataService.deleteBackupFile(backupFile.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.deleteSuccess),
            backgroundColor: Colors.green,
          ),
        );
        _loadBackupFiles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupManagement),
        actions: [
          IconButton(
            onPressed: _loadBackupFiles,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // 操作按钮区域
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _createBackup,
                    child: Text(l10n.createBackup),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _importData,
                    child: Text(l10n.importData),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // 备份文件列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _backupFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noBackupFiles,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noBackupFilesDesc,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _backupFiles.length,
                    itemBuilder: (context, index) {
                      final backupFile = _backupFiles[index];
                      return _buildBackupFileItem(backupFile);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupFileItem(BackupFile backupFile) {
    final l10n = AppLocalizations.of(context)!;
    final isEncrypted = backupFile.name.toLowerCase().endsWith('.drmbak');
    final isJson = backupFile.name.toLowerCase().endsWith('.json');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          backupFile.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.size}: ${backupFile.formattedSize}'),
            Text('${l10n.createdAt}: ${backupFile.formattedDate}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'restore':
                await _restoreBackup(backupFile);
                break;
              case 'share':
                await _shareBackup(backupFile);
                break;
              case 'export':
                await _exportBackup(backupFile);
                break;
              case 'delete':
                await _deleteBackup(backupFile);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  const Icon(Icons.restore),
                  const SizedBox(width: 8),
                  Text(l10n.restoreBackup),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  const Icon(Icons.share),
                  const SizedBox(width: 8),
                  Text(l10n.share),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  const Icon(Icons.download),
                  const SizedBox(width: 8),
                  Text(l10n.export),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
