import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/current_user_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/activity_model.dart';
import '../../models/profile_model.dart';
import '../../widgets/profile/profile_shared_widgets.dart';
import '../../widgets/user_avatar.dart';

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
              GestureDetector(
                onTap: () => _showPhotoOptionsSheet(context, ctrl, status.profile),
                child: Hero(
                  tag: 'my-avatar',
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      UserAvatar.me(radius: 38),
                      if (ctrl.isUploadingImage)
                        Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                          child: const Center(
                            child: SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: -2, right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
              TribeStatTile(icon: Icons.groups_rounded, label: 'Activities\nJoined', value: status.stats.activitiesJoined),
              TribeStatTile(icon: Icons.campaign_rounded, label: 'Events\nHosted', value: status.stats.eventsHosted),
              TribeStatTile(icon: Icons.home_work_rounded, label: 'Roommate\nMatches', value: status.stats.roommateMatches),
              TribeStatTile(icon: Icons.diversity_3_rounded, label: 'People\nMet', value: status.stats.peopleMet),
              TribeStatTile(icon: Icons.local_fire_department_rounded, label: 'Chat\nStreak', value: status.stats.chatStreak),
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

/// Bottom sheet opened by tapping the avatar — Take Photo / Choose From
/// Gallery / Remove Photo (only if a photo exists) / Cancel. Matches the
/// same rounded-sheet style already used by ChatScreen's menu sheet.
void _showPhotoOptionsSheet(BuildContext context, ProfileController ctrl, ProfileCore profile) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: AppColors.textPrimary),
            title: Text('Take Photo', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _pickAndUpload(context, ctrl, ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.textPrimary),
            title: Text('Choose From Gallery', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _pickAndUpload(context, ctrl, ImageSource.gallery);
            },
          ),
          if (profile.profileImage != null)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: Text('Remove Photo',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.redAccent)),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final ok = await ctrl.removeProfileImage();
                if (!context.mounted) return;
                if (ok) {
                  context.read<CurrentUserController>().updateProfile(
                    fullName: profile.fullName,
                    profileImage: null,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ctrl.error ?? 'Could not remove photo.')),
                  );
                }
              },
            ),
          ListTile(
            leading: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
            title: Text('Cancel',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            onTap: () => Navigator.of(sheetContext).pop(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Take Photo / Choose From Gallery -> pick -> upload -> refresh Tribe
/// Status in place. On failure, shows a snackbar with a Retry action that
/// re-runs the exact same pick (per the "Retry should work" requirement).
Future<void> _pickAndUpload(BuildContext context, ProfileController ctrl, ImageSource source) async {
  final picker = ImagePicker();
  XFile? picked;
  try {
    picked = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(source == ImageSource.camera
            ? 'Could not access the camera.'
            : 'Could not access the gallery.'),
      ),
    );
    return;
  }

  if (picked == null) return; // user cancelled the picker — no-op

  final ok = await ctrl.uploadProfileImage(File(picked.path));
  if (!context.mounted) return;
  if (ok) {
    final updated = ctrl.tribeStatus?.profile;
    if (updated != null) {
      context.read<CurrentUserController>().updateProfile(
        fullName: updated.fullName,
        profileImage: updated.profileImage,
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ctrl.error ?? 'Could not upload photo.'),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _pickAndUpload(context, ctrl, source),
        ),
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