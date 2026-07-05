import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/routes/app_routes.dart';

/// Reusable bottom navigation bar for TRIBAL.
///
/// Usage — just drop it into any screen's [Scaffold.bottomNavigationBar]:
/// ```dart
/// Scaffold(
///   body: ...,
///   bottomNavigationBar: const TribalBottomNav(),
/// )
/// ```
///
/// The active tab is detected automatically from the current GoRouter
/// location — no need to pass an index or active flag per screen.
/// Tab navigation fires [GoRouter.go] so the back-stack stays clean.
/// Tabs whose routes aren't registered yet show a "coming soon" snackbar
/// instead of navigating.
class TribalBottomNav extends StatelessWidget {
  const TribalBottomNav({super.key});

  static const _tabs = [
    _TabConfig(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      route: AppRoutes.home,
    ),
    _TabConfig(
      label: 'Explore',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      route: null, // not implemented yet
    ),
    _TabConfig(
      label: 'Chat',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      route: null, // not implemented yet
    ),
    _TabConfig(
      label: 'Roommate',
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      route: null, // not implemented yet
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _tabs.map((tab) {
              final isActive = tab.route != null &&
                  currentLocation.startsWith(tab.route!);

              return _NavItem(
                tab: tab,
                isActive: isActive,
                onTap: () => _onTap(context, tab),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, _TabConfig tab) {
    if (tab.route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tab.label} is coming soon!'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Don't navigate if already on this tab
    final currentLocation = GoRouterState.of(context).uri.path;
    if (!currentLocation.startsWith(tab.route!)) {
      context.go(tab.route!);
    }
  }
}

// =============================================================================
// Internal config + item widget
// =============================================================================

class _TabConfig {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String? route; // null = not yet implemented

  const _TabConfig({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

class _NavItem extends StatelessWidget {
  final _TabConfig tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? tab.activeIcon : tab.icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              tab.label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}