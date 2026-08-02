import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/profile_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/activity_model.dart';
import '../../widgets/profile/profile_shared_widgets.dart';

/// Activities that BOTH the current user and [userId] have joined.
/// Opened from Other User Profile's "View Mutual Activities" button.
class MutualActivitiesScreen extends StatelessWidget {
  final int userId;
  const MutualActivitiesScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileController()..loadMutualActivities(userId),
      child: _MutualActivitiesView(userId: userId),
    );
  }
}

class _MutualActivitiesView extends StatelessWidget {
  final int userId;
  const _MutualActivitiesView({required this.userId});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProfileController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
        ),
        title: Text(
          'Mutual Activities',
          style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(child: _buildBody(context, ctrl)),
    );
  }

  Widget _buildBody(BuildContext context, ProfileController ctrl) {
    if (ctrl.isLoading && ctrl.mutualActivities == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (ctrl.error != null && ctrl.mutualActivities == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ctrl.error!, textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ctrl.loadMutualActivities(userId),
                child: Text('Retry',
                    style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    final activities = ctrl.mutualActivities ?? const [];

    if (activities.isEmpty) {
      return Center(
        child: ProfileEmptyState(
          icon: Icons.groups_2_rounded,
          title: 'No mutual activities yet',
          subtitle: 'Once you both join the same activity, it will show up here.',
          actionLabel: 'Explore Activities',
          onAction: () => context.push(AppRoutes.seeAllActivities),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ctrl.loadMutualActivities(userId),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => _MutualActivityCard(activity: activities[i]),
      ),
    );
  }
}

class _MutualActivityCard extends StatelessWidget {
  final ActivityCardModel activity;
  const _MutualActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: activity.imageUrl != null && activity.imageUrl!.isNotEmpty
                    ? Image.network(activity.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              if (activity.matchPercent != null)
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${activity.matchPercent}% Compatible',
                        style: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.calendar_today_rounded, text: '${activity.date} · ${activity.time}'),
                const SizedBox(height: 4),
                _InfoRow(icon: Icons.location_on_rounded, text: activity.location),
                const SizedBox(height: 4),
                _InfoRow(icon: Icons.groups_rounded, text: '${activity.memberCount} joined'),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push(AppRoutes.activityDetail, extra: activity.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: Text('View Activity',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF4A7A5A), Color(0xFF1A3D28)],
      ),
    ),
    child: const Icon(Icons.landscape_rounded, color: Colors.white24, size: 48),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}