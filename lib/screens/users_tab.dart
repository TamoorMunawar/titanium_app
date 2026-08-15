import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/user_controller.dart';
import '../core/network/api_exception.dart';
import '../models/app_user.dart';
import '../widgets/add_user_sheet.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/delete_user_dialog.dart';
import '../widgets/edit_user_sheet.dart';
import '../widgets/icon_action_button.dart';
import '../widgets/page_button.dart';
import '../widgets/user_status_badge.dart';

class UsersTab extends ConsumerStatefulWidget {
  const UsersTab({super.key});

  @override
  ConsumerState<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<UsersTab> {
  static const _accentBlue = Color(0xFF2F5FDE);
  static const _fieldFill = Color(0xFFF3F4F8);

  final _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppUser> _filter(List<AppUser> users) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return users;
    return users
        .where((user) =>
            user.fullName.toLowerCase().contains(query) ||
            user.username.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _addUser() async {
    await showAddUserSheet(context);
  }

  Future<void> _editUser(AppUser user) async {
    await showEditUserSheet(context, user);
  }

  Future<void> _confirmDelete(AppUser user) async {
    final confirmed = await showDeleteUserDialog(context, user.fullName);
    if (!confirmed || !mounted) return;

    try {
      await ref.read(userControllerProvider.notifier).deleteUser(user.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userControllerProvider);

    return Stack(
      children: [
        Column(
          children: [
            const AppTopBar(title: 'Users'),
            Expanded(
              child: usersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.read(userControllerProvider.notifier).refresh(),
                ),
                data: (pageState) {
                  final filtered = _filter(pageState.users);
                  final start = (pageState.page - 1) * pageState.limit;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Users',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pageState.total} users across all locations',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            hintText: 'Search users...',
                            hintStyle: const TextStyle(fontSize: 13),
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 20,
                              color: Colors.black45,
                            ),
                            filled: true,
                            fillColor: _fieldFill,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No users match your search',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                          )
                        else
                          for (var i = 0; i < filtered.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12),
                            _UserCard(
                              user: filtered[i],
                              onEdit: () => _editUser(filtered[i]),
                              onDelete: () => _confirmDelete(filtered[i]),
                            ),
                          ],
                        if (pageState.total > 0) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                '${start + 1}-${start + pageState.users.length} of ${pageState.total}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const Spacer(),
                              for (var i = 0; i < pageState.pages; i++)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: PageButton(
                                    label: '${i + 1}',
                                    selected: i + 1 == pageState.page,
                                    onTap: () => ref
                                        .read(userControllerProvider.notifier)
                                        .goToPage(i + 1),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: _accentBlue,
            onPressed: _addUser,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.black38, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  final AppUser user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _mutedBlue = Color(0xFF5C6B8C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBECF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              UserStatusBadge(active: user.isActive),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${user.username} Â· ${user.email}',
            style: const TextStyle(fontSize: 11, color: _mutedBlue),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${user.role} Â· ${user.location ?? 'Unassigned'}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              IconActionButton(icon: Icons.visibility_outlined, onTap: () {}),
              const SizedBox(width: 4),
              IconActionButton(icon: Icons.edit_outlined, onTap: onEdit),
              const SizedBox(width: 4),
              IconActionButton(icon: Icons.lock_outline, onTap: () {}),
              const SizedBox(width: 4),
              IconActionButton(icon: Icons.delete_outline, onTap: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}
