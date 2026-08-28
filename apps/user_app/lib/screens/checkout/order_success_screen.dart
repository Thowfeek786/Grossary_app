import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/invoice_generator.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;
  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _badgeScale;
  late Animation<double> _checkRotate;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _pulseHalo;
  late Animation<double> _confettiProgress;

  String _selectedInstruction = '🚪 Leave at door';
  final List<String> _deliveryInstructions = [
    '🚪 Leave at door',
    '🔔 Ring doorbell',
    '📞 Call before arrival',
    '🤫 Avoid ringing bell',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _badgeScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );

    _checkRotate = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.5, curve: Curves.easeOutBack),
    );

    _confettiProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.85, curve: Curves.easeOutCubic),
    );

    _contentFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.9, curve: Curves.easeOutCubic),
    ));

    _pulseHalo = Tween<double>(begin: 0.8, end: 1.25).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final shortId = widget.orderId
        .substring(0, widget.orderId.length > 8 ? 8 : widget.orderId.length)
        .toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: StreamBuilder<StoreSettingsModel>(
        stream: SettingsRepository().getGlobalSettings(),
        builder: (context, settingsSnapshot) {
          final deliveryTimingLabel = settingsSnapshot.data?.estimatedDeliveryTime ?? '20 to 30 minutes';

          return StreamBuilder<OrderModel?>(
            stream: orderProvider.getOrderStream(widget.orderId),
            builder: (context, snapshot) {
              final order = snapshot.data;

              return Stack(
                children: [
                  // Background Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFECFDF5),
                            Color(0xFFF8FAFC),
                            Color(0xFFFFFFFF),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Animated Confetti Canvas Overlay
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _confettiProgress,
                      builder: (context, _) => _ConfettiCanvas(
                        progress: _confettiProgress.value,
                      ),
                    ),
                  ),

                  // Content Layout (Compact non-scrolling layout)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),

                          // Compact Center Stage: Pulsing Halo + Badge
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _pulseHalo,
                                builder: (_, __) => Container(
                                  width: 140 * _pulseHalo.value,
                                  height: 140 * _pulseHalo.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF10B981).withValues(
                                      alpha: (1.3 - _pulseHalo.value).clamp(0.0, 0.15),
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _pulseHalo,
                                builder: (_, __) => Container(
                                  width: 115 * _pulseHalo.value,
                                  height: 115 * _pulseHalo.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF059669).withValues(
                                      alpha: (1.2 - _pulseHalo.value).clamp(0.0, 0.22),
                                    ),
                                  ),
                                ),
                              ),

                              // Main Badge
                              ScaleTransition(
                                scale: _badgeScale,
                                child: Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF059669),
                                        Color(0xFF047857),
                                        Color(0xFF064E3B),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF059669).withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: RotationTransition(
                                    turns: Tween(begin: -0.15, end: 0.0).animate(_checkRotate),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                                  ),
                                ),
                              ),

                              // Floating Party Emojis
                              Positioned(
                                top: 0,
                                right: 20,
                                child: ScaleTransition(
                                  scale: _badgeScale,
                                  child: const Text('✨', style: TextStyle(fontSize: 20)),
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                left: 15,
                                child: ScaleTransition(
                                  scale: _badgeScale,
                                  child: const Text('🎉', style: TextStyle(fontSize: 22)),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Compact Headline & Subtitle
                          FadeTransition(
                            opacity: _contentFade,
                            child: SlideTransition(
                              position: _contentSlide,
                              child: Column(
                                children: [
                                  const Text(
                                    'Order Placed! 🎉',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Confirmed & being freshly packed by store',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Compact Summary Card
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 14,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        // Ref ID & Total Row
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'ORDER REF',
                                                  style: TextStyle(
                                                    color: Color(0xFF94A3B8),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '#$shortId',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w900,
                                                        color: Color(0xFF0F172A),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    GestureDetector(
                                                      onTap: () {
                                                        Clipboard.setData(
                                                          ClipboardData(text: widget.orderId),
                                                        );
                                                        HapticFeedback.selectionClick();
                                                        ScaffoldMessenger.of(context).clearSnackBars();
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: const Text(
                                                              'Order ID copied ✓',
                                                            ),
                                                            backgroundColor: const Color(0xFF059669),
                                                            duration: const Duration(seconds: 2),
                                                            behavior: SnackBarBehavior.floating,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 7,
                                                          vertical: 3,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF1F5F9),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: const Text(
                                                          'Copy',
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w800,
                                                            color: Color(0xFF475569),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            if (order != null)
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  const Text(
                                                    'TOTAL AMOUNT',
                                                    style: TextStyle(
                                                      color: Color(0xFF94A3B8),
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '₹${order.total.toStringAsFixed(0)}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w900,
                                                      color: Color(0xFF059669),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),

                                        // Item Thumbnails Strip
                                        if (order != null && order.items.isNotEmpty) ...[
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 8),
                                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                                          ),
                                          SizedBox(
                                            height: 44,
                                            child: ListView.separated(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: order.items.length,
                                              separatorBuilder: (_, __) => const SizedBox(width: 6),
                                              itemBuilder: (ctx, idx) {
                                                final item = order.items[idx];
                                                return Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF8FAFC),
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(10),
                                                    child: item.imageUrl != null &&
                                                            item.imageUrl!.isNotEmpty
                                                        ? CachedNetworkImage(
                                                            imageUrl: item.imageUrl!,
                                                            fit: BoxFit.cover,
                                                            errorWidget: (_, __, ___) => const Icon(
                                                              Icons.shopping_bag_outlined,
                                                              color: Colors.grey,
                                                              size: 18,
                                                            ),
                                                          )
                                                        : const Icon(
                                                            Icons.shopping_bag_outlined,
                                                            color: Colors.grey,
                                                            size: 18,
                                                          ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],

                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 8),
                                          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                                        ),

                                        // Dynamic Admin Delivery Timing Banner (e.g. "20 to 30 minutes")
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFA7F3D0)),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(5),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF059669),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.bolt_rounded,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'ESTIMATED DELIVERY TIMING',
                                                      style: TextStyle(
                                                        color: Color(0xFF047857),
                                                        fontSize: 8,
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 1),
                                                    Text(
                                                      '⚡ $deliveryTimingLabel',
                                                      style: const TextStyle(
                                                        color: Color(0xFF065F46),
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w900,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Mystery Scratch Card Reward Banner
                                  GestureDetector(
                                    onTap: () {
                                      final user = context.read<AuthProvider>().user;
                                      _showScratchCardDialog(context, user?.id ?? 'anon');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFF4F46E5)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Text('🎁', style: TextStyle(fontSize: 16)),
                                          ),
                                          const SizedBox(width: 10),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Mystery Scratch Card 🎁',
                                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                                                ),
                                                Text(
                                                  'Tap to scratch & test your luck for rewards',
                                                  style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Scratch',
                                              style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w900, fontSize: 11),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Delivery Instructions Selector
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Delivery Instruction',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: _deliveryInstructions.map((inst) {
                                            final isSelected = _selectedInstruction == inst;
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 6),
                                              child: ChoiceChip(
                                                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                                visualDensity: VisualDensity.compact,
                                                label: Text(
                                                  inst,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                    color: isSelected
                                                        ? const Color(0xFF047857)
                                                        : const Color(0xFF475569),
                                                  ),
                                                ),
                                                selected: isSelected,
                                                onSelected: (_) {
                                                  setState(() => _selectedInstruction = inst);
                                                  HapticFeedback.selectionClick();
                                                },
                                                selectedColor: const Color(0xFFD1FAE5),
                                                backgroundColor: Colors.white,
                                                side: BorderSide(
                                                  color: isSelected
                                                      ? const Color(0xFF059669)
                                                      : const Color(0xFFCBD5E1),
                                                  width: isSelected ? 1.5 : 1.0,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Compact Bottom CTAs
                          FadeTransition(
                            opacity: _contentFade,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: () => context.go('/orders/${widget.orderId}'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      shadowColor: const Color(0xFF059669).withValues(alpha: 0.3),
                                    ),
                                    icon: const Icon(Icons.local_shipping_rounded, size: 18),
                                    label: const Text(
                                      'Track My Order',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    if (order != null) ...[
                                      Expanded(
                                        child: SizedBox(
                                          height: 42,
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                InvoiceGenerator.generateAndDownload(order),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: Color(0xFFCBD5E1),
                                                width: 1.2,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.picture_as_pdf_rounded,
                                              color: Color(0xFF059669),
                                              size: 15,
                                            ),
                                            label: const Text(
                                              'Invoice PDF',
                                              style: TextStyle(
                                                color: Color(0xFF334155),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: SizedBox(
                                        height: 42,
                                        child: OutlinedButton(
                                          onPressed: () => context.go('/home'),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Color(0xFFCBD5E1),
                                              width: 1.2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'Continue Shopping 🛍️',
                                            style: TextStyle(
                                              color: Color(0xFF475569),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showScratchCardDialog(BuildContext context, String userId) {
    bool isScratched = false;
    bool isClaiming = false;
    bool isClaimed = false;

    // 25% chance to win, 75% chance of Better Luck Next Time
    final random = math.Random();
    final bool isWinner = random.nextInt(100) < 25;
    final double cashbackAmount = isWinner
        ? const [10.0, 15.0, 20.0, 25.0][random.nextInt(4)]
        : 0.0;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🎁 Mystery Scratch Card',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(dlgCtx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Scratch Surface Card
                  GestureDetector(
                    onTap: () {
                      if (!isScratched) {
                        HapticFeedback.heavyImpact();
                        setDialogState(() => isScratched = true);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: isScratched
                            ? (isWinner
                                ? const LinearGradient(
                                    colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : const LinearGradient(
                                    colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ))
                            : const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFF4F46E5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isScratched
                              ? (isWinner ? const Color(0xFF34D399) : const Color(0xFFCBD5E1))
                              : const Color(0xFF818CF8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isScratched
                                ? (isWinner
                                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.05))
                                : const Color(0xFF6366F1).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isScratched
                            ? (isWinner
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('💰', style: TextStyle(fontSize: 36)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${cashbackAmount.toStringAsFixed(0)}.00 CASHBACK',
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Credited directly to your GroceryGo Wallet',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('🍀', style: TextStyle(fontSize: 36)),
                                      SizedBox(height: 6),
                                      Text(
                                        'Better Luck Next Time!',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                                      ),
                                      SizedBox(height: 3),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'Keep shopping with GroceryGo to unlock guaranteed rewards on your next order!',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ))
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.touch_app_rounded, color: Colors.white, size: 36),
                                  SizedBox(height: 8),
                                  Text(
                                    'TAP TO SCRATCH',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'See if you won a mystery cashback reward',
                                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (isScratched && isWinner && !isClaimed)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isClaiming
                            ? null
                            : () async {
                                setDialogState(() => isClaiming = true);
                                try {
                                  if (userId != 'anon') {
                                    await WalletRepository().addFunds(
                                      userId: userId,
                                      amount: cashbackAmount,
                                      description: 'Mystery Scratch Card Reward for Order #${widget.orderId.substring(0, 8)}',
                                      orderId: widget.orderId,
                                    );
                                  }
                                  setDialogState(() {
                                    isClaiming = false;
                                    isClaimed = true;
                                  });
                                } catch (_) {
                                  setDialogState(() => isClaiming = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isClaiming
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('Claim ₹${cashbackAmount.toStringAsFixed(0)} to Wallet 🎁', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      ),
                    )
                  else if (isScratched && isWinner && isClaimed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Added to Wallet Successfully!',
                            style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else if (isScratched && !isWinner)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dlgCtx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Got It 👍',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Custom Confetti Canvas Painter
// ─────────────────────────────────────────────
class _ConfettiCanvas extends StatelessWidget {
  final double progress;
  const _ConfettiCanvas({required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ConfettiPainter(progress: progress),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height * 0.25);
    final colors = [
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];

    final random = math.Random(42);

    for (int i = 0; i < 28; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = (60 + random.nextDouble() * 140) * progress;
      final dx = center.dx + math.cos(angle) * distance;
      final dy = center.dy + math.sin(angle) * distance + (progress * 30);

      final color = colors[i % colors.length].withValues(
        alpha: (1.0 - progress).clamp(0.0, 1.0),
      );
      final paint = Paint()..color = color;

      final particleSize = 3.5 + random.nextDouble() * 4.0;

      if (i % 3 == 0) {
        canvas.drawCircle(Offset(dx, dy), particleSize, paint);
      } else if (i % 3 == 1) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(dx, dy),
            width: particleSize * 1.5,
            height: particleSize,
          ),
          paint,
        );
      } else {
        final path = Path()
          ..moveTo(dx, dy - particleSize)
          ..lineTo(dx + particleSize, dy)
          ..lineTo(dx, dy + particleSize)
          ..lineTo(dx - particleSize, dy)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
