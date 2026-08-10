import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import '../constants/app_colors.dart';

class ExportService {
  /// Generate CSV string for Orders list (with UTF-8 BOM for Excel)
  static String generateOrdersCsv(List<OrderModel> orders) {
    final StringBuffer buffer = StringBuffer();
    // UTF-8 BOM for Microsoft Excel auto-detect
    buffer.write('\uFEFF');
    // CSV Header
    buffer.writeln('Order ID,Customer Name,Phone,Email,Items Count,Subtotal (INR),Delivery Fee (INR),Discount (INR),Total (INR),Payment Method,Is Paid,Status,Created At');

    for (final o in orders) {
      final id = o.id;
      final name = _escapeCsv(o.userName);
      final phone = o.userPhone;
      final email = o.userEmail;
      final itemsCount = o.itemCount;
      final subtotal = o.subtotal.toStringAsFixed(2);
      final deliveryFee = o.deliveryFee.toStringAsFixed(2);
      final discount = o.discount.toStringAsFixed(2);
      final total = o.total.toStringAsFixed(2);
      final paymentMethod = _escapeCsv(o.paymentMethod);
      final isPaid = o.isPaid ? 'Yes' : 'No';
      final status = o.status.name;
      final createdAt = o.createdAt.toIso8601String();

      buffer.writeln('$id,$name,$phone,$email,$itemsCount,$subtotal,$deliveryFee,$discount,$total,$paymentMethod,$isPaid,$status,$createdAt');
    }

    return buffer.toString();
  }

  /// Generate CSV string for Products list (with UTF-8 BOM for Excel)
  static String generateProductsCsv(List<ProductModel> products) {
    final StringBuffer buffer = StringBuffer();
    buffer.write('\uFEFF');
    buffer.writeln('Product ID,Product Name,Category ID,Price (INR),Discount Price (INR),Stock Quantity,Unit,Is Active,Created At');

    for (final p in products) {
      final id = p.id;
      final name = _escapeCsv(p.name);
      final categoryId = p.categoryId;
      final price = p.price.toStringAsFixed(2);
      final discountPrice = p.discountPrice?.toStringAsFixed(2) ?? '';
      final stock = p.stockQuantity;
      final unit = p.unit;
      final isActive = p.isActive ? 'Active' : 'Inactive';
      final createdAt = p.createdAt.toIso8601String();

      buffer.writeln('$id,$name,$categoryId,$price,$discountPrice,$stock,$unit,$isActive,$createdAt');
    }

    return buffer.toString();
  }

  /// Generate CSV string for Users list (with UTF-8 BOM for Excel)
  static String generateUsersCsv(List<UserModel> users) {
    final StringBuffer buffer = StringBuffer();
    buffer.write('\uFEFF');
    buffer.writeln('User ID,Full Name,Email,Phone,Role,Is Active,Is Approved,Created At');

    for (final u in users) {
      final id = u.id;
      final name = _escapeCsv(u.name);
      final email = u.email;
      final phone = u.phone;
      final role = u.role.name;
      final isActive = u.isActive ? 'Yes' : 'No';
      final isApproved = u.isApproved ? 'Yes' : 'No';
      final createdAt = u.createdAt.toIso8601String();

      buffer.writeln('$id,$name,$email,$phone,$role,$isActive,$isApproved,$createdAt');
    }

    return buffer.toString();
  }

  /// Generate real binary PDF document bytes using official `pdf` package
  static Future<Uint8List> generatePdfBytes(String title, String csvContent) async {
    final pdf = pw.Document();
    // Clean BOM if present
    final cleanCsv = csvContent.replaceAll('\uFEFF', '').trim();
    final lines = cleanCsv.split('\n');
    if (lines.isEmpty) return Uint8List(0);

    final rawHeader = lines.first.split(',');
    final rawDataRows = lines.skip(1).map((line) => line.split(',')).toList();

    final sanitizedHeader = rawHeader.map((h) => _sanitizeForPdf(h)).toList();
    final sanitizedRows = rawDataRows
        .map((row) => row.map((cell) => _sanitizeForPdf(cell)).toList())
        .toList();

    final pdfTitle = _sanitizeForPdf(title);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('GROCERYGO PLATFORM', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                pw.Text('OFFICIAL EXPORT REPORT', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(pdfTitle, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.Text('Generated: ${_sanitizeForPdf(DateTime.now().toLocal().toString())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 1, color: PdfColors.green800),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('GroceryGo Multi-Vendor Platform - Auto Generated', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
        build: (context) => [
          if (sanitizedRows.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: sanitizedHeader,
              data: sanitizedRows,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellPadding: const pw.EdgeInsets.all(5),
            )
          else
            pw.Text('No data records available for this export report.', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );

    return pdf.save();
  }

  /// Show Export Dialog with options to download CSV or PDF document
  static void showExportDialog(BuildContext context, {
    required String title,
    required String csvContent,
    required String pdfSummaryTitle,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.download_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Text('Export $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Select export format to download official PDF document or Excel CSV file:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // CSV / Excel Export Option
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              tileColor: AppColors.grey100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              leading: const CircleAvatar(backgroundColor: Color(0xFF10B981), child: Icon(Icons.table_chart_rounded, color: Colors.white, size: 20)),
              title: const Text('Export as Excel / CSV (.csv)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Download .csv file & open directly in Excel or Google Sheets', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _downloadAndSaveFile(
                  context: context,
                  fileTitle: '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv',
                  textContent: csvContent,
                  typeLabel: 'CSV / Excel Spreadsheet',
                  isPdfFormat: false,
                  pdfTitle: title,
                );
              },
            ),
            const SizedBox(height: 12),

            // Official PDF Document Option
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              tileColor: AppColors.grey100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              leading: const CircleAvatar(backgroundColor: Color(0xFFEF4444), child: Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20)),
              title: const Text('Export as Official PDF (.pdf)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Generate & download styled PDF document with tables & headers', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _downloadAndSaveFile(
                  context: context,
                  fileTitle: '${title.replaceAll(' ', '_')}_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
                  textContent: csvContent,
                  typeLabel: 'Official PDF Document',
                  isPdfFormat: true,
                  pdfTitle: pdfSummaryTitle,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Future<void> _downloadAndSaveFile({
    required BuildContext context,
    required String fileTitle,
    required String textContent,
    required String typeLabel,
    required bool isPdfFormat,
    required String pdfTitle,
  }) async {
    File? createdFile;
    String savedPath = '';

    try {
      Directory? targetDir;

      // Try public Download folder on Android
      if (Platform.isAndroid) {
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (await publicDownload.exists()) {
          targetDir = publicDownload;
        }
      }

      if (targetDir == null) {
        try {
          targetDir = await getExternalStorageDirectory();
        } catch (_) {}
      }

      if (targetDir == null) {
        targetDir = await getApplicationDocumentsDirectory();
      }

      final file = File('${targetDir.path}/$fileTitle');

      if (isPdfFormat) {
        final pdfBytes = await generatePdfBytes(pdfTitle, textContent);
        await file.writeAsBytes(pdfBytes);
      } else {
        await file.writeAsBytes(utf8.encode(textContent));
      }

      createdFile = file;
      savedPath = file.path;
    } catch (_) {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final file = File('${docsDir.path}/$fileTitle');
        if (isPdfFormat) {
          final pdfBytes = await generatePdfBytes(pdfTitle, textContent);
          await file.writeAsBytes(pdfBytes);
        } else {
          await file.writeAsBytes(utf8.encode(textContent));
        }
        createdFile = file;
        savedPath = file.path;
      } catch (e) {
        savedPath = 'Copied to Clipboard';
      }
    }

    // Always copy CSV content to Clipboard
    await Clipboard.setData(ClipboardData(text: textContent));

    // Automatically trigger system share/save sheet so user can open in Excel, PDF Viewer, or save to any directory
    if (createdFile != null && await createdFile.exists()) {
      try {
        await Share.shareXFiles(
          [XFile(createdFile.path, name: fileTitle)],
          text: 'GroceryGo Platform - Exported $typeLabel',
        );
      } catch (_) {}
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(isPdfFormat ? 'PDF Ready & Downloaded!' : 'CSV Ready & Downloaded!',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$typeLabel has been generated. Use the button below to open in Excel, view PDF, or save to any folder on your device.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 14),
              const Text('File Saved Location:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
                child: SelectableText(
                  savedPath,
                  style: const TextStyle(color: Color(0xFF38BDF8), fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
          actions: [
            if (createdFile != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Share.shareXFiles(
                    [XFile(createdFile!.path, name: fileTitle)],
                    text: 'GroceryGo Platform - $typeLabel',
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open / Save File'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  static String _sanitizeForPdf(String text) {
    return text
        .replaceAll('₹', 'INR ')
        .replaceAll('·', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('’', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '');
  }

  static String _escapeCsv(String input) {
    if (input.contains(',') || input.contains('"') || input.contains('\n')) {
      return '"${input.replaceAll('"', '""')}"';
    }
    return input;
  }
}

