import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/event_record.dart';
import '../models/event.dart';
import '../providers/event_record_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/camera_permission_service.dart';
import '../services/image_storage_service.dart';

class AddRecordPage extends ConsumerStatefulWidget {
  const AddRecordPage({
    super.key,
    required this.eventId,
    this.record, // 如果提供，则是编辑模式
    this.event, // 事件信息，用于获取主题色
  });

  final String eventId;
  final EventRecord? record;
  final Event? event;

  @override
  ConsumerState<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends ConsumerState<AddRecordPage> {
  final _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<String> _imagePaths = [];
  List<bool> _isFromCamera = []; // 跟踪每张图片是否来自相机
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _textController.text = widget.record!.textContent ?? '';
      _imagePaths = List.from(widget.record!.imagePaths);
      // 编辑模式下，假设所有图片都不是新拍摄的，创建可变长度列表
      _isFromCamera = List.generate(_imagePaths.length, (index) => false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.record != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEditing ? l10n.editRecord : l10n.addRecord,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: SizedBox(
            width: 100,
            child: TextButton(
              onPressed: () => _handleBackPress(l10n),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
                minimumSize: const Size(100, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                splashFactory: NoSplash.splashFactory,
                overlayColor: Colors.transparent,
              ),
              child: Text(
                l10n.cancel,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _saveRecord(l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                minimumSize: const Size(0, 32),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isEditing ? l10n.save : l10n.add,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: l10n.recordContentHint,
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 20),

            // 照片网格
            LayoutBuilder(
              builder: (context, constraints) {
                final itemSize = (constraints.maxWidth - 16) / 3; // 3列布局，减去间距
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // 显示已上传的图片
                    ..._imagePaths.asMap().entries.map((entry) {
                      final index = entry.key;
                      return SizedBox(
                        width: itemSize,
                        height: itemSize,
                        child: _buildPhotoPreview(index),
                      );
                    }),
                    // 如果图片少于9张，显示添加按钮
                    if (_imagePaths.length < 9)
                      SizedBox(
                        width: itemSize,
                        height: itemSize,
                        child: _buildAddPhotoButton(l10n),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotoButton(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => _addPhoto(l10n),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.grey, size: 32),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(_imagePaths[index]),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // 图片丢失时，只显示破损图标，不提供预览功能
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        ),
        // 删除按钮始终显示，即使图片丢失也可以删除
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
        // 图片正常时显示预览按钮
        if (_imageExists(_imagePaths[index]))
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _showImagePreview(index),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _addPhoto(AppLocalizations l10n) async {
    // 显示选择来源的对话框
    _showImageSourceDialog(l10n);
  }

  /// 显示图片来源选择对话框
  void _showImageSourceDialog(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(l10n.takePhoto),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera(l10n);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.selectFromGallery),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery(l10n);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(l10n.cancel),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 从相机拍照
  Future<void> _pickImageFromCamera(AppLocalizations l10n) async {
    try {
      // 检查相机权限
      final hasPermission = await CameraPermissionService.instance
          .hasCameraPermission();

      if (!hasPermission) {
        // 请求相机权限
        final permissionStatus = await CameraPermissionService.instance
            .requestCameraPermission();

        if (!permissionStatus.isGranted) {
          if (permissionStatus.isPermanentlyDenied) {
            // 权限被永久拒绝，显示设置对话框
            _showPermissionDeniedDialog(l10n);
            return;
          } else {
            // 权限被拒绝，显示提示
            _showErrorSnackBar(l10n.cameraPermissionRequired);
            return;
          }
        }
      }

      // 显示加载状态
      setState(() {
        _isLoading = true;
      });

      // 添加超时处理
      final XFile? image = await _imagePicker
          .pickImage(source: ImageSource.camera, imageQuality: 80)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(l10n.cameraTimeout);
            },
          );

      if (image != null) {
        setState(() {
          _imagePaths.add(image.path);
          _isFromCamera.add(true); // 标记为来自相机
        });
      }
    } catch (e) {
      String errorMessage = l10n.photoFailed(e.toString());
      if (e.toString().contains('timeout')) {
        errorMessage = l10n.cameraTimeout;
      } else if (e.toString().contains('permission')) {
        errorMessage = l10n.cameraPermissionRequired;
      } else if (e.toString().contains('camera')) {
        errorMessage = l10n.cameraNotAvailable;
      }

      _showErrorSnackBar(errorMessage);
    } finally {
      // 确保加载状态被重置
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 从相册选择图片
  Future<void> _pickImageFromGallery(AppLocalizations l10n) async {
    try {
      // 检查相册权限
      final hasPermission = await Permission.photos.status.isGranted;

      if (!hasPermission) {
        // 请求相册权限
        final permissionStatus = await Permission.photos.request();

        if (!permissionStatus.isGranted) {
          if (permissionStatus.isPermanentlyDenied) {
            // 权限被永久拒绝，显示设置对话框
            _showPermissionDeniedDialog(l10n);
            return;
          } else {
            // 权限被拒绝，显示提示
            _showErrorSnackBar(l10n.photoPermissionRequired);
            return;
          }
        }
      }

      // 显示加载状态
      setState(() {
        _isLoading = true;
      });

      // 添加超时处理
      final XFile? image = await _imagePicker
          .pickImage(source: ImageSource.gallery, imageQuality: 80)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(l10n.photoTimeout);
            },
          );

      if (image != null) {
        setState(() {
          _imagePaths.add(image.path);
          _isFromCamera.add(false); // 标记为来自相册
        });
      }
    } catch (e) {
      String errorMessage = l10n.selectPhotoFailed(e.toString());
      if (e.toString().contains('timeout')) {
        errorMessage = l10n.photoTimeout;
      } else if (e.toString().contains('permission')) {
        errorMessage = l10n.photoPermissionRequired;
      }

      _showErrorSnackBar(errorMessage);
    } finally {
      // 确保加载状态被重置
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _imagePaths.removeAt(index);
      _isFromCamera.removeAt(index);
    });
  }

  /// 检查图片文件是否存在
  bool _imageExists(String imagePath) {
    try {
      final file = File(imagePath);
      return file.existsSync();
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveRecord(AppLocalizations l10n) async {
    if (_textController.text.trim().isEmpty && _imagePaths.isEmpty) {
      _showErrorSnackBar(l10n.pleaseAddContent);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final record =
          widget.record ??
          EventRecord(
            id: const Uuid().v4(),
            eventId: widget.eventId,
            type: RecordType.text,
            createdAt: now,
          );

      // 处理图片路径 - 根据图片来源选择不同的存储方法
      List<String> permanentImagePaths = [];
      if (_imagePaths.isNotEmpty) {
        try {
          // 分别处理来自相机和相册的图片
          List<String> cameraImages = [];
          List<String> galleryImages = [];

          for (int i = 0; i < _imagePaths.length; i++) {
            if (_isFromCamera[i]) {
              cameraImages.add(_imagePaths[i]);
            } else {
              galleryImages.add(_imagePaths[i]);
            }
          }

          // 处理来自相机的图片（需要保存到相册）
          if (cameraImages.isNotEmpty) {
            final cameraPaths = await ImageStorageService()
                .copyImagesToPermanentStorageAndGallery(cameraImages);
            permanentImagePaths.addAll(cameraPaths);
          }

          // 处理来自相册的图片（只复制到应用目录，不保存到相册）
          if (galleryImages.isNotEmpty) {
            final galleryPaths = await ImageStorageService()
                .copyImagesToPermanentStorage(galleryImages);
            permanentImagePaths.addAll(galleryPaths);
          }
        } catch (e) {
          _showErrorSnackBar(l10n.saveImageFailed(e.toString()));
          return;
        }
      }

      // 更新记录内容
      record.updateRecord(
        textContent: _textController.text.trim().isEmpty
            ? null
            : _textController.text.trim(),
        imagePaths: permanentImagePaths,
        location: null,
      );

      // 确定记录类型
      if (record.hasText && record.hasImages) {
        record.type = RecordType.mixed;
      } else if (record.hasImages) {
        record.type = RecordType.photo;
      } else {
        record.type = RecordType.text;
      }

      // 保存记录
      if (widget.record != null) {
        await ref.read(eventRecordsProvider.notifier).updateRecord(record);
      } else {
        await ref.read(eventRecordsProvider.notifier).addRecord(record);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        // _showSuccessSnackBar(widget.record != null ? l10n.recordUpdated : l10n.recordAdded);
      }
    } catch (e) {
      _showErrorSnackBar(l10n.saveFailed(e.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// 处理返回按钮点击
  void _handleBackPress(AppLocalizations l10n) {
    // 检查是否有内容
    final hasContent =
        _textController.text.trim().isNotEmpty || _imagePaths.isNotEmpty;

    if (hasContent) {
      // 有内容时显示确认对话框
      _showExitConfirmationDialog(l10n);
    } else {
      // 没有内容直接返回
      Navigator.of(context).pop();
    }
  }

  /// 显示退出确认对话框
  void _showExitConfirmationDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.confirmLeave),
          content: Text(l10n.confirmLeaveDesc),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // 关闭对话框
                  child: Text(l10n.continueEditing),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 关闭对话框
                    Navigator.of(context).pop(); // 返回上一页
                  },
                  child: Text(
                    l10n.confirmLeaveAction,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// 显示权限被拒绝的对话框
  void _showPermissionDeniedDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.permissionRequired),
          content: Text(l10n.permissionRequiredDesc),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: Text(l10n.goToSettings),
            ),
          ],
        );
      },
    );
  }

  /// 显示图片预览
  void _showImagePreview(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImagePreviewPage(
          imagePaths: _imagePaths,
          initialIndex: index,
          onDelete: (int deleteIndex) {
            setState(() {
              _imagePaths.removeAt(deleteIndex);
              _isFromCamera.removeAt(deleteIndex);
            });
          },
        ),
      ),
    );
  }

  // void _showSuccessSnackBar(String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text(message), backgroundColor: Colors.green),
  //   );
  // }
}

/// 图片预览页面
class _ImagePreviewPage extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final Function(int) onDelete;

  const _ImagePreviewPage({
    required this.imagePaths,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<_ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<_ImagePreviewPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.imagePaths.length}'),
        actions: [
          IconButton(
            onPressed: () => _showDeleteDialog(),
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.imagePaths.length,
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.file(
                File(widget.imagePaths[index]),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 100,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.deleteImage),
          content: Text(l10n.deleteImageConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDelete(_currentIndex);
                Navigator.of(context).pop();
              },
              child: Text(
                l10n.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
