import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/home_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/activity_model.dart';
import '../../widgets/tribal_bottom_nav.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, ctrl, _) => Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: const TribalBottomNav(),
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
          title: Text('Notifications',
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          centerTitle: true,
        ),
        body: ctrl.isLoading && ctrl.notifications.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ctrl.notifications.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: ctrl.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        _NotificationTile(notification: ctrl.notifications[i]),
                  ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  IconData get _icon {
    switch (notification.type) {
      case 'join': return Icons.people_rounded;
      case 'match': return Icons.local_fire_department_rounded;
      case 'reminder': return Icons.alarm_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color get _iconBg {
    switch (notification.type) {
      case 'join': return const Color(0xFFE8F5E9);
      case 'match': return const Color(0xFFFFF3E0);
      case 'reminder': return const Color(0xFFE3F2FD);
      default: return AppColors.surface;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case 'join': return Colors.green;
      case 'match': return Colors.orange;
      case 'reminder': return Colors.blue;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (notification.activityId != null) {
          context.push(AppRoutes.activityDetail, extra: notification.activityId!);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.background : AppColors.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead ? AppColors.divider : AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: _iconBg, shape: BoxShape.circle),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title,
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(notification.body,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                  if (notification.activityTitle != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(notification.activityTitle!,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.primary,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ],
              ),
            ),

            // Unread dot
            if (!notification.isRead)
              Container(
                width: 8, height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No notifications yet',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Join activities to get updates here.',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint)),
        ],
      ),
    );
  }
}
