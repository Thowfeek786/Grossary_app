import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:core/core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with WidgetsBindingObserver {
  final UserRepository _userRepo = UserRepository();
  AddressModel? _selectedAddress;
  String _paymentMethod = 'Cash on Delivery';
  bool _useWalletBalance = false;
  bool _isAwaitingUpiConfirmation = false;
  int _selectedDateIndex = 0;
  String _selectedSlotKey = 'asap';
  final Set<String> _selectedInstructions = {};

  static const List<_DeliverySlotOption> _deliverySlots = [
    _DeliverySlotOption(
      key: 'asap',
      title: 'Deliver ASAP',
      timeRange: '20–30 minutes',
      icon: Icons.bolt_rounded,
      cutoffHour: 24,
    ),
    _DeliverySlotOption(
      key: 'morning',
      title: 'Morning',
      timeRange: '8 AM – 10 AM',
      icon: Icons.wb_sunny_outlined,
      cutoffHour: 10,
    ),
    _DeliverySlotOption(
      key: 'afternoon',
      title: 'Afternoon',
      timeRange: '12 PM – 2 PM',
      icon: Icons.wb_sunny_rounded,
      cutoffHour: 14,
    ),
    _DeliverySlotOption(
      key: 'evening',
      title: 'Evening',
      timeRange: '5 PM – 7 PM',
      icon: Icons.nights_stay_outlined,
      cutoffHour: 19,
    ),
    _DeliverySlotOption(
      key: 'night',
      title: 'Night',
      timeRange: '8 PM – 10 PM',
      icon: Icons.nightlight_round,
      cutoffHour: 22,
    ),
  ];

  List<DateTime> get _availableDates {
    final now = DateTime.now();
    return List.generate(4, (i) => now.add(Duration(days: i)));
  }

  String _formatDateTitle(int index, DateTime date) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  String _formatDateSubtitle(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  String get _selectedSlotSummary {
    final date = _availableDates[_selectedDateIndex];
    final dateLabel = _selectedDateIndex == 0 ? 'Today' : (_selectedDateIndex == 1 ? 'Tomorrow' : _formatDateSubtitle(date));
    final slot = _deliverySlots.firstWhere((s) => s.key == _selectedSlotKey, orElse: () => _deliverySlots.first);
    return '$dateLabel (${slot.title} - ${slot.timeRange})';
  }

  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'GroceryGo Wallet',
    'UPI',
    'Card'
  ];

  Stream<List<AddressModel>>? _addressesStream;
  Stream<WalletModel>? _walletStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isAwaitingUpiConfirmation && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Returned to GroceryGo. Please confirm your UPI payment status.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF6366F1),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _addressesStream ??= _userRepo.getAddresses(user.id);
      _walletStream ??= WalletRepository().getWallet(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Checkout',
            style: TextStyle(
                color: Color(0xFF111827), fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<List<AddressModel>>(
        stream: _addressesStream,
        initialData: _userRepo.getCachedAddresses(user.id),
        builder: (context, snapshot) {
          final addresses = (snapshot.data ?? []).toList();
          if (addresses.isEmpty && (user.shopAddress != null && user.shopAddress!.trim().isNotEmpty)) {
            addresses.add(AddressModel(
              id: 'profile_addr_${user.id}',
              userId: user.id,
              label: 'Default',
              fullName: user.name,
              phone: user.phone,
              addressLine1: user.shopAddress!,
              city: '',
              state: '',
              pincode: '',
              isDefault: true,
            ));
          }

          final effectiveAddress = _selectedAddress ??
              (addresses.isNotEmpty
                  ? addresses.firstWhere((a) => a.isDefault,
                      orElse: () => addresses.first)
                  : null);

          return StreamBuilder<WalletModel>(
            stream: _walletStream,
            builder: (context, walletSnap) {
              final wallet = walletSnap.data ??
                  WalletModel(
                      userId: user.id,
                      balance: 0.0,
                      transactions: [],
                      updatedAt: DateTime.now());

              final walletBalance = wallet.balance;
              final appliedWallet = _useWalletBalance
                  ? (walletBalance > cart.total ? cart.total : walletBalance)
                  : 0.0;
              final remainingPayable = cart.total - appliedWallet;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Delivery Address Card
                    _buildCard(
                      title: 'Delivery Address',
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFF10B981),
                      child: (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData)
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF059669)),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Loading saved addresses...',
                                      style: TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            )
                          : addresses.isEmpty
                              ? _AddAddressPrompt(
                                  onTap: () =>
                                      context.push('/profile/add-address'))
                              : Column(
                                  children: [
                                    ...addresses.map((a) => _AddressTile(
                                          address: a,
                                          isSelected:
                                              effectiveAddress?.id == a.id,
                                          onSelect: () => setState(
                                              () => _selectedAddress = a),
                                        )),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () =>
                                      context.push('/profile/add-address'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: const Color(0xFF059669)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_rounded,
                                            color: Color(0xFF059669), size: 18),
                                        SizedBox(width: 6),
                                        Text('Add New Address',
                                            style: TextStyle(
                                                color: Color(0xFF059669),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),

                    const SizedBox(height: 16),

                    // 2. Scheduled Delivery Card
                    _buildScheduledDeliveryCard(context, cart),

                    const SizedBox(height: 16),

                    // 2.5 Delivery Instructions Card
                    _buildDeliveryInstructionsCard(),

                    const SizedBox(height: 16),

                    // 3. Order Items Summary Card
                    _buildCard(
                      title: 'Order Items (${cart.itemCount})',
                      icon: Icons.shopping_bag_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      child: Column(
                        children: cart.items
                            .map((item) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: item.imageUrl != null &&
                                                  item.imageUrl!.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: item.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, __, ___) =>
                                                      const Icon(
                                                          Icons.image_outlined,
                                                          color: Colors.grey),
                                                )
                                              : const Icon(Icons.image_outlined,
                                                  color: Colors.grey),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13,
                                                  color: Color(0xFF111827)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item.quantity} × ${item.unit}',
                                              style: const TextStyle(
                                                  color: Color(0xFF6B7280),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₹${item.totalPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF059669),
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. Applied Coupon Banner
                    if (cart.appliedCoupon != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer_rounded,
                                color: Color(0xFF059669)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Coupon "${cart.appliedCoupon!.code}" Applied',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF059669),
                                        fontSize: 13),
                                  ),
                                  Text(
                                    'You save ₹${cart.discountAmount.toStringAsFixed(0)} on this order',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF047857),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '-₹${cart.discountAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xFF059669)),
                            ),
                          ],
                        ),
                      ),

                    // 4. Split Wallet Toggle Card (If user has wallet balance)
                    if (walletBalance > 0 &&
                        _paymentMethod != 'GroceryGo Wallet')
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Color(0xFF059669),
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Use Wallet Balance',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Color(0xFF111827)),
                                  ),
                                  Text(
                                    'Available: ₹${walletBalance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF059669),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _useWalletBalance,
                              activeThumbColor: const Color(0xFF059669),
                              onChanged: (val) =>
                                  setState(() => _useWalletBalance = val),
                            ),
                          ],
                        ),
                      ),

                    // 5. Payment Method Selection Card
                    _buildCard(
                      title: 'Payment Method',
                      icon: Icons.payment_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      child: Column(
                        children: _paymentMethods.map((method) {
                          final isSelected = _paymentMethod == method;
                          final isWallet = method == 'GroceryGo Wallet';
                          return GestureDetector(
                            onTap: () => setState(() => _paymentMethod = method),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF10B981)
                                        .withValues(alpha: 0.06)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF059669)
                                      : Colors.grey.shade200,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked_rounded
                                            : Icons.radio_button_off_rounded,
                                        color: isSelected
                                            ? const Color(0xFF059669)
                                            : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        method,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF111827)),
                                      ),
                                      if (isWallet) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF059669),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Text('Instant',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (isWallet && isSelected)
                                    Container(
                                      margin: const EdgeInsets.only(
                                          top: 10, left: 32),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: walletBalance >= cart.total
                                            ? const Color(0xFF10B981)
                                                .withValues(alpha: 0.1)
                                            : const Color(0xFFEF4444)
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Balance: ₹${walletBalance.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                              color: walletBalance >= cart.total
                                                  ? const Color(0xFF047857)
                                                  : const Color(0xFFDC2626),
                                            ),
                                          ),
                                          if (walletBalance < cart.total)
                                            GestureDetector(
                                              onTap: () =>
                                                  context.push('/profile/wallet'),
                                              child: const Text(
                                                'Top Up Wallet →',
                                                style: TextStyle(
                                                  color: Color(0xFF059669),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  if (method == 'UPI' && isSelected)
                                    StreamBuilder<AdminPaymentSettings>(
                                      stream: PaymentRepository()
                                          .streamPaymentSettings(),
                                      builder: (context, settingsSnap) {
                                        final settings = settingsSnap.data ??
                                            const AdminPaymentSettings();
                                        return Container(
                                          margin: const EdgeInsets.only(
                                              top: 10, left: 32),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6366F1)
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: const Color(0xFF6366F1)
                                                    .withValues(alpha: 0.3)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                      Icons.qr_code_2_rounded,
                                                      color: Color(0xFF6366F1),
                                                      size: 18),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      'Payee VPA: ${settings.upiId}',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 12,
                                                          color: Color(0xFF0F172A)),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Payee: ${settings.merchantName}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF64748B),
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              const SizedBox(height: 10),
                                              OutlinedButton.icon(
                                                onPressed: () => _showUpiQrDialog(
                                                    context,
                                                    settings,
                                                    remainingPayable),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      const Color(0xFF6366F1),
                                                  side: const BorderSide(
                                                      color: Color(0xFF6366F1)),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                ),
                                                icon: const Icon(
                                                    Icons.qr_code_rounded,
                                                    size: 16),
                                                label: const Text(
                                                    'Show Scannable UPI QR',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: StreamBuilder<List<AddressModel>>(
        stream: _addressesStream,
        initialData: _userRepo.getCachedAddresses(user.id),
        builder: (context, snapshot) {
          final addresses = (snapshot.data ?? []).toList();
          if (addresses.isEmpty && (user.shopAddress != null && user.shopAddress!.trim().isNotEmpty)) {
            addresses.add(AddressModel(
              id: 'profile_addr_${user.id}',
              userId: user.id,
              label: 'Default',
              fullName: user.name,
              phone: user.phone,
              addressLine1: user.shopAddress!,
              city: '',
              state: '',
              pincode: '',
              isDefault: true,
            ));
          }

          final effectiveAddress = _selectedAddress ??
              (addresses.isNotEmpty
                  ? addresses.firstWhere((a) => a.isDefault,
                      orElse: () => addresses.first)
                  : null);
          return _buildPlaceOrderBar(context, cart, user, effectiveAddress);
        },
      ),
    );
  }

  void _showUpiQrDialog(
      BuildContext context, AdminPaymentSettings settings, double amount) {
    final upiUrl =
        'upi://pay?pa=${settings.upiId}&pn=${Uri.encodeComponent(settings.merchantName)}&am=${amount.toStringAsFixed(2)}&cu=INR';
    final qrImageUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(upiUrl)}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF6366F1)),
            SizedBox(width: 10),
            Text('Scan UPI QR Code',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.network(
                qrImageUrl,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Column(
                  children: [
                    Icon(Icons.qr_code_2_rounded,
                        size: 100, color: Color(0xFF6366F1)),
                    Text('Scan to Pay',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Payee: ${settings.merchantName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              'VPA: ${settings.upiId}',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
            const SizedBox(height: 6),
            Text(
              'Amount: ₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF059669)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      {required String title,
      required IconData icon,
      required Color iconColor,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildScheduledDeliveryCard(BuildContext context, CartProvider cart) {
    final now = DateTime.now();
    return _buildCard(
      title: 'Scheduled Delivery',
      icon: Icons.schedule_rounded,
      iconColor: const Color(0xFF046A38),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Date',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_availableDates.length, (index) {
                final date = _availableDates[index];
                final isSelected = _selectedDateIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDateIndex = index;
                      if (index == 0) {
                        final currentSlot = _deliverySlots.firstWhere((s) => s.key == _selectedSlotKey, orElse: () => _deliverySlots.first);
                        if (now.hour >= currentSlot.cutoffHour) {
                          _selectedSlotKey = 'asap';
                        }
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF046A38) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF046A38) : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDateTitle(index, date),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateSubtitle(date),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white70 : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Choose Time Slot',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: _deliverySlots.map((slot) {
              final isToday = _selectedDateIndex == 0;
              final isPast = isToday && now.hour >= slot.cutoffHour;
              final isSelected = _selectedSlotKey == slot.key;

              return GestureDetector(
                onTap: isPast
                    ? null
                    : () => setState(() => _selectedSlotKey = slot.key),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.grey.shade100
                        : (isSelected
                            ? const Color(0xFFEDF7EE)
                            : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPast
                          ? Colors.grey.shade200
                          : (isSelected
                              ? const Color(0xFF046A38)
                              : Colors.grey.shade200),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPast
                            ? Icons.block_rounded
                            : (isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded),
                        color: isPast
                            ? Colors.grey.shade400
                            : (isSelected
                                ? const Color(0xFF046A38)
                                : const Color(0xFF9CA3AF)),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(slot.icon,
                                    size: 15,
                                    color: isPast
                                        ? Colors.grey.shade400
                                        : const Color(0xFF046A38)),
                                const SizedBox(width: 6),
                                Text(
                                  slot.title,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: isPast
                                        ? Colors.grey.shade400
                                        : const Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              slot.timeRange,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isPast
                                    ? Colors.grey.shade400
                                    : const Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isPast)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Unavailable',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                      else
                        Builder(
                          builder: (context) {
                            final slotFee = cart.getDeliveryFeeForSlot(slot.key);
                            return Text(
                              slotFee == 0 ? 'FREE' : '₹${slotFee.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                color: slotFee == 0
                                    ? const Color(0xFF046A38)
                                    : const Color(0xFF4B5563),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInstructionsCard() {
    const options = [
      {'icon': Icons.notifications_off_outlined, 'title': "Don't ring bell", 'desc': 'Leave quietly'},
      {'icon': Icons.door_front_door_outlined, 'title': 'Leave at door', 'desc': 'Drop at doorstep'},
      {'icon': Icons.phone_callback_outlined, 'title': 'Call before reaching', 'desc': 'Notify 5m before'},
      {'icon': Icons.shield_outlined, 'title': 'Leave with guard', 'desc': 'Security / reception'},
    ];

    return _buildCard(
      title: 'Delivery Instructions (Optional)',
      icon: Icons.speaker_notes_outlined,
      iconColor: const Color(0xFF8B5CF6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select instructions for your delivery partner',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final title = opt['title'] as String;
              final icon = opt['icon'] as IconData;
              final isSelected = _selectedInstructions.contains(title);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInstructions.remove(title);
                    } else {
                      _selectedInstructions.add(title);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEDE9FE) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? const Color(0xFF5B21B6) : const Color(0xFF374151),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF7C3AED)),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderBar(
      BuildContext context, CartProvider cart, UserModel user, AddressModel? effectiveAddress) {
    final orderProvider = context.watch<OrderProvider>();

    return StreamBuilder<WalletModel>(
      stream: WalletRepository().getWallet(user.id),
      builder: (context, walletSnap) {
        final walletBalance = walletSnap.data?.balance ?? 0.0;
        final effectiveTotal = cart.getTotalForSlot(_selectedSlotKey);
        final appliedWallet = _useWalletBalance
            ? (walletBalance > effectiveTotal ? effectiveTotal : walletBalance)
            : 0.0;
        final remainingPayable = effectiveTotal - appliedWallet;

        return Container(
          padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom + 8
                  : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (appliedWallet > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Wallet Discount Applied:',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669))),
                      Text('-₹${appliedWallet.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669))),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PAYABLE AMOUNT',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6B7280),
                              letterSpacing: 0.8)),
                      Text('Inclusive of all taxes',
                          style:
                              TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                  Text(
                    '₹${remainingPayable.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (effectiveAddress == null || orderProvider.isLoading)
                      ? null
                      : () => _placeOrder(context, cart, user, effectiveAddress, appliedWallet, remainingPayable),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: orderProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Place Order Now',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w900)),
                            SizedBox(width: 8),
                            Icon(Icons.check_circle_rounded, size: 20),
                          ],
                        ),
                ),
              ),
              if (effectiveAddress == null)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Please add or select a delivery address to place order',
                    style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _placeOrder(BuildContext context, CartProvider cart,
      UserModel user, AddressModel selectedAddress, double appliedWallet, double remainingPayable) async {
    final orderProvider = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    // Deduct wallet balance if wallet is selected or split wallet used
    if (_paymentMethod == 'GroceryGo Wallet') {
      try {
        final walletStream = await WalletRepository().getWallet(user.id).first;
        if (walletStream.balance < cart.total) {
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: const Text(
                    'Insufficient wallet balance. Please top up your wallet or choose another payment method.'),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          return;
        }
      } catch (_) {}
    }

    AdminPaymentSettings settings = const AdminPaymentSettings();

    // 1. If UPI is selected, launch payment app and verify completion BEFORE placing order
    if (_paymentMethod == 'UPI' && remainingPayable > 0) {
      _isAwaitingUpiConfirmation = true;
      try {
        settings = await PaymentRepository().getPaymentSettings();
        final upiVpa =
            settings.upiId.isNotEmpty ? settings.upiId : 'sthowfeek65@okaxis';
        final payeeName = Uri.encodeComponent(settings.merchantName.isNotEmpty
            ? settings.merchantName
            : 'GroceryGo Official Store');
        final amt = remainingPayable.toStringAsFixed(2);
        final note = Uri.encodeComponent('GroceryGo Order Payment');

        final upiUrl =
            'upi://pay?pa=$upiVpa&pn=$payeeName&am=$amt&cu=INR&tn=$note';
        final uri = Uri.parse(upiUrl);

        try {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
          if (!launched) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (err) {
            debugPrint('Could not launch UPI app: $err');
          }
        }
      } catch (e) {
        debugPrint('Error launching UPI payment app: $e');
      }

      if (!mounted) return;
      final confirmationResult = await _showUpiConfirmationSheet(
          this.context, remainingPayable, settings);
      _isAwaitingUpiConfirmation = false;

      if (confirmationResult == 'COD') {
        _paymentMethod = 'Cash on Delivery';
      } else if (confirmationResult != true) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: const Text(
                  'UPI payment was not completed. Order has not been placed.'),
              backgroundColor: const Color(0xFFF59E0B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }
    }

    final isOrderPaid =
        _paymentMethod == 'GroceryGo Wallet' || _paymentMethod == 'UPI';

    final selectedDeliveryFee = cart.getDeliveryFeeForSlot(_selectedSlotKey);
    final selectedTotal = cart.getTotalForSlot(_selectedSlotKey);

    final order = OrderModel(
      id: '',
      userId: user.id,
      userName: user.name,
      userEmail: user.email,
      userPhone: user.phone,
      items: cart.items.toList(),
      deliveryAddress: selectedAddress,
      status: OrderStatus.pending,
      subtotal: cart.subtotal,
      deliveryFee: selectedDeliveryFee,
      discount: cart.discountAmount + appliedWallet,
      total: selectedTotal,
      paymentMethod: _paymentMethod,
      isPaid: isOrderPaid,
      dealerId: cart.items.isNotEmpty ? cart.items.first.dealerId : null,
      dealerName: cart.items.isNotEmpty ? cart.items.first.dealerName : null,
      notes: 'Scheduled: $_selectedSlotSummary',
      idempotencyKey: '${user.id}_${DateTime.now().millisecondsSinceEpoch}_${cart.items.length}',
      deliveryInstructions: _selectedInstructions.toList(),
      createdAt: DateTime.now(),
    );

    final id = await orderProvider.placeOrder(order);
    if (!mounted) return;

    if (id != null) {
      // Deduct wallet balance if split wallet used
      if (appliedWallet > 0) {
        try {
          await WalletRepository().deductBalance(
            userId: user.id,
            amount: appliedWallet,
            description:
                'Partial Wallet Payment for Order #${id.substring(0, 6).toUpperCase()}',
          );
        } catch (_) {}
      }

      // Full wallet payment deduction
      if (_paymentMethod == 'GroceryGo Wallet') {
        try {
          await WalletRepository().deductBalance(
            userId: user.id,
            amount: cart.total,
            description:
                'Full Wallet Payment for Order #${id.substring(0, 6).toUpperCase()}',
          );
        } catch (_) {}
      }

      // Create Payment Transaction Record
      try {
        final gateway = _paymentMethod == 'UPI'
            ? PaymentGateway.upi
            : (_paymentMethod == 'GroceryGo Wallet'
                ? PaymentGateway.wallet
                : PaymentGateway.cod);
        await PaymentRepository().createPaymentIntent(
          orderId: id,
          userId: user.id,
          userName: user.name,
          amount: remainingPayable,
          walletAmountUsed: appliedWallet,
          gateway: gateway,
        );
      } catch (_) {}

      // Increment coupon usage count if coupon applied
      if (cart.appliedCoupon != null) {
        try {
          await CouponRepository().incrementUsage(cart.appliedCoupon!.id);
        } catch (_) {}
      }

      // Trigger Out-App System Tray Notification & Audio Sound
      try {
        AudioService().playOrderSuccessSound();
        final shortId = id.substring(0, id.length > 6 ? 6 : id.length).toUpperCase();
        await NotificationService.showLocalNotification(
          title: 'Order Placed Successfully! 🎉',
          body: 'Your order #$shortId has been placed and is being prepared.',
          payload: '/orders/$id',
        );
      } catch (_) {}

      if (!mounted) return;
      cart.clearCart();
      router.go('/order-success/$id');
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Failed to place order'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<dynamic> _showUpiConfirmationSheet(
      BuildContext context, double amount, AdminPaymentSettings settings) {
    final utrCtrl = TextEditingController();

    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final upiVpa = settings.upiId.isNotEmpty
            ? settings.upiId
            : 'sthowfeek65@okaxis';
        final payeeName = Uri.encodeComponent(settings.merchantName.isNotEmpty
            ? settings.merchantName
            : 'GroceryGo Official Store');
        final amt = amount.toStringAsFixed(2);
        final note = Uri.encodeComponent('GroceryGo Order Payment');

        void launchSpecificUpi(String scheme) {
          final upiUrl =
              '$scheme?pa=$upiVpa&pn=$payeeName&am=$amt&cu=INR&tn=$note';
          try {
            launchUrl(Uri.parse(upiUrl),
                mode: LaunchMode.externalApplication);
          } catch (_) {}
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.qr_code_2_rounded,
                          color: Color(0xFF6366F1), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Complete UPI Payment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            'Awaiting payment completion',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Launch Buttons for Popular UPI Apps
                const Text(
                  'Quick Open App:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B5563)),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildUpiAppChip('GPay', const Color(0xFF4285F4),
                          () => launchSpecificUpi('gpay://upi/pay')),
                      const SizedBox(width: 8),
                      _buildUpiAppChip('PhonePe', const Color(0xFF5F259F),
                          () => launchSpecificUpi('phonepe://pay')),
                      const SizedBox(width: 8),
                      _buildUpiAppChip('Paytm', const Color(0xFF002E6E),
                          () => launchSpecificUpi('paytmmp://pay')),
                      const SizedBox(width: 8),
                      _buildUpiAppChip('BHIM', const Color(0xFFF15A24),
                          () => launchSpecificUpi('bhim://pay')),
                      const SizedBox(width: 8),
                      _buildUpiAppChip('All Apps', const Color(0xFF059669),
                          () => launchSpecificUpi('upi://pay')),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AMOUNT PAYABLE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Payee: ${settings.merchantName}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          Text(
                            'VPA: ${settings.upiId}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: utrCtrl,
                  decoration: InputDecoration(
                    labelText: 'UPI Ref / UTR No. (Optional)',
                    hintText: 'e.g. 324156789012',
                    prefixIcon: const Icon(Icons.receipt_long_rounded,
                        color: Color(0xFF6366F1), size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text(
                      'I\'ve Paid & Place Order',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(ctx, 'COD'),
                        icon: const Icon(Icons.local_shipping_rounded,
                            size: 16),
                        label: const Text('Switch to Cash on Delivery',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD97706),
                          side: const BorderSide(color: Color(0xFFD97706)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(ctx, false),
                      icon: const Icon(Icons.close_rounded,
                          size: 16, color: Color(0xFFEF4444)),
                      label: const Text('Cancel',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpiAppChip(String label, Color color, VoidCallback onTap) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(Icons.account_balance_wallet_rounded, color: color, size: 14),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final AddressModel address;
  final bool isSelected;
  final VoidCallback onSelect;
  const _AddressTile(
      {required this.address,
      required this.isSelected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981).withValues(alpha: 0.06)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF059669)
                : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? const Color(0xFF059669) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.label.toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: Color(0xFF059669))),
                      if (address.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('DEFAULT',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.fullAddress,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAddressPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _AddAddressPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF059669)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_location_alt_rounded, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Text('Add Delivery Address to Continue',
                style: TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w900,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _DeliverySlotOption {
  final String key;
  final String title;
  final String timeRange;
  final IconData icon;
  final int cutoffHour;

  const _DeliverySlotOption({
    required this.key,
    required this.title,
    required this.timeRange,
    required this.icon,
    required this.cutoffHour,
  });
}

