import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_summary.dart';
import '../widgets/app_top_bar.dart';
import 'sold_inventory_screen.dart';

const _topN = 5;

class DashboardHomeTab extends ConsumerWidget {
  const DashboardHomeTab({
    super.key,
    this.showBackButton = false,
    this.onViewInventory,
  });

  final bool showBackButton;

  /// Called when "View all" is tapped on the Recent Inventory card. Defaults
  /// to popping back to the underlying vehicle list when not provided (the
  /// User-side standalone [DashboardScreen] case); the Admin dashboard
  /// overrides this to switch its persistent tab bar to Inventory instead.
  final VoidCallback? onViewInventory;

  static const _accentBlue = Color(0xFF2F5FDE);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardControllerProvider);
    final userName = ref.watch(authControllerProvider).user?.firstName;

    return Column(
      children: [
        AppTopBar(title: 'Dashboard', showBackButton: showBackButton),
        Expanded(
          child: summaryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(
              message: error.toString(),
              onRetry: () =>
                  ref.read(dashboardControllerProvider.notifier).refresh(),
            ),
            data: (summary) => _DashboardContent(
              summary: summary,
              userName: userName,
              onViewInventory: onViewInventory,
            ),
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

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.summary,
    required this.userName,
    required this.onViewInventory,
  });

  final DashboardSummary summary;
  final String? userName;
  final VoidCallback? onViewInventory;

  @override
  Widget build(BuildContext context) {
    final topTypes = summary.inventoryByType.take(_topN).toList();
    final maxCount = topTypes.isEmpty
        ? 1
        : topTypes.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            userName == null || userName!.isEmpty
                ? 'Hi there 👋'
                : 'Hi, $userName 👋',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            "Here's what's happening today",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 18),
          _StatCard(
            icon: Icons.inventory_2_rounded,
            iconBackground: const Color(0xFFEAF0FB),
            iconColor: DashboardHomeTab._accentBlue,
            value: '${summary.totalInventory.total}',
            label: 'Total Inventory',
            trend: summary.totalInventory.trendLabel,
            activeCount: summary.totalInventory.activeCount,
            soldCount: summary.totalInventory.soldCount,
            onSoldTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SoldInventoryScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.people_alt_rounded,
            iconBackground: const Color(0xFFE6F7ED),
            iconColor: const Color(0xFF1FA76A),
            value: '${summary.totalUsers.total}',
            label: 'Total Users',
            trend: summary.totalUsers.trendLabel,
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.location_on_rounded,
            iconBackground: const Color(0xFFFFF4E5),
            iconColor: const Color(0xFFD97706),
            value: '${summary.totalLocations.total}',
            label: 'Total Locations',
            trend: summary.totalLocations.trendLabel,
          ),
          const SizedBox(height: 20),
          _LastLocationCard(location: summary.lastLocation),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEBECF2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inventory by Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                if (topTypes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No inventory data yet',
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  )
                else
                  SizedBox(
                    height: 110,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final entry in topTypes)
                          Expanded(
                            child: _CategoryBar(
                              label: entry.type,
                              count: entry.count,
                              heightFactor: entry.count / maxCount,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _RecentActivityCard(
            activity: summary.recentActivity.take(_topN).toList(),
          ),
          const SizedBox(height: 16),
          _RecentInventoryCard(
            items: summary.recentInventory.take(_topN).toList(),
            onViewAll:
                onViewInventory ?? () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.trend,
    this.activeCount,
    this.soldCount,
    this.onSoldTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String value;
  final String label;
  final String? trend;

  /// Only set on the Total Inventory card, to render an Active/Sold
  /// breakdown row — [soldCount] is tappable via [onSoldTap].
  final int? activeCount;
  final int? soldCount;
  final VoidCallback? onSoldTap;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (activeCount != null && soldCount != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '$activeCount Active',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1FA76A),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onSoldTap,
                        child: Text(
                          '$soldCount Sold',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (trend != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7ED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                trend!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1FA76A),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

class _LastLocationCard extends StatelessWidget {
  const _LastLocationCard({required this.location});

  final DashboardLastLocation? location;

  static const _accentBlue = Color(0xFF2F5FDE);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBECF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last Login Location',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (location == null)
            const Text(
              'No location recorded yet',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: _accentBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location!.address.isEmpty
                            ? 'Unknown address'
                            : location!.address,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${location!.lat.toStringAsFixed(4)}, ${location!.lng.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Updated ${_formatDate(location!.updatedAt)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.label,
    required this.count,
    required this.heightFactor,
  });

  final String label;
  final int count;
  final double heightFactor;

  static const _accentBlue = Color(0xFF2F5FDE);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$count',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: heightFactor.clamp(0.05, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _accentBlue,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

(IconData, Color) _activityIconFor(String action) {
  if (action.startsWith('inventory')) {
    return (Icons.inventory_2_rounded, const Color(0xFF2F5FDE));
  }
  if (action.startsWith('location')) {
    return (Icons.location_on_rounded, const Color(0xFFD97706));
  }
  if (action.startsWith('user')) {
    return (Icons.person_rounded, const Color(0xFF1FA76A));
  }
  return (Icons.info_outline_rounded, Colors.black45);
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.activity});

  final List<DashboardActivity> activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBECF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (activity.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No recent activity',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            )
          else
            for (var i = 0; i < activity.length; i++) ...[
              if (i > 0) const Divider(height: 17, color: Color(0xFFF0F1F5)),
              _ActivityRow(entry: activity[i]),
            ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final DashboardActivity entry;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _activityIconFor(entry.action);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.message,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 2),
              Text(
                entry.timeAgo,
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentInventoryCard extends StatelessWidget {
  const _RecentInventoryCard({required this.items, required this.onViewAll});

  final List<DashboardRecentInventoryItem> items;
  final VoidCallback onViewAll;

  static const _accentBlue = Color(0xFF2F5FDE);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBECF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent Inventory',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _accentBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No inventory yet',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 17, color: Color(0xFFF0F1F5)),
              _InventoryRow(item: items[i]),
            ],
        ],
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({required this.item});

  final DashboardRecentInventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.chassisNo,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ),
        Text(
          item.color,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
