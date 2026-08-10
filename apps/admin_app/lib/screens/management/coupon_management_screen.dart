import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';

class CouponManagementScreen extends StatefulWidget {
  const CouponManagementScreen({super.key});

  @override
  State<CouponManagementScreen> createState() => _CouponManagementScreenState();
}

class _CouponManagementScreenState extends State<CouponManagementScreen>
    with SingleTickerProviderStateMixin {
  final _couponRepo = CouponRepository();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Coupon Management',
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [Tab(text: 'Active'), Tab(text: 'Expired'), Tab(text: 'All')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCouponForm(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Coupon', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: StreamBuilder<List<CouponModel>>(
        stream: _couponRepo.getAllCoupons(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final all = snap.data ?? [];
          final active = all.where((c) => c.isValid).toList();
          final expired = all.where((c) => !c.isValid).toList();

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _buildList(active, 'No active coupons'),
              _buildList(expired, 'No expired coupons'),
              _buildList(all, 'No coupons created yet'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<CouponModel> coupons, String emptyMsg) {
    if (coupons.isEmpty) {
      return EmptyState(
        icon: Icons.confirmation_num_outlined,
        title: emptyMsg,
        subtitle: 'Tap + to create a coupon',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: coupons.length,
      itemBuilder: (context, i) {
        final c = coupons[i];
        return _CouponCard(
          coupon: c,
          onEdit: () => _showCouponForm(context, coupon: c),
          onToggle: () async {
            await _couponRepo.toggleCouponActive(c.id, !c.isActive);
          },
          onDelete: () => _confirmDelete(c),
        );
      },
    );
  }

  void _confirmDelete(CouponModel coupon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Coupon', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Delete coupon "${coupon.code}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _couponRepo.deleteCoupon(coupon.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Coupon "${coupon.code}" deleted'),
                      backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCouponForm(BuildContext context, {CouponModel? coupon}) {
    final isEdit = coupon != null;
    final codeCtrl = TextEditingController(text: coupon?.code ?? '');
    final descCtrl = TextEditingController(text: coupon?.description ?? '');
    final amountCtrl = TextEditingController(text: coupon?.discountAmount.toString() ?? '');
    final minCtrl = TextEditingController(text: coupon?.minSubtotal.toString() ?? '0');
    final maxCtrl = TextEditingController(text: coupon?.maxDiscount?.toString() ?? '');
    final maxUsageCtrl = TextEditingController(text: coupon?.maxUsage?.toString() ?? '');
    var discountType = coupon?.discountType ?? DiscountType.percentage;
    var expiry = coupon?.expiryDate ?? DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'Edit Coupon' : 'Create Coupon',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),

                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDeco('Coupon Code', Icons.confirmation_num_rounded),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: descCtrl,
                  decoration: _inputDeco('Description', Icons.description_rounded),
                ),
                const SizedBox(height: 14),

                // Discount type toggle
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => discountType = DiscountType.percentage),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: discountType == DiscountType.percentage ? AppColors.primarySurface : AppColors.grey100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: discountType == DiscountType.percentage ? AppColors.primary : AppColors.grey200),
                        ),
                        child: Center(child: Text('Percentage %',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                                color: discountType == DiscountType.percentage ? AppColors.primary : AppColors.textSecondary))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => discountType = DiscountType.fixed),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: discountType == DiscountType.fixed ? AppColors.primarySurface : AppColors.grey100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: discountType == DiscountType.fixed ? AppColors.primary : AppColors.grey200),
                        ),
                        child: Center(child: Text('Fixed ₹',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                                color: discountType == DiscountType.fixed ? AppColors.primary : AppColors.textSecondary))),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),

                Row(children: [
                  Expanded(child: TextField(controller: amountCtrl, keyboardType: TextInputType.number,
                      decoration: _inputDeco(discountType == DiscountType.percentage ? 'Discount %' : 'Discount ₹', Icons.discount_rounded))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: minCtrl, keyboardType: TextInputType.number,
                      decoration: _inputDeco('Min Order ₹', Icons.shopping_cart_rounded))),
                ]),
                const SizedBox(height: 14),

                Row(children: [
                  Expanded(child: TextField(controller: maxCtrl, keyboardType: TextInputType.number,
                      decoration: _inputDeco('Max Discount ₹', Icons.arrow_upward_rounded))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: maxUsageCtrl, keyboardType: TextInputType.number,
                      decoration: _inputDeco('Max Usage', Icons.repeat_rounded))),
                ]),
                const SizedBox(height: 14),

                // Expiry date
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: expiry,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setModalState(() => expiry = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grey300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Text('Expires: ${expiry.day}/${expiry.month}/${expiry.year}',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (codeCtrl.text.trim().isEmpty || amountCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Please fill in code and amount'),
                              backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        );
                        return;
                      }

                      final model = CouponModel(
                        id: coupon?.id ?? '',
                        code: codeCtrl.text.trim().toUpperCase(),
                        description: descCtrl.text.trim(),
                        discountType: discountType,
                        discountAmount: double.tryParse(amountCtrl.text) ?? 0,
                        minSubtotal: double.tryParse(minCtrl.text) ?? 0,
                        maxDiscount: maxCtrl.text.isNotEmpty ? double.tryParse(maxCtrl.text) : null,
                        expiryDate: expiry,
                        isActive: coupon?.isActive ?? true,
                        usageCount: coupon?.usageCount ?? 0,
                        maxUsage: maxUsageCtrl.text.isNotEmpty ? int.tryParse(maxUsageCtrl.text) : null,
                      );

                      if (isEdit) {
                        await _couponRepo.updateCoupon(model);
                      } else {
                        await _couponRepo.addCoupon(model);
                      }

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isEdit ? 'Coupon updated!' : 'Coupon created!'),
                              backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: Text(isEdit ? 'Update Coupon' : 'Create Coupon',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

// ─── Coupon Card ───
class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _CouponCard({
    required this.coupon,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isValid = coupon.isValid;
    final color = isValid ? AppColors.primary : AppColors.grey400;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isValid ? AppColors.primary.withOpacity(0.2) : AppColors.grey200),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.confirmation_num_rounded, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(coupon.code,
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color, letterSpacing: 1)),
                    if (coupon.description.isNotEmpty)
                      Text(coupon.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isValid
                        ? AppColors.success.withOpacity(0.1)
                        : coupon.isExpired
                            ? AppColors.error.withOpacity(0.1)
                            : AppColors.grey200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isValid ? 'Active' : coupon.isExpired ? 'Expired' : 'Disabled',
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: isValid ? AppColors.success : coupon.isExpired ? AppColors.error : AppColors.grey500),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _infoChip(
                      coupon.discountType == DiscountType.percentage
                          ? '${coupon.discountAmount.toStringAsFixed(0)}% OFF'
                          : '₹${coupon.discountAmount.toStringAsFixed(0)} OFF',
                      const Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 8),
                    _infoChip('Min ₹${coupon.minSubtotal.toStringAsFixed(0)}', const Color(0xFF10B981)),
                    if (coupon.maxDiscount != null) ...[
                      const SizedBox(width: 8),
                      _infoChip('Max ₹${coupon.maxDiscount!.toStringAsFixed(0)}', const Color(0xFFF59E0B)),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Expires ${coupon.expiryDate.day}/${coupon.expiryDate.month}/${coupon.expiryDate.year}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const Spacer(),
                    Icon(Icons.repeat_rounded, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${coupon.usageCount}${coupon.maxUsage != null ? '/${coupon.maxUsage}' : ''} used',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_rounded, size: 18), onPressed: onEdit,
                        color: AppColors.primary, tooltip: 'Edit'),
                    IconButton(
                      icon: Icon(coupon.isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded, size: 28),
                      onPressed: onToggle,
                      color: coupon.isActive ? AppColors.success : AppColors.grey400,
                      tooltip: coupon.isActive ? 'Disable' : 'Enable',
                    ),
                    IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18), onPressed: onDelete,
                        color: AppColors.error, tooltip: 'Delete'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
