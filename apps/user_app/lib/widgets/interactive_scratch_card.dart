import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:repository/repository.dart';

class ScratchCardResult {
  final bool isWinner;
  final double amount;
  final bool isClaimed;

  const ScratchCardResult({
    required this.isWinner,
    required this.amount,
    required this.isClaimed,
  });
}

class InteractiveScratchCardDialog extends StatefulWidget {
  final String userId;
  final String orderId;
  final Function(ScratchCardResult result)? onResult;

  const InteractiveScratchCardDialog({
    super.key,
    required this.userId,
    required this.orderId,
    this.onResult,
  });

  static Future<ScratchCardResult?> show(
    BuildContext context, {
    required String userId,
    required String orderId,
    Function(ScratchCardResult result)? onResult,
  }) {
    return showDialog<ScratchCardResult>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: InteractiveScratchCardDialog(
          userId: userId,
          orderId: orderId,
          onResult: onResult,
        ),
      ),
    );
  }

  @override
  State<InteractiveScratchCardDialog> createState() => _InteractiveScratchCardDialogState();
}

class _InteractiveScratchCardDialogState extends State<InteractiveScratchCardDialog> with SingleTickerProviderStateMixin {
  final List<Offset?> _scratchPoints = [];
  bool _isRevealed = false;
  bool _isClaiming = false;
  bool _isClaimed = false;

  late bool _isWinner;
  late double _cashbackAmount;
  late AnimationController _revealAnimCtrl;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // 25% chance to win, 75% chance of Better Luck Next Time
    final random = math.Random();
    _isWinner = random.nextInt(100) < 25;
    _cashbackAmount = _isWinner
        ? const [10.0, 15.0, 20.0, 25.0][random.nextInt(4)]
        : 0.0;

