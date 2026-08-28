import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:ui_kit/ui_kit.dart';

class JoinStoreFleetDialog extends StatefulWidget {
  final UserModel user;

  const JoinStoreFleetDialog({super.key, required this.user});

  static Future<DealerDriverModel?> show(BuildContext context, UserModel user) {
    return showModalBottomSheet<DealerDriverModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JoinStoreFleetDialog(user: user),
    );
  }

  @override
  State<JoinStoreFleetDialog> createState() => _JoinStoreFleetDialogState();
}

class _JoinStoreFleetDialogState extends State<JoinStoreFleetDialog> {
  final TextEditingController _codeCtrl = TextEditingController();
  final DealerFleetRepository _fleetRepo = DealerFleetRepository();
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitCode([String? manualCode]) async {
    final code = (manualCode ?? _codeCtrl.text).trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorMsg = 'Please enter a store invite code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final driverModel = await _fleetRepo.joinFleetWithInviteCode(
        inviteCode: code,
        driver: widget.user,
      );

      HapticFeedback.heavyImpact();
      if (mounted) {
        Navigator.pop(context, driverModel);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Successfully joined ${driverModel.dealerName}\'s delivery fleet!'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  Future<void> _scanQrCode() async {
    final scanned = await CanQrScannerDialog.show(
      context,
      title: 'Scan Store QR Code',
      prompt: 'Align the dark store invite QR code inside the camera viewfinder',
    );

    if (scanned != null && scanned.isNotEmpty) {
      _codeCtrl.text = scanned.toUpperCase();
      await _submitCode(scanned);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 18, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join Dark Store Fleet',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Enter your dealer\'s invite code to get dedicated runs',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Code Input Field with 1-Tap Camera Scanner
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                labelText: 'Store Invite Code *',
                hintText: 'e.g. STORE-QJJJP',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, letterSpacing: 0),
                prefixIcon: const Icon(Icons.vpn_key_rounded, color: Color(0xFF059669), size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF059669), size: 22),
                  tooltip: 'Scan Store QR with Camera',
                  onPressed: _scanQrCode,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF059669), width: 2)),
              ),
              onSubmitted: (_) => _submitCode(),
            ),

            if (_errorMsg != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Benefits highlight
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dedicated partners receive daily morning water drops (5:30 AM) and direct store pickup orders.',
                      style: TextStyle(color: Color(0xFF065F46), fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _submitCode(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Verify & Join Fleet ✓',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
