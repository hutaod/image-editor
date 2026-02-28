import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/id_photo_record.dart';
import '../providers/id_photo_provider.dart';
import '../services/template_service.dart';
import '../services/database_service.dart';
import 'id_photo_history_detail_page.dart';

/// 历史记录页面（参考第八张图片）
class IdPhotoHistoryPage extends HookConsumerWidget {
  const IdPhotoHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(idPhotoRecordsProvider);
    final recordsNotifier = ref.read(idPhotoRecordsProvider.notifier);

    // 自动删除7天前的记录
    useEffect(() {
      _cleanupOldRecords(recordsNotifier);
      return null;
    }, []);

    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        title: const Text('电子照'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // 温馨提示（黄色/橙色横幅）
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange[100],
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '温馨提醒:本应用不提供照片的永久存储功能,电子照自保存到列表之日起7天后会自动删除,请尽早提取!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // 记录列表
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '没有更多了...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await recordsNotifier.loadRecords();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return _buildRecordCard(context, record, recordsNotifier);
                      },
                    ),
                  ),
          ),
        ],
      ),
      ),
    );
  }

  void _cleanupOldRecords(IdPhotoRecordsNotifier notifier) async {
    final records = DatabaseService.getAllRecords();
    final now = DateTime.now();
    for (final record in records) {
      final daysSinceCreated = now.difference(record.createdAt).inDays;
      if (daysSinceCreated >= 7) {
        await notifier.deleteRecord(record.id);
      }
    }
  }

  Widget _buildRecordCard(
    BuildContext context,
    IdPhotoRecord record,
    IdPhotoRecordsNotifier notifier,
  ) {
    final template = TemplateService.getTemplateById(record.templateId);
    final daysRemaining = 7 - DateTime.now().difference(record.createdAt).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => IdPhotoHistoryDetailPage(record: record),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 缩略图
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: record.thumbnailPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          File(record.thumbnailPath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.image, size: 40),
              ),
              const SizedBox(width: 12),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template?.name ?? record.templateId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${template?.widthPx ?? 0}*${template?.heightPx ?? 0}px',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '拍摄时间:${_formatDate(record.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (daysRemaining > 0)
                      Text(
                        '剩余 ${daysRemaining} 天自动删除',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                        ),
                      ),
                  ],
                ),
              ),
              // 右箭头
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

}
