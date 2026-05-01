import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../providers/management_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  final _roleLabels = {
    null: 'All',
    UserRole.customer: 'Customers',
    UserRole.dealer: 'Dealers',
    UserRole.deliveryPartner: 'Delivery',
    UserRole.admin: 'Admins',
  };

  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedRole = _roleLabels.keys.toList()[_tabController.index];
        });
      }
    });
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
        title: 'User Management',
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _roleLabels.values.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
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
            child: StreamBuilder<List<UserModel>>(
              stream: management.getUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoader();
                }
                if (snapshot.hasError) {
                  return AppErrorWidget(message: snapshot.error.toString());
                }

                var users = snapshot.data ?? [];

                // Filter by role
                if (_selectedRole != null) {
                  users =
                      users.where((u) => u.role == _selectedRole).toList();
                }

                // Filter by search
                if (_searchQuery.isNotEmpty) {
                  users = users
                      .where((u) =>
                          u.name.toLowerCase().contains(_searchQuery) ||
                          u.email.toLowerCase().contains(_searchQuery) ||
                          u.phone.contains(_searchQuery))
                      .toList();
                }

                if (users.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No Users Found',
                    subtitle: 'No users match your current filter or search.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final u = users[index];
                    return _UserCard(
                      user: u,
                      onTap: () => _showUserDetails(context, u, management),
                      onToggleActive: () =>
                          management.setUserActive(u.id, !u.isActive),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/management/users/add'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: AppColors.white),
        label: const Text('Add User', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _showUserDetails(BuildContext context, UserModel user,
      AdminManagementProvider management) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
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
                  width: 40,
                  height: 4,
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
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 26))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(user.email,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                        Text(user.phone,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Change Role',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: UserRole.values.map((role) {
                  final isSelected = user.role == role;
                  return FilterChip(
                    label: Text(role.name),
                    selected: isSelected,
                    onSelected: (selected) async {
                      if (selected && !isSelected) {
                        Navigator.pop(ctx);
                        await management.updateUserRole(user.id, role);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${user.name}\'s role updated to ${role.name}'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      }
                    },
                    selectedColor: AppColors.primarySurface,
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Account Active',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  user.isActive
                      ? 'User can log in and use the app'
                      : 'User is blocked from the platform',
                  style: const TextStyle(fontSize: 12),
                ),
                value: user.isActive,
                activeColor: AppColors.success,
                onChanged: (v) async {
                  Navigator.pop(ctx);
                  await management.setUserActive(user.id, v);
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Member since ${AppHelpers.formatDate(user.createdAt)}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onToggleActive,
  });

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin: return AppColors.error;
      case UserRole.dealer: return AppColors.primary;
      case UserRole.deliveryPartner: return AppColors.info;
      case UserRole.customer: return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: !user.isActive
                ? AppColors.error.withOpacity(0.3)
                : AppColors.grey200,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _roleColor(user.role).withOpacity(0.1),
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _roleColor(user.role),
                          fontSize: 16))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(user.email,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _roleColor(user.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          user.role.name.toUpperCase(),
                          style: TextStyle(
                              color: _roleColor(user.role),
                              fontSize: 9,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (!user.isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('BLOCKED',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.grey400, size: 20),
          ],
        ),
      ),
    );
  }
}
