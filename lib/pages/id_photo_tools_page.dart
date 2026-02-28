import 'package:flutter/material.dart';
import 'id_photo_change_background_page.dart';
import 'id_photo_edit_page.dart';
import 'id_photo_custom_size_page.dart';
import 'id_photo_format_convert_page.dart';

/// 小工具页面
class IdPhotoToolsPage extends StatelessWidget {
  const IdPhotoToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('实用工具'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildToolItem(
            context,
            icon: Icons.color_lens,
            iconColor: Colors.blue,
            title: '证件照更换底色',
            subtitle: '已有证件照更换底色',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const IdPhotoChangeBackgroundPage(),
                ),
              );
            },
          ),
          _buildToolItem(
            context,
            icon: Icons.aspect_ratio,
            iconColor: Colors.lightBlue,
            title: '自定义尺寸',
            subtitle: '自定义输入尺寸大小背景色制作证件照',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const IdPhotoCustomSizePage(),
                ),
              );
            },
          ),
          _buildToolItem(
            context,
            icon: Icons.high_quality,
            iconColor: Colors.pink,
            title: '人像高清',
            subtitle: '对模糊图片人像进行清晰度修复增强',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('人像高清功能需要AI支持，暂未实现'),
                ),
              );
            },
          ),
          _buildToolItem(
            context,
            icon: Icons.edit,
            iconColor: Colors.orange,
            title: '图片编辑',
            subtitle: '更改图片大小(kb),分辨率大小(dpi)',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const IdPhotoEditPage(),
                ),
              );
            },
          ),
          _buildToolItem(
            context,
            icon: Icons.swap_horiz,
            iconColor: Colors.lightBlue,
            title: '图片格式转换',
            subtitle: '对不同格式的图片类型进行转换',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const IdPhotoFormatConvertPage(),
                ),
              );
            },
          ),
          _buildToolItem(
            context,
            icon: Icons.format_color_fill,
            iconColor: Colors.red,
            title: '黑白图片上色',
            subtitle: '上传黑白图片立即获取彩色图片',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('黑白上色功能需要AI支持，暂未实现'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
