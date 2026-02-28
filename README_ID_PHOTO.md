# 证件照处理 App

一个专业的证件照处理应用，支持背景替换、尺寸模板、打印排版等功能。

## 功能特性

### ✅ 已实现功能

1. **图片获取**
   - 相机拍照
   - 相册选择
   - EXIF 方向自动修正
   - 图片压缩

2. **裁剪功能**
   - 固定比例裁剪（根据模板）
   - 自定义尺寸（mm 转 px）
   - 辅助线显示

3. **背景替换**
   - 基于颜色阈值替换
   - 可调节容差参数
   - 支持白色/蓝色/红色/自定义颜色
   - 手动擦除模式（预留）

4. **图像调节**
   - 亮度调节
   - 对比度调节
   - 饱和度调节
   - 锐化
   - 降噪

5. **尺寸模板**
   - 中国一寸/二寸/小一寸/大一寸
   - 美国护照
   - 日本在留卡/护照
   - 欧洲签证
   - 自定义尺寸（预留）

6. **打印排版**
   - 4x6 英寸排版
   - PDF 生成
   - 自动计算张数

7. **导出功能**
   - JPG 导出
   - PNG 导出
   - PDF 导出
   - 保存到相册
   - 分享功能

8. **历史管理**
   - 本地数据库存储（Hive）
   - 查看历史记录
   - 删除记录
   - 重新编辑（预留）

9. **设置**
   - 主题切换（浅色/深色/跟随系统）

## 项目结构

```
lib/
├── models/              # 数据模型
│   ├── id_photo_template.dart    # 尺寸模板模型
│   ├── id_photo_record.dart       # 证件照记录模型
│   └── edit_params.dart          # 编辑参数模型
├── services/           # 服务层
│   ├── image_service.dart        # 图片处理服务
│   ├── database_service.dart     # 数据库服务
│   ├── template_service.dart     # 模板服务
│   ├── pdf_service.dart          # PDF 生成服务
│   └── print_layout_service.dart # 打印排版服务
├── providers/          # 状态管理
│   ├── id_photo_provider.dart    # 证件照 Provider
│   └── theme_provider.dart       # 主题 Provider
├── pages/              # 页面
│   ├── id_photo_home_page.dart        # 首页
│   ├── id_photo_crop_page.dart       # 裁剪页面
│   ├── id_photo_background_page.dart  # 背景替换页面
│   ├── id_photo_adjust_page.dart      # 图像调节页面
│   ├── id_photo_export_page.dart      # 导出页面
│   ├── id_photo_template_page.dart     # 模板选择页面
│   ├── id_photo_history_page.dart      # 历史记录页面
│   └── id_photo_settings_page.dart     # 设置页面
└── main.dart           # 应用入口
```

## 技术栈

- **Flutter** - 跨平台框架
- **Riverpod** - 状态管理
- **Hive** - 本地数据库
- **image** - 图片处理
- **pdf** - PDF 生成
- **camera** - 相机功能
- **image_picker** - 图片选择

## 安装和运行

1. 安装依赖：
```bash
flutter pub get
```

2. 生成代码（Hive 适配器）：
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. 运行应用：
```bash
flutter run
```

## 使用流程

1. **新建证件照**
   - 点击首页的"新建证件照"按钮
   - 选择拍照或从相册选择

2. **选择尺寸模板**
   - 在裁剪页面选择证件照尺寸
   - 或从模板页面选择

3. **裁剪图片**
   - 调整裁剪区域
   - 点击"下一步：背景替换"

4. **替换背景**
   - 选择背景颜色（白色/蓝色/红色/自定义）
   - 调节容差参数
   - 点击"下一步：图像调节"

5. **图像调节**
   - 调节亮度、对比度、饱和度等
   - 点击"完成并导出"

6. **导出**
   - 保存到相册
   - 导出 PDF
   - 分享
   - 保存到历史记录

## 隐私说明

- ✅ 所有图片处理均在本地完成
- ✅ 不上传服务器
- ✅ 不收集用户照片
- ✅ 完全离线工作

## 待实现功能

- [ ] 多语言支持（中英文）
- [ ] 付费功能集成（in_app_purchase）
- [ ] 手动擦除模式（橡皮擦 + 放大镜）
- [ ] 自定义尺寸模板
- [ ] 重新编辑历史记录
- [ ] 相机页面优化

## 许可证

本项目仅供学习和商业使用。
