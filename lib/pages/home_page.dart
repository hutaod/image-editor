import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'remove_watermark_page.dart';
import 'image_crop_page.dart';
import 'image_adjust_page.dart';
import 'image_text_page.dart';
import 'image_blur_page.dart';
import 'image_mosaic_page.dart';
import 'image_brush_page.dart';
import 'image_watermark_page.dart';
import 'image_stitch_page.dart';
import 'image_compress_page.dart';

enum ImageEditFeature {
  removeWatermark,
  addWatermark,
  crop,
  rotate,
  adjust,
  blur,
  mosaic,
  brush,
  addText,
  formatConvert,
  trimEdges,
  addBorder,
  enlarge,
  compress,
  stitch,
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图片编辑器'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 实现搜索功能
            },
          ),
        ],
      ),
      body: ListView(
              padding: const EdgeInsets.all(16),
                  children: [
          const SizedBox(height: 8),
          // 基础处理
          _buildSectionHeader('基础处理'),
          _buildFeatureGrid(
            context,
            [
              _FeatureItem(
                title: '去水印',
                icon: Icons.auto_fix_high,
                color: const Color(0xFFFB7185),
                feature: ImageEditFeature.removeWatermark,
              ),
              _FeatureItem(
                title: '加水印',
                icon: Icons.water_drop,
                color: const Color(0xFF3B82F6),
                feature: ImageEditFeature.addWatermark,
                    ),
              _FeatureItem(
                title: '裁剪',
                icon: Icons.crop,
                color: const Color(0xFF10B981),
                feature: ImageEditFeature.crop,
              ),
              _FeatureItem(
                title: '旋转翻转',
                icon: Icons.rotate_right,
                color: const Color(0xFFF59E0B),
                feature: ImageEditFeature.rotate,
                    ),
                  ],
                ),
          const SizedBox(height: 24),
          // 色彩调整
          _buildSectionHeader('色彩调整'),
          _buildFeatureGrid(
            context,
            [
              _FeatureItem(
                title: '亮度对比度',
                icon: Icons.brightness_6,
                color: const Color(0xFF8B5CF6),
                feature: ImageEditFeature.adjust,
              ),
              _FeatureItem(
                title: '模糊',
                icon: Icons.blur_on,
                color: const Color(0xFFEC4899),
                feature: ImageEditFeature.blur,
              ),
              _FeatureItem(
                title: '马赛克',
                icon: Icons.grid_4x4,
                color: const Color(0xFF6366F1),
                feature: ImageEditFeature.mosaic,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 标注工具
          _buildSectionHeader('标注工具'),
          _buildFeatureGrid(
                                        context,
            [
              _FeatureItem(
                title: '画笔',
                icon: Icons.brush,
                color: const Color(0xFF14B8A6),
                feature: ImageEditFeature.brush,
                                    ),
              _FeatureItem(
                title: '添加文字',
                icon: Icons.text_fields,
                color: const Color(0xFF06B6D4),
                feature: ImageEditFeature.addText,
                                  ),
                                ],
                              ),
          const SizedBox(height: 24),
          // 其他功能
          _buildSectionHeader('其他功能'),
          _buildFeatureGrid(
                                          context,
            [
              _FeatureItem(
                title: '图片拼接',
                icon: Icons.view_compact,
                color: const Color(0xFFA78BFA),
                feature: ImageEditFeature.stitch,
              ),
              _FeatureItem(
                title: '图片压缩',
                icon: Icons.compress,
                color: const Color(0xFF22C55E),
                feature: ImageEditFeature.compress,
                                          ),
              _FeatureItem(
                title: '格式转换',
                icon: Icons.swap_horiz,
                color: const Color(0xFF84CC16),
                feature: ImageEditFeature.formatConvert,
              ),
              _FeatureItem(
                title: '去白边',
                icon: Icons.crop_free,
                color: const Color(0xFFF97316),
                feature: ImageEditFeature.trimEdges,
                                                ),
              _FeatureItem(
                title: '加边框',
                icon: Icons.border_style,
                color: const Color(0xFFA855F7),
                feature: ImageEditFeature.addBorder,
              ),
              _FeatureItem(
                title: '图片放大',
                icon: Icons.zoom_in,
                color: const Color(0xFFEF4444),
                feature: ImageEditFeature.enlarge,
                              ),
                            ],
                          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(
    BuildContext context,
    List<_FeatureItem> features,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _FeatureCard(
          feature: feature,
          onTap: () => _handleFeatureTap(context, feature.feature),
        );
      },
    );
  }

  void _handleFeatureTap(BuildContext context, ImageEditFeature feature) {
    switch (feature) {
      case ImageEditFeature.removeWatermark:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const RemoveWatermarkPage(),
          ),
        );
        break;
      case ImageEditFeature.addWatermark:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ImageWatermarkPage(),
          ),
        );
        break;
      case ImageEditFeature.crop:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ImageCropPage(),
          ),
        );
        break;
      case ImageEditFeature.rotate:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ImageAdjustPage(isRotate: true),
          ),
        );
        break;
      case ImageEditFeature.adjust:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ImageAdjustPage(),
          ),
        );
        break;
      case ImageEditFeature.blur:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ImageBlurPage(),
          ),
        );
        break;
      case ImageEditFeature.mosaic:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ImageMosaicPage(),
          ),
        );
        break;
      case ImageEditFeature.brush:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ImageBrushPage(),
          ),
        );
        break;
      case ImageEditFeature.addText:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ImageTextPage(),
          ),
        );
        break;
      case ImageEditFeature.stitch:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ImageStitchPage(),
          ),
        );
        break;
      case ImageEditFeature.compress:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ImageCompressPage(),
          ),
        );
        break;
      case ImageEditFeature.formatConvert:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('格式转换功能开发中...')),
        );
          break;
      case ImageEditFeature.trimEdges:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('去白边功能开发中...')),
        );
        break;
      case ImageEditFeature.addBorder:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加边框功能开发中...')),
        );
        break;
      case ImageEditFeature.enlarge:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('图片放大功能开发中...')),
        );
        break;
    }
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.feature,
  });

  final String title;
  final IconData icon;
  final Color color;
  final ImageEditFeature feature;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.feature,
    required this.onTap,
  });

  final _FeatureItem feature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
      decoration: BoxDecoration(
          color: feature.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: feature.color.withValues(alpha: 0.3),
            width: 1,
          ),
      ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              feature.icon,
              color: feature.color,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              feature.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
