import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/profile_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/activity_model.dart';
import '../../widgets/profile/profile_shared_widgets.dart';

/// FEATURE 1 — "Your Tribe Status"
/// Opened from the Home page profile avatar. Matches the existing Tribal
/// design language (maroon primary, 20px card radius, Poppins) rather than
/// copying the reference mockup — no star ratings, real stats only.
class TribeStatusScreen extends StatelessWidget {
  const TribeStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileController()..loadTribeStatus(),
      child: const _TribeStatusView(),
    );
  }
}

class _TribeStatusView extends StatelessWidget {
  const _TribeStatusView();

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
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
        ),
        title: Text(
          'Your Tribe Status',
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.profileSettings),
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(context, ctrl),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProfileController ctrl) {
    if (ctrl.isLoading && ctrl.tribeStatus == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (ctrl.error != null && ctrl.tribeStatus == null) {
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
                onPressed: ctrl.loadTribeStatus,
                child: Text('Retry', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    final status = ctrl.tribeStatus!;
    final upcoming = ctrl.upcomingActivity;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: ctrl.loadTribeStatus,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ── Profile section ────────────────────────────────────────────
          Row(
            children: [
              ProfileAvatar(imageUrl: status.profile.profileImage, initials: status.profile.initials, radius: 38),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status.profile.fullName,
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    if (status.profile.username != null)
                      Text('@${status.profile.username}',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text(
                      status.profile.bio ?? 'No bio yet',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: status.profile.bio != null ? AppColors.textPrimary : AppColors.textHint,
                        fontStyle: status.profile.bio != null ? FontStyle.normal : FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Tribe Stats ────────────────────────────────────────────────
          Text('Tribe Stats',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              TribeStatTile(icon: Icons.groups_rounded, label: 'Activities \n Joined', value: status.stats.activitiesJoined),
              TribeStatTile(icon: Icons.campaign_rounded, label: 'Events \n Hosted', value: status.stats.eventsHosted),
              TribeStatTile(icon: Icons.home_work_rounded, label: 'Roommate \n Matches', value: status.stats.roommateMatches),
              TribeStatTile(icon: Icons.diversity_3_rounded, label: 'People \n Met', value: status.stats.peopleMet),
              TribeStatTile(icon: Icons.local_fire_department_rounded, label: 'Chat Streak', value: status.stats.chatStreak),
            ],
          ),

          const SizedBox(height: 28),

          // ── Upcoming Activity ─────────────────────────────────────────
          Text('Upcoming Activity',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          upcoming != null
              ? _UpcomingActivityCard(activity: upcoming)
              : Container(
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
            child: ProfileEmptyState(
              icon: Icons.event_available_rounded,
              title: 'No upcoming activities yet',
              subtitle: 'Find something your tribe is doing this week.',
              actionLabel: 'Explore Activities',
              // The dedicated "Explore" tab isn't built yet (see
              // TribalBottomNav) — this routes to the closest
              // implemented equivalent instead of a dead link.
              onAction: () => context.push(AppRoutes.seeAllActivities),
            ),
          ),

          const SizedBox(height: 28),

          // ── Recent Activity (timeline, no star ratings) ───────────────
          Text('Recent Activity',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          status.recentTimeline.isEmpty
              ? ProfileEmptyState(icon: Icons.history_rounded, title: 'Nothing here yet', subtitle: 'Your activity will show up here.')
              : Column(children: status.recentTimeline.map((e) => TribeTimelineTile(entry: e)).toList()),

          // ── Achievements (only shown if the user has earned any) ──────
          if (status.achievements.any((a) => a.earned)) ...[
            const SizedBox(height: 28),
            Text('Achievements',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: status.achievements
                  .where((a) => a.earned)
                  .map((a) => AchievementChip(label: a.label))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpcomingActivityCard extends StatelessWidget {
  final ActivityCardModel activity;
  const _UpcomingActivityCard({required this.activity});

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
          SizedBox(
            height: 130,
            width: double.infinity,
            child: activity.imageUrl != null && activity.imageUrl!.isNotEmpty
                ? Image.network(activity.imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.calendar_today_rounded, text: '${activity.date} · ${activity.time}'),
                const SizedBox(height: 4),
                _InfoRow(icon: Icons.location_on_rounded, text: activity.location),
                const SizedBox(height: 4),
                _InfoRow(
                  icon: Icons.groups_rounded,
                  text: '${activity.memberCount} going${activity.isFull ? ' · Full' : ''}',
                ),
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
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
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
    child: const Icon(Icons.landscape_rounded, color: Colors.white24, size: 60),
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