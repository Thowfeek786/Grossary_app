import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:models/models.dart';
import 'package:core/core.dart';

class InvoiceGenerator {
  static Future<void> generateAndDownload(OrderModel order) async {
    final pdf = pw.Document();
    final emeraldDark = PdfColor.fromHex('#047857');
    final emeraldPrimary = PdfColor.fromHex('#059669');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'GroceryGo',
                          style: pw.TextStyle(
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                            color: emeraldDark,
                          ),
                        ),
                        pw.Text(
                          'Fresh Groceries Delivered',
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.Text(
                          'Order #${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length).toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: emeraldPrimary,
                          ),
                        ),
                        pw.Text(
                          'Date: ${AppHelpers.formatDateTime(order.createdAt)}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 14),

                // Customer & Delivery Address details
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Billed & Delivered To:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                              color: PdfColors.grey800,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            order.deliveryAddress.fullName,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          pw.Text(
                            order.deliveryAddress.phone,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            order.deliveryAddress.fullAddress,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Payment Details:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                              color: PdfColors.grey800,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Method: ${order.paymentMethod.toUpperCase()}',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            'Status: ${order.statusString.toUpperCase()}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: emeraldDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Itemized Table
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                  headerDecoration: pw.BoxDecoration(color: emeraldDark),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  headers: ['#', 'Item Description', 'Qty', 'Unit Price', 'Total Price'],
                  data: List.generate(order.items.length, (index) {
                    final item = order.items[index];
                    return [
                      '${index + 1}',
                      item.productName,
                      '${item.quantity} ${item.unit}',
                      'INR ${item.price.toStringAsFixed(2)}',
                      'INR ${item.totalPrice.toStringAsFixed(2)}',
                    ];
                  }),
                ),
                pw.SizedBox(height: 16),

                // Subtotal, Delivery Fee & Grand Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 220,
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                              pw.Text('INR ${order.subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Delivery Fee:', style: const pw.TextStyle(fontSize: 10)),
                              pw.Text('INR ${order.deliveryFee.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                          if (order.discount > 0) ...[
                            pw.SizedBox(height: 4),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Discount:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.green700)),
                                pw.Text('- INR ${order.discount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.green700)),
                              ],
                            ),
                          ],
                          pw.Divider(color: PdfColors.grey400),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Grand Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                              pw.Text(
                                'INR ${order.total.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                  color: emeraldDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Thank you for shopping with GroceryGo! For support, email support@grocerygo.com',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}.pdf',
    );
  }
}
