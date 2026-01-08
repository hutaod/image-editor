import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../models/event_record.dart';
import '../providers/event_provider.dart';
import '../providers/event_record_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/event_display_utils.dart';
import 'event_detail_page.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  String _searchQuery = '';

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final events = ref.watch(eventsProvider);
    final records = ref.watch(eventRecordsProvider);

    // 过滤记录：只显示有记录的事件
    final recordsWithEvents = records.where((record) {
      final event = events.firstWhere(
        (e) => e.id == record.eventId,
        orElse: () => Event.create(
          id: '',
          title: l10n.deletedEvent,
          date: DateTime.now(),
        ),
      );
      return event.id.isNotEmpty;
    }).toList();

    // 根据搜索查询过滤记录
    final filteredRecords = _searchQuery.isEmpty
        ? recordsWithEvents
        : recordsWithEvents.where((record) {
            final event = events.firstWhere(
              (e) => e.id == record.eventId,
              orElse: () => Event.create(
                id: '',
                title: l10n.deletedEvent,
                date: DateTime.now(),
              ),
            );
            // 使用本地化的标题进行搜索，这样可以搜索默认事件
            final displayTitle = EventDisplayUtils.getLocalizedTitle(
              context,
              event,
            );
            return displayTitle.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
          }).toList();

    // 按创建时间倒序排列
    filteredRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: Colors.grey[50], // 微信朋友圈的背景色
      appBar: AppBar(
        title: Text(l10n.community),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () => _showSearchDialog(context, l10n, events, records),
          ),
        ],
      ),
      body: filteredRecords.isEmpty
          ? _buildEmptyState(context, l10n)
          : ListView.separated(
              itemCount: filteredRecords.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey[200], thickness: 0.5),
              itemBuilder: (context, index) {
                final record = filteredRecords[index];
                final event = events.firstWhere(
                  (e) => e.id == record.eventId,
                  orElse: () => Event.create(
                    id: '',
                    title: l10n.deletedEvent,
                    date: DateTime.now(),
                  ),
                );
                return _buildRecordCard(context, record, event, l10n);
              },
            ),
    );
  }

  void _showSearchDialog(
    BuildContext context,
    AppLocalizations l10n,
    List<Event> events,
    List<EventRecord> records,
  ) {
    final TextEditingController searchController = TextEditingController(
      text: _searchQuery,
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 搜索输入框
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                onSubmitted: (value) {
                  Navigator.of(context).pop();
                  _performSearch(value, events, records);
                },
              ),

              const SizedBox(height: 16),

              // 按钮组
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _performSearch(searchController.text, events, records);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.search,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _performSearch(
    String query,
    List<Event> events,
    List<EventRecord> records,
  ) {
    setState(() {
      _searchQuery = query;
    });
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noRecordsFound,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noRecordsFoundDesc,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(
    BuildContext context,
    EventRecord record,
    Event event,
    AppLocalizations l10n,
  ) {
    // 使用统一的工具函数处理事件标题显示
    final displayTitle = EventDisplayUtils.getLocalizedTitle(context, event);

    return GestureDetector(
      onTap: () {
        // 跳转到事件详情页，并定位到对应的记录
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EventDetailPage(
              event: event,
              initialRecordId: record.id, // 传递记录ID用于定位
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 事件名称 - 显示在顶部
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getEventTypeColor(event.kind).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getEventTypeIcon(event.kind),
                    size: 14,
                    color: _getEventTypeColor(event.kind),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    displayTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getEventTypeColor(event.kind),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 文字内容
            if (record.textContent != null && record.textContent!.isNotEmpty)
              _buildTextContent(record.textContent!),

            // 图片内容
            if (record.imagePaths.isNotEmpty)
              _buildImageContent(record.imagePaths, context),

            // 位置信息
            if (record.location != null && record.location!.isNotEmpty)
              _buildLocationContent(record.location!),

            const SizedBox(height: 8),

            // 底部时间
            Text(
              DateFormat('MM-dd HH:mm').format(record.createdAt),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 16, height: 1.4)),
    );
  }

  Widget _buildImageContent(List<String> imagePaths, BuildContext context) {
    if (imagePaths.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: _buildImageGrid(imagePaths, context),
    );
  }

  Widget _buildLocationContent(String location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              location,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<String> imagePaths, BuildContext context) {
    if (imagePaths.length == 1) {
      // 单张图片
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildImageWidget(
          imagePaths[0],
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    } else if (imagePaths.length <= 4) {
      // 2-4张图片，2列布局
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: imagePaths.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImageWidget(
              imagePaths[index],
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          );
        },
      );
    } else {
      // 5张以上图片，3列布局
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: imagePaths.length > 9 ? 9 : imagePaths.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImageWidget(
              imagePaths[index],
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          );
        },
      );
    }
  }

  Widget _buildImageWidget(
    String imagePath, {
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Image.file(
      File(imagePath),
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(Icons.broken_image, color: Colors.grey[400]),
        );
      },
    );
  }

  Color _getEventTypeColor(EventKind kind) {
    switch (kind) {
      case EventKind.birthday:
        return const Color(0xFFFB7185); // 粉色 - 与首页保持一致
      case EventKind.anniversary:
        return const Color(0xFFA78BFA); // 紫色 - 与首页保持一致
      case EventKind.countdown:
        return const Color(0xFF22C55E); // 绿色 - 与首页保持一致
    }
  }

  IconData _getEventTypeIcon(EventKind kind) {
    switch (kind) {
      case EventKind.birthday:
        return Icons.cake;
      case EventKind.anniversary:
        return Icons.favorite;
      case EventKind.countdown:
        return Icons.schedule;
    }
  }
}
