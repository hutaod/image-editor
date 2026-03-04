import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../services/template_service.dart';
import '../models/id_photo_template.dart';
import 'id_photo_history_page.dart';
import 'id_photo_tools_page.dart';
import 'id_photo_profile_page.dart';
import 'id_photo_template_page.dart';
import 'id_photo_source_page.dart';
import 'id_photo_change_background_page.dart';
import 'id_photo_edit_page.dart';

/// 证件照首页
class IdPhotoHomePage extends HookConsumerWidget {
  const IdPhotoHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = useState(0);

    // 获取热门尺寸（前6个）
    final hotTemplates = TemplateService.getAllTemplates().take(6).toList();
    // 获取其他尺寸（除了热门尺寸外的其他尺寸）
    final otherTemplates = TemplateService.getAllTemplates().skip(6).toList();

    return Scaffold(
      body: IndexedStack(
        index: currentIndex.value,
        children: [
          _buildMainPage(context, ref, hotTemplates, otherTemplates),
          const IdPhotoToolsPage(),
          const IdPhotoHistoryPage(),
          const IdPhotoProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context, currentIndex),
    );
  }

  Widget _buildMainPage(
    BuildContext context,
    WidgetRef ref,
    List<IdPhotoTemplate> hotTemplates,
    List<IdPhotoTemplate> otherTemplates,
  ) {
    return Scaffold(
      backgroundColor: Colors.green, // 绿色背景
      appBar: AppBar(
        title: const Text('证件照生成器'),
        centerTitle: true,
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // // 主标题和副标题
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           const Text(
              //             '证件照生成器',
              //             style: TextStyle(
              //               fontSize: 24,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //           const SizedBox(height: 4),
              //           Text(
              //             '3秒快速生成',
              //             style: TextStyle(
              //               fontSize: 14,
              //               color: Colors.grey[600],
              //             ),
              //           ),
              //         ],
              //       ),
              //       // 人物插图（占位）
              //       Container(
              //         width: 80,
              //         height: 80,
              //         decoration: BoxDecoration(
              //           color: Colors.purple[100],
              //           shape: BoxShape.circle,
              //         ),
              //         child: const Icon(Icons.person, size: 40),
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 24),

              // 功能卡片
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 一寸照大卡片
                      Expanded(
                        flex: 2,
                        child: _buildFeatureCard(
                          context,
                          title: '一寸照',
                          subtitle: '25x35mm | 295x413px',
                          icon: Icons.photo_camera,
                          color: Colors.blue,
                          isLarge: true,
                          onTap: () {
                            _navigateToCamera(context, 'china_1inch');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 右侧两个小卡片
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: _buildFeatureCard(
                                context,
                                title: '修改底色',
                                subtitle: '已有底色修改...',
                                icon: Icons.color_lens,
                                color: Colors.orange,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const IdPhotoChangeBackgroundPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _buildFeatureCard(
                                context,
                                title: '图片编辑',
                                subtitle: '修改kb与dpi...',
                                icon: Icons.auto_fix_high,
                                color: Colors.purple,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const IdPhotoEditPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 热门尺寸
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.red[400],
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '热门尺寸',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const IdPhotoTemplatePage(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.orange[700],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '其他尺寸',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 热门尺寸列表
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: hotTemplates.map((template) {
                    return _buildSizeItem(context, template);
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false, // 是否是大卡片（一寸照）
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: isLarge ? 48 : 40,
                height: isLarge ? 48 : 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: isLarge ? 28 : 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isLarge ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isLarge ? 13 : 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isLarge) ...[
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeItem(BuildContext context, IdPhotoTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          _navigateToCamera(context, template.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 尺寸预览框
              Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Text(
                    '${template.widthMm.toInt()}×${template.heightMm.toInt()}',
                    style: const TextStyle(fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 尺寸信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${template.widthMm.toStringAsFixed(1)}×${template.heightMm.toStringAsFixed(1)}mm | ${template.widthPx}×${template.heightPx}px',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // 图标
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(
    BuildContext context,
    ValueNotifier<int> currentIndex,
  ) {
    return BottomNavigationBar(
      currentIndex: currentIndex.value,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey[400],
      selectedLabelStyle: const TextStyle(fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      iconSize: 24,
      elevation: 8,
      onTap: (index) {
        currentIndex.value = index;
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: '证件照'),
        BottomNavigationBarItem(icon: Icon(Icons.build), label: '小工具'),
        BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: '电子照'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: '个人中心'),
      ],
    );
  }

  void _navigateToCamera(BuildContext context, String templateId) {
    final template = TemplateService.getTemplateById(templateId);
    if (template != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => IdPhotoSourcePage(template: template),
        ),
      );
    }
  }
}
