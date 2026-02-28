import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/id_photo_template.dart';
import 'image_service.dart';

/// PDF 生成服务
class PdfService {
  /// 生成打印排版 PDF
  ///
  /// [images] 图片数据列表
  /// [template] 尺寸模板
  /// [paperSize] 纸张尺寸（英寸）：'4x6' 或 '6x4'
  /// [dpi] 打印分辨率
  static Future<String> generatePrintLayout({
    required List<Uint8List> images,
    required IdPhotoTemplate template,
    String paperSize = '4x6',
    int dpi = 300,
  }) async {
    final pdf = pw.Document();

    // 纸张尺寸（英寸转点，1 inch = 72 points）
    PdfPageFormat pageFormat;
    if (paperSize == '4x6') {
      pageFormat = PdfPageFormat(6 * 72, 4 * 72); // 6" x 4"
    } else {
      pageFormat = PdfPageFormat(4 * 72, 6 * 72); // 4" x 6"
    }

    // 计算每张图片在纸张上的尺寸（英寸转点）
    final imageWidthInches = template.widthMm / 25.4;
    final imageHeightInches = template.heightMm / 25.4;
    final imageWidthPoints = imageWidthInches * 72;
    final imageHeightPoints = imageHeightInches * 72;

    // 计算可以排列多少张
    final cols = (pageFormat.width / imageWidthPoints).floor();
    final rows = (pageFormat.height / imageHeightPoints).floor();
    final imagesPerPage = cols * rows;

    int imageIndex = 0;
    while (imageIndex < images.length) {
      final pageImages = <pw.Widget>[];

      for (int row = 0; row < rows && imageIndex < images.length; row++) {
        final rowImages = <pw.Widget>[];
        for (int col = 0; col < cols && imageIndex < images.length; col++) {
          final image = pw.MemoryImage(images[imageIndex]);
          rowImages.add(
            pw.Container(
              width: imageWidthPoints,
              height: imageHeightPoints,
              child: pw.Image(image, fit: pw.BoxFit.cover),
            ),
          );
          imageIndex++;
        }
        pageImages.add(
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: rowImages,
          ),
        );
      }

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: pageImages,
            );
          },
        ),
      );
    }

    // 保存 PDF
    final appDir = await getApplicationDocumentsDirectory();
    final filename = 'id_photo_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path.join(appDir.path, filename));
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// 生成单张证件照 PDF
  static Future<String> generateSinglePhoto({
    required Uint8List image,
    required IdPhotoTemplate template,
  }) async {
    final pdf = pw.Document();

    // 图片尺寸（毫米转点）
    final imageWidthPoints = (template.widthMm / 25.4) * 72;
    final imageHeightPoints = (template.heightMm / 25.4) * 72;

    // 创建 A4 页面
    final pageFormat = PdfPageFormat.a4;
    final pageWidth = pageFormat.width;
    final pageHeight = pageFormat.height;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(72), // 1 inch margin
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              width: imageWidthPoints,
              height: imageHeightPoints,
              child: pw.Image(pw.MemoryImage(image), fit: pw.BoxFit.cover),
            ),
          );
        },
      ),
    );

    // 保存 PDF
    final appDir = await getApplicationDocumentsDirectory();
    final filename =
        'id_photo_single_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path.join(appDir.path, filename));
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }
}
