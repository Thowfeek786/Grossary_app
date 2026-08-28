import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CanQrScannerDialog extends StatefulWidget {
  final String title;
  final String prompt;
  final Function(String serialId) onScanned;

  const CanQrScannerDialog({
    super.key,
    this.title = 'Scan Water Can QR Code',
    this.prompt = 'Align the 2D QR / Barcode inside the viewfinder',
    required this.onScanned,
  });

  static Future<String?> show(
    BuildContext context, {
    String title = 'Scan Water Can QR Code',
    String prompt = 'Align the QR code or Barcode inside the viewfinder',
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
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
  final MobileScannerController _scannerCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  late AnimationController _animCtrl;
  bool _isTorchOn = false;
  bool _hasDetected = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _serialCtrl.dispose();
    _scannerCtrl.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasDetected) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.trim().isNotEmpty) {
        _hasDetected = true;
        HapticFeedback.heavyImpact();
        widget.onScanned(code.trim().toUpperCase());
        break;
      }
    }
  }

  void _submitManualSerial(String val) {
    final cleaned = val.trim().toUpperCase();
    if (cleaned.isNotEmpty) {
      HapticFeedback.selectionClick();
      widget.onScanned(cleaned);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF059669), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
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
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),

            // ─────────────────────────────────────────────
            // 📷 Live Camera Scanner Viewfinder Box
            // ─────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 240,
                height: 240,
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Live Camera Stream
                    MobileScanner(
                      controller: _scannerCtrl,
                      onDetect: _onBarcodeDetected,
                      errorBuilder: (context, error) {
                        return Container(
                          color: const Color(0xFF0F172A),
                          padding: const EdgeInsets.all(16),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 36),
                              SizedBox(height: 8),
                              Text(
                                'Camera Unavailable\nPlease use manual input below',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Viewfinder Reticle Framing Borders
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white38, width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    // Laser Scan Line Animation
                    AnimatedBuilder(
                      animation: _animCtrl,
                      builder: (context, child) {
                        return Positioned(
                          top: 25 + (_animCtrl.value * 190),
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.9),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Camera Controls Overlay (Flash / Torch & Camera Switch)
                    Positioned(
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                color: _isTorchOn ? const Color(0xFFFACC15) : Colors.white70,
                              ),
                              onPressed: () async {
                                await _scannerCtrl.toggleTorch();
                                setState(() => _isTorchOn = !_isTorchOn);
                              },
                            ),
                            const SizedBox(width: 14),
                            IconButton(
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white70),
                              onPressed: () => _scannerCtrl.switchCamera(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─────────────────────────────────────────────
            // ⌨️ Manual Serial ID Input Fallback
            // ─────────────────────────────────────────────
            const Text(
              'Or enter Serial / Barcode manually:',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _serialCtrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. CAN-GG-20L-10928',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.tag_rounded, size: 18, color: Color(0xFF059669)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
              onSubmitted: _submitManualSerial,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
        ),
        ElevatedButton(
          onPressed: () => _submitManualSerial(_serialCtrl.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Verify ✓', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
