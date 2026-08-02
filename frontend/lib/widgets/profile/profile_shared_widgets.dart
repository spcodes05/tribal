import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/profile_model.dart';

/// Generic elegant empty state — reused across the profile feature so every
/// "nothing here yet" moment looks consistent instead of a blank screen.
class ProfileEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ProfileEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.textSecondary, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              child: Text(
                actionLabel!,
                style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One tile inside the Tribe Stats grid, with an animated count-up.
class TribeStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const TribeStatTile({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, animatedValue, __) => Text(
              '$animatedValue',
              style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary, height: 1.2),
          ),
        ],
      ),
    );
  }
}

/// One row in the "Recent Activity" timeline — no star ratings, per spec.
class TribeTimelineTile extends StatelessWidget {
  final TimelineEntryModel entry;
  const TribeTimelineTile({super.key, required this.entry});

  IconData get _icon {
    switch (entry.type) {
      case 'hosted_activity':
        return Icons.campaign_rounded;
      case 'roommate_match':
        return Icons.home_work_rounded;
      default:
        return Icons.groups_rounded;
    }
  }

  String get _formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[entry.date.month - 1]} ${entry.date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: entry.imageUrl != null
                ? Image.network(
              entry.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(_icon, color: AppColors.textSecondary, size: 20),
            )
                : Icon(_icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    _formattedDate,
                    if (entry.location != null && entry.location!.isNotEmpty) entry.location!,
                    if (entry.peopleCount != null) '${entry.peopleCount} people',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small earned-achievement chip.
class AchievementChip extends StatelessWidget {
  final String label;
  const AchievementChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryLight, AppColors.primary]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

/// Display-only tag (interests, mutual interests, badges) — distinct from
/// [InterestChip], which is a selectable form control used in onboarding.
class ProfileTag extends StatelessWidget {
  final String label;
  final bool emphasized;
  const ProfileTag({super.key, required this.label, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: emphasized ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: emphasized ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