    _revealAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _revealAnimCtrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _revealAnimCtrl.dispose();
    super.dispose();
  }

  void _notifyResult() {
    widget.onResult?.call(
      ScratchCardResult(
        isWinner: _isWinner,
        amount: _cashbackAmount,
        isClaimed: _isClaimed,
      ),
    );
  }

  void _onScratch(Offset localPos) {
    if (_isRevealed) return;

    setState(() {
      _scratchPoints.add(localPos);
    });

    // Provide tactile scratching feedback every 5 drag points
    if (_scratchPoints.length % 5 == 0) {
      HapticFeedback.selectionClick();
    }

    // Auto-reveal once scratched sufficiently (e.g. 30+ swipe points)
    if (_scratchPoints.length >= 30 && !_isRevealed) {
      _revealCard();
    }
  }

  void _revealCard() {
    if (_isRevealed) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _isRevealed = true;
    });
    _revealAnimCtrl.forward();
    _notifyResult();
  }

  Future<void> _claimReward() async {
    setState(() => _isClaiming = true);
    try {
      if (widget.userId != 'anon') {
        final shortOrder = widget.orderId.length >= 8 ? widget.orderId.substring(0, 8) : widget.orderId;
        await WalletRepository().addFunds(
          userId: widget.userId,
          amount: _cashbackAmount,
          description: 'Mystery Scratch Card Reward for Order #$shortOrder',
          orderId: widget.orderId,
        );
      }
      if (mounted) {
        setState(() {
          _isClaiming = false;
          _isClaimed = true;
        });
        HapticFeedback.heavyImpact();
        _notifyResult();
      }
    } catch (_) {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row with Dynamic Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🎁', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Mystery Scratch Card',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                onPressed: () {
                  _notifyResult();
                  Navigator.pop(
                    context,
                    ScratchCardResult(
                      isWinner: _isWinner,
                      amount: _cashbackAmount,
                      isClaimed: _isClaimed,
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Live Scratch Card Status Pill
          _buildStatusBanner(),
          const SizedBox(height: 14),

          // Interactive Scratch Area Stack
          Container(
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: (_isRevealed && _isWinner)
                      ? const Color(0xFF10B981).withValues(alpha: 0.25)
                      : const Color(0xFF6366F1).withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. UNDERLYING REVEALED PRIZE CARD
                  ScaleTransition(
                    scale: _isRevealed ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
                    child: _buildPrizeCard(),
                  ),

                  // 2. SCRATCHABLE METALLIC FOIL LAYER (DISSOLVES ON REVEAL)
                  if (!_isRevealed)
                    GestureDetector(
                      onPanStart: (details) => _onScratch(details.localPosition),
                      onPanUpdate: (details) => _onScratch(details.localPosition),
                      onPanEnd: (_) => _scratchPoints.add(null),
                      onTap: _revealCard,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF6366F1), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CustomPaint(
                          painter: _ScratchFoilPainter(points: _scratchPoints),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.touch_app_rounded, color: Colors.white, size: 32),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'RUB TO SCRATCH & WIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Swipe your finger across to reveal prize',
                                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Bottom Action Panel
          if (!_isRevealed)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton.icon(
                onPressed: _revealCard,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF6366F1)),
                label: const Text(
                  'Tap to Quick Reveal ⚡',
                  style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            )
          else if (_isRevealed && _isWinner && !_isClaimed)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isClaiming ? null : _claimReward,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isClaiming
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Claim ₹${_cashbackAmount.toStringAsFixed(0)} to Wallet 🎁',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
              ),
            )
          else if (_isRevealed && _isWinner && _isClaimed)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '₹${_cashbackAmount.toStringAsFixed(0)}.00 Credited to Wallet ✓',
                        style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () {
                      _notifyResult();
                      Navigator.pop(
                        context,
                        ScratchCardResult(
                          isWinner: _isWinner,
                          amount: _cashbackAmount,
                          isClaimed: _isClaimed,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFF059669), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Done & Continue Shopping 🛍️', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ],
            )
          else if (_isRevealed && !_isWinner)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  _notifyResult();
                  Navigator.pop(
                    context,
                    ScratchCardResult(
                      isWinner: _isWinner,
                      amount: _cashbackAmount,
                      isClaimed: _isClaimed,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Got It 👍 Continue Shopping', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (!_isRevealed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 13, color: Color(0xFF6366F1)),
            SizedBox(width: 5),
            Text(
              'STATUS: CARD READY • RUB FOIL TO REVEAL',
              style: TextStyle(color: Color(0xFF4F46E5), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.3),
            ),
          ],
        ),
      );
    } else if (_isWinner && !_isClaimed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration_rounded, size: 13, color: Color(0xFFD97706)),
            SizedBox(width: 5),
            Text(
              'STATUS: 🎉 YOU WON! TAP CLAIM BELOW',
              style: TextStyle(color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.3),
            ),
          ],
        ),
      );
    } else if (_isWinner && _isClaimed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
            SizedBox(width: 5),
            Text(
              'STATUS: ✅ REWARD ADDED TO WALLET',
              style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.3),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 13, color: Color(0xFF64748B)),
            SizedBox(width: 5),
            Text(
              'STATUS: 🍀 CARD REVEALED',
              style: TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.3),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPrizeCard() {
    if (_isWinner) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFF34D399), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉 💰 🎁', style: TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(
              '₹${_cashbackAmount.toStringAsFixed(0)}.00 CASHBACK',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF065F46),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _isClaimed ? '✓ Added to Wallet Balance' : 'Instant Wallet Credit Guaranteed',
                style: const TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🍀', style: TextStyle(fontSize: 34)),
            SizedBox(height: 6),
            Text(
              'Better Luck Next Time!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
            ),
            SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'Keep placing orders with GroceryGo to unlock exclusive rewards on your next order!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600, height: 1.2),
              ),
            ),
          ],
        ),
      );
    }
  }
}

class _ScratchFoilPainter extends CustomPainter {
  final List<Offset?> points;

  _ScratchFoilPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw subtle holographic decorative sparkles in the background
    final sparkPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 20, sparkPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 30, sparkPaint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), 15, sparkPaint);

    // Scratch trails
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 24.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ScratchFoilPainter oldDelegate) => true;
}
