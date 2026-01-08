import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/event_record.dart';
import '../models/event.dart';
import '../providers/event_record_provider.dart';
import 'add_record_page.dart';

class RecordDetailPage extends ConsumerWidget {
  const RecordDetailPage({super.key, required this.record, this.event});

  final EventRecord record;
  final Event? event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // 监听记录数据变化，获取最新的记录信息
    final records = ref.watch(eventRecordsProvider);

    // 获取最新的记录数据
    final currentRecord = records.firstWhere(
      (r) => r.id == record.id,
      orElse: () => record,
    );

    // 获取事件主题色
    final primaryColor = _getEventPrimaryColor(event);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentRecord.summary),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editRecord(context, currentRecord),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog(context, ref, currentRecord, l10n);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text(
                      l10n.deleteRecord,
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 记录类型和时间
            _buildRecordHeader(currentRecord, theme, l10n),
            const SizedBox(height: 24),

            // 文字内容
            if (currentRecord.hasText) ...[
              _buildTextContent(currentRecord, theme, l10n),
              const SizedBox(height: 24),
            ],

            // 照片
            if (currentRecord.hasImages) ...[
              _buildPhotoSection(currentRecord, theme, l10n),
              const SizedBox(height: 24),
            ],

            // 位置信息
            if (currentRecord.location != null &&
                currentRecord.location!.isNotEmpty) ...[
              _buildLocationInfo(currentRecord, theme, l10n),
              const SizedBox(height: 24),
            ],

            // 时间信息
            _buildTimeInfo(currentRecord, theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordHeader(
    EventRecord currentRecord,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getRecordTypeColor(currentRecord.type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getRecordTypeColor(currentRecord.type).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getRecordTypeIcon(currentRecord.type),
            color: _getRecordTypeColor(currentRecord.type),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getRecordTypeText(currentRecord.type, l10n),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getRecordTypeColor(currentRecord.type),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentRecord.formattedCreatedAt,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent(
    EventRecord currentRecord,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recordContent,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Text(
            currentRecord.textContent!,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(
    EventRecord currentRecord,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.photosCount(currentRecord.imagePaths.length),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: currentRecord.imagePaths.length,
          itemBuilder: (context, index) {
            return _buildPhotoThumbnail(currentRecord.imagePaths[index], theme);
          },
        ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(String imagePath, ThemeData theme) {
    return GestureDetector(
      onTap: () => _showPhotoViewer(imagePath),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(imagePath),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: theme.colorScheme.surface,
              child: Icon(Icons.broken_image, color: theme.colorScheme.outline),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationInfo(
    EventRecord currentRecord,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.location,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentRecord.location!,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(
    EventRecord currentRecord,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.timeInfo,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              _buildTimeRow(
                l10n.createdTime,
                currentRecord.formattedCreatedAt,
                Icons.access_time,
                theme,
              ),
              if (currentRecord.updatedAt != null) ...[
                const SizedBox(height: 12),
                _buildTimeRow(
                  l10n.updatedTime,
                  currentRecord.formattedUpdatedAt!,
                  Icons.update,
                  theme,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow(
    String label,
    String time,
    IconData icon,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(time, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Color _getRecordTypeColor(RecordType type) {
    switch (type) {
      case RecordType.photo:
        return Colors.blue;
      case RecordType.text:
        return Colors.green;
      case RecordType.mixed:
        return Colors.purple;
    }
  }

  IconData _getRecordTypeIcon(RecordType type) {
    switch (type) {
      case RecordType.photo:
        return Icons.photo_camera;
      case RecordType.text:
        return Icons.text_fields;
      case RecordType.mixed:
        return Icons.photo_library;
    }
  }

  String _getRecordTypeText(RecordType type, AppLocalizations l10n) {
    switch (type) {
      case RecordType.photo:
        return l10n.photoRecord;
      case RecordType.text:
        return l10n.textRecord;
      case RecordType.mixed:
        return l10n.mixedRecord;
    }
  }

  void _editRecord(BuildContext context, EventRecord currentRecord) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddRecordPage(
          eventId: currentRecord.eventId,
          record: currentRecord,
          event: event, // 传递事件信息
        ),
      ),
    );
  }

  void _showPhotoViewer(String imagePath) {
    // TODO: 实现照片查看器
    // 可以使用 photo_view 插件或自定义实现
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    EventRecord currentRecord,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteRecord),
        content: Text(l10n.confirmDeleteRecordDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(eventRecordsProvider.notifier)
                  .deleteRecord(currentRecord.id);
              Navigator.of(context).pop();
            },
            child: Text(l10n.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 获取事件主题色 - 与事件详情页保持一致
  Color _getEventPrimaryColor(Event? event) {
    if (event == null) {
      return const Color(0xFF22C55E); // 默认使用倒数日颜色
    }

    // 使用与事件详情页完全相同的颜色值
    switch (event.kind) {
      case EventKind.birthday:
        return const Color(0xFFFB7185); // 粉色
      case EventKind.anniversary:
        return const Color(0xFFA78BFA); // 紫色
      case EventKind.countdown:
        return const Color(0xFF22C55E); // 绿色
    }
  }
}
