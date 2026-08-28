import 'package:flutter/material.dart';

class CanQrScannerDialog extends StatefulWidget {
  final String title;
  final String prompt;
  final Function(String serialId) onScanned;

  const CanQrScannerDialog({
    super.key,
    this.title = 'Scan Water Can QR Code',
    this.prompt = 'Scan the 2D DataMatrix/QR code on the neck of the water can',
    required this.onScanned,
  });

  static Future<String?> show(
    BuildContext context, {
    String title = 'Scan Water Can QR Code',
    String prompt = 'Scan the QR code on the water can container',
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => CanQrScannerDialog(
        title: title,
        prompt: prompt,
        onScanned: (serial) => Navigator.pop(ctx, serial),
      ),
    );
  }

  @override
  State<CanQrScannerDialog> createState() => _CanQrScannerDialogState();
}

class _CanQrScannerDialogState extends State<CanQrScannerDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _serialCtrl = TextEditingController();
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _serialCtrl.dispose();
    super.dispose();
  }

  void _submitSerial(String val) {
    final cleaned = val.trim().toUpperCase();
    if (cleaned.isNotEmpty) {
      widget.onScanned(cleaned);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF059669), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),

            // Visual Scanning Reticle Box
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF059669), width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.qr_code_2_rounded, color: Colors.white24, size: 100),
                  AnimatedBuilder(
                    animation: _animCtrl,
                    builder: (context, child) {
                      return Positioned(
                        top: 20 + (_animCtrl.value * 140),
                        left: 20,
                        right: 20,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            const Text(
              'Or enter Serial ID manually:',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _serialCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. CAN-GG-20L-10928',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.tag_rounded, size: 18, color: Color(0xFF64748B)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: _submitSerial,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          onPressed: () => _submitSerial(_serialCtrl.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Verify & Confirm', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
