import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../providers/management_provider.dart';

class DealerManagementScreen extends StatefulWidget {
  const DealerManagementScreen({super.key});

  @override
  State<DealerManagementScreen> createState() => _DealerManagementScreenState();
}

class _DealerManagementScreenState extends State<DealerManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final management = context.watch<AdminManagementProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Dealers & Vendors',
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Approved'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search dealers...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.grey200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.grey200),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDealerList(management, filter: 'all'),
                _buildDealerList(management, filter: 'approved'),
                _buildDealerList(management, filter: 'pending'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealerList(AdminManagementProvider management,
      {required String filter}) {
    return StreamBuilder<List<UserModel>>(
      stream: management.getUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoader();
        }

        var dealers = (snapshot.data ?? [])
            .where((u) => u.role == UserRole.dealer)
            .toList();

        // Apply search
        if (_searchQuery.isNotEmpty) {
          dealers = dealers
              .where((d) =>
                  d.name.toLowerCase().contains(_searchQuery) ||
                  d.email.toLowerCase().contains(_searchQuery) ||
                  (d.shopName?.toLowerCase().contains(_searchQuery) ?? false))
              .toList();
        }

        // Apply tab filter
        if (filter == 'approved') {
          dealers = dealers.where((d) => d.isApproved && d.isActive).toList();
        } else if (filter == 'pending') {
          dealers = dealers.where((d) => !d.isApproved).toList();
        }

        if (dealers.isEmpty) {
          return EmptyState(
            icon: Icons.storefront_outlined,
            title: filter == 'pending'
                ? 'No Pending Approvals'
                : 'No Dealers Found',
            subtitle: filter == 'pending'
                ? 'All dealer registrations are reviewed.'
                : 'No dealers match your search.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: dealers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final d = dealers[index];
            return _DealerCard(
              dealer: d,
              onApprove: () => _toggleApproval(context, d, management, true),
              onSuspend: () => _toggleApproval(context, d, management, false),
              onViewDetails: () => _showDealerDetails(context, d, management),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleApproval(BuildContext context, UserModel dealer,
      AdminManagementProvider management, bool approved) async {
    try {
      await management.setUserApproval(dealer.id, approved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved
                ? '${dealer.name} has been approved'
                : '${dealer.name} has been suspended'),
            backgroundColor:
                approved ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _showDealerDetails(BuildContext context, UserModel dealer,
      AdminManagementProvider management) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      dealer.name.isNotEmpty
                          ? dealer.name[0].toUpperCase()
                          : 'D',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 26),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dealer.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(dealer.email,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: dealer.isApproved
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                dealer.isApproved ? 'APPROVED' : 'PENDING',
                                style: TextStyle(
                                    color: dealer.isApproved
                                        ? AppColors.success
                                        : AppColors.warning,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (dealer.shopName != null) ...[
                _DetailRow(Icons.store_rounded, 'Shop Name', dealer.shopName!),
                const SizedBox(height: 12),
              ],
              if (dealer.shopAddress != null) ...[
                _DetailRow(Icons.location_on_rounded, 'Address', dealer.shopAddress!),
                const SizedBox(height: 12),
              ],
              _DetailRow(Icons.phone_rounded, 'Phone', dealer.phone),
              const SizedBox(height: 12),
              _DetailRow(Icons.star_rounded, 'Rating',
                  '${dealer.rating?.toStringAsFixed(1) ?? 'N/A'}'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: dealer.isApproved ? 'Suspend Dealer' : 'Approve Dealer',
                      variant: dealer.isApproved
                          ? AppButtonVariant.outlined
                          : AppButtonVariant.primary,
                      onTap: () {
                        Navigator.pop(ctx);
                        _toggleApproval(
                            context, dealer, management, !dealer.isApproved);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _DealerCard extends StatelessWidget {
  final UserModel dealer;
  final VoidCallback onApprove;
  final VoidCallback onSuspend;
  final VoidCallback onViewDetails;

  const _DealerCard({
    required this.dealer,
    required this.onApprove,
    required this.onSuspend,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewDetails,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !dealer.isApproved
                ? AppColors.warning.withOpacity(0.4)
                : AppColors.grey200,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primarySurface,
                  child: const Icon(Icons.storefront_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dealer.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(dealer.shopName ?? dealer.email,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: dealer.isApproved
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dealer.isApproved ? 'Approved' : 'Pending Approval',
                              style: TextStyle(
                                  color: dealer.isApproved
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.warning, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                dealer.rating?.toStringAsFixed(1) ?? 'N/A',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.grey400),
              ],
            ),
            if (!dealer.isApproved) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Reject',
                      variant: AppButtonVariant.outlined,
                      onTap: onSuspend,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Approve',
                      onTap: onApprove,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
