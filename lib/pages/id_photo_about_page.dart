import 'package:flutter/material.dart';

/// 关于页面
class IdPhotoAboutPage extends StatelessWidget {
  const IdPhotoAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Logo和版本
          Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '证件照生成器',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '版本 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // 应用介绍
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '应用介绍',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '证件照生成器是一款专业的证件照处理应用，支持多种尺寸模板、背景替换、图像调节等功能。所有处理均在本地完成，保护您的隐私安全。',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 功能特性
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('多种尺寸模板'),
                  subtitle: Text('支持中国、美国、日本等国家证件照尺寸'),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('背景替换'),
                  subtitle: Text('支持白色、蓝色、红色等多种背景颜色'),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('图像调节'),
                  subtitle: Text('支持亮度、对比度、饱和度等参数调节'),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('打印排版'),
                  subtitle: Text('自动生成4x6英寸打印排版，支持PDF导出'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 隐私政策
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.security, color: Colors.blue),
                  title: Text('隐私政策'),
                  subtitle: Text('所有图片处理均在本地完成，不上传服务器'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.orange),
                  title: const Text('自动删除'),
                  subtitle: const Text('电子照会在7天后自动删除'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 版权信息
          Center(
            child: Text(
              '© 2024 证件照生成器\nAll rights reserved',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
