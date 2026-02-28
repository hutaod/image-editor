import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/id_photo_template.dart';
import '../providers/id_photo_provider.dart';

/// 尺寸模板页面
class IdPhotoTemplatePage extends ConsumerWidget {
  final bool selectMode;

  const IdPhotoTemplatePage({
    super.key,
    this.selectMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(selectMode ? '选择尺寸' : '尺寸模板'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 中国证件照
          _buildSection(
            context,
            title: '中国证件照',
            templates: templates.where((t) => t.country == 'CN').toList(),
            selectMode: selectMode,
          ),
          const SizedBox(height: 24),
          // 美国证件照
          _buildSection(
            context,
            title: '美国证件照',
            templates: templates.where((t) => t.country == 'US').toList(),
            selectMode: selectMode,
          ),
          const SizedBox(height: 24),
          // 日本证件照
          _buildSection(
            context,
            title: '日本证件照',
            templates: templates.where((t) => t.country == 'JP').toList(),
            selectMode: selectMode,
          ),
          const SizedBox(height: 24),
          // 欧洲证件照
          _buildSection(
            context,
            title: '欧洲证件照',
            templates: templates.where((t) => t.country == 'EU').toList(),
            selectMode: selectMode,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<IdPhotoTemplate> templates,
    required bool selectMode,
  }) {
    if (templates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...templates.map((template) => _buildTemplateCard(
              context,
              template: template,
              selectMode: selectMode,
            )),
      ],
    );
  }

  Widget _buildTemplateCard(
    BuildContext context, {
    required IdPhotoTemplate template,
    required bool selectMode,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: selectMode
            ? () {
                Navigator.of(context).pop(template);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 尺寸预览
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Text(
                    '${template.widthMm.toInt()}×${template.heightMm.toInt()}',
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 模板信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          template.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (template.isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${template.widthMm} × ${template.heightMm} mm',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${template.widthPx} × ${template.heightPx} px @ ${template.dpi} DPI',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '背景: ${template.backgroundColor} | 建议打印: ${template.printCount} 张',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (selectMode)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
