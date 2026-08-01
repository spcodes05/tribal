import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/home_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/activity_model.dart';
import '../../models/profile_model.dart';
import '../../widgets/tribal_bottom_nav.dart';

/// Shared "See All" screen — shows either all activities or all people
/// depending on the [mode] arg passed via GoRouter extra.
class SeeAllScreen extends StatelessWidget {
  final SeeAllMode mode;
  const SeeAllScreen({super.key, required this.mode});

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
          title: Text(
            mode == SeeAllMode.activities
                ? 'All Activities'
                : 'People You Might Vibe With',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          centerTitle: true,
        ),
        body: mode == SeeAllMode.activities
            ? _AllActivities(activities: ctrl.activities)
            : _AllPeople(people: ctrl.people),
      ),
    );
  }
}

enum SeeAllMode { activities, people }

// ── All Activities ─────────────────────────────────────────────────────────────

class _AllActivities extends StatelessWidget {
  final List<ActivityCardModel> activities;
  const _AllActivities({required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Center(
        child: Text('No activities yet. Be the first to create one!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _ActivityListCard(activity: activities[i]),
    );
  }
}

class _ActivityListCard extends StatelessWidget {
  final ActivityCardModel activity;
  const _ActivityListCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.activityDetail, extra: activity.id),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.surface,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover
            activity.imageUrl != null && activity.imageUrl!.isNotEmpty
                ? Image.network(activity.imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _GradientBg())
                : _GradientBg(),

            // Gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              left: 16, right: 16, bottom: 14, top: 14,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(activity.title,
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: Colors.white),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: Colors.white70, size: 12),
                            const SizedBox(width: 3),
                            Text(activity.location,
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.people_rounded,
                                color: Colors.white70, size: 12),
                            const SizedBox(width: 3),
                            Text('${activity.memberCount} joined',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (activity.matchPercent != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${activity.matchPercent}% Match',
                          style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                ],
              ),
            ),

            // Tags row at bottom
            Positioned(
              left: 16, bottom: 10,
              child: Row(
                children: [
                  if (activity.isFree) _SmallTag('Free'),
                  if (activity.isWomenOnly) _SmallTag('Women-only'),
                  if (activity.isAccessible) _SmallTag('Accessible'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final String label;
  const _SmallTag(this.label);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 6, top: 30),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(label,
        style: GoogleFonts.poppins(fontSize: 9, color: Colors.white,
            fontWeight: FontWeight.w500)),
  );
}

class _GradientBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF4A7A5A), Color(0xFF1A3D28)],
      ),
    ),
  );
}

// ── All People ────────────────────────────────────────────────────────────────

class _AllPeople extends StatelessWidget {
  final List<PersonMatchModel> people;
  const _AllPeople({required this.people});

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return Center(
        child: Text('No people to show yet.',
            style: GoogleFonts.poppins(color: AppColors.textSecondary)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemCount: people.length,
      itemBuilder: (_, i) => _PersonGridCard(person: people[i]),
    );
  }
}

class _PersonGridCard extends StatelessWidget {
  final PersonMatchModel person;
  const _PersonGridCard({required this.person});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.otherUserProfilePath(person.id),
        extra: OtherProfileNavArgs(fallbackMatchPercent: person.matchPercent),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.surface,
                  child: Icon(Icons.person_outline_rounded,
                      color: AppColors.textSecondary, size: 30),
                ),
                Positioned(
                  bottom: -10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                        person.matchPercent != null
                            ? '${person.matchPercent}% match'
                            : 'Vibe ✨',
                        style: GoogleFonts.poppins(
                            fontSize: 9, fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(person.fullName,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4, runSpacing: 4, alignment: WrapAlignment.center,
              children: person.interests.take(2).map((i) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(i,
                    style: GoogleFonts.poppins(
                        fontSize: 10, fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}