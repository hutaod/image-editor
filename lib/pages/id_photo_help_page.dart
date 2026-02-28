import 'package:flutter/material.dart';

/// 帮助与反馈页面
class IdPhotoHelpPage extends StatelessWidget {
  const IdPhotoHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('帮助与反馈'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: '常见问题',
            children: [
              _buildQuestion(
                '如何制作证件照？',
                '1. 点击首页的"一寸照"或选择其他尺寸\n'
                '2. 选择拍照或从相册选择照片\n'
                '3. 裁剪照片到合适位置\n'
                '4. 选择背景颜色\n'
                '5. 调整图像参数（可选）\n'
                '6. 保存或导出',
              ),
              _buildQuestion(
                '如何更换已有照片的底色？',
                '1. 点击首页的"修改底色"功能\n'
                '2. 从相册选择已有证件照\n'
                '3. 选择新的背景颜色\n'
                '4. 调整容差参数以获得最佳效果\n'
                '5. 保存',
              ),
              _buildQuestion(
                '如何自定义尺寸？',
                '1. 进入"小工具"页面\n'
                '2. 选择"自定义尺寸"\n'
                '3. 输入宽度、高度（mm）和DPI\n'
                '4. 选择背景颜色\n'
                '5. 生成并保存',
              ),
              _buildQuestion(
                '照片会自动删除吗？',
                '是的，为了您的隐私安全，所有保存的电子照会在7天后自动删除。请及时提取您需要的照片。',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: '隐私说明',
            children: [
              const ListTile(
                leading: Icon(Icons.security, color: Colors.green),
                title: Text('本地处理'),
                subtitle: Text('所有图片处理均在您的设备本地完成'),
              ),
              const ListTile(
                leading: Icon(Icons.cloud_off, color: Colors.green),
                title: Text('不上传服务器'),
                subtitle: Text('您的照片不会上传到任何服务器'),
              ),
              const ListTile(
                leading: Icon(Icons.no_photography, color: Colors.green),
                title: Text('不收集照片'),
                subtitle: Text('我们不会收集或存储您的任何照片'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: '反馈',
            children: [
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('意见反馈'),
                subtitle: const Text('如有问题或建议，欢迎联系我们'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请通过应用商店联系我们'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildQuestion(String question, String answer) {
    return ExpansionTile(
      title: Text(question),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
