import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/home_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/activity_model.dart';
import '../../models/profile_model.dart';
import '../../services/location_service.dart';
import '../../controllers/current_user_controller.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/tribal_bottom_nav.dart';
import '../../widgets/safety_feature_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Request GPS permission and save coordinates so the recommendation
      // engine can compute LocationScore for activities and people.
      LocationService.instance.requestAndSave();
      context.read<HomeController>().loadHomeFeed();
      context.read<CurrentUserController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, ctrl, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: ctrl.loadHomeFeed,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _GreetingHeader(ctrl: ctrl)),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  const SliverToBoxAdapter(child: _SearchBarTap()),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  const SliverToBoxAdapter(
                    child: SafetyFeatureButton(),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 28)),

                  if (ctrl.isLoading && ctrl.activities.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )

                  else if (ctrl.error != null && ctrl.activities.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(ctrl.error!, style: GoogleFonts.poppins(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: ctrl.loadHomeFeed,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                      SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: 'People You Might Vibe With',
                          onSeeAll: () => context.push(AppRoutes.seeAllPeople),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),
                      SliverToBoxAdapter(
                        child: ctrl.people.isEmpty
                            ? _EmptyHint(text: 'No people to show yet.')
                            : _PeopleList(people: ctrl.people),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: 'Activities Near You',
                          onSeeAll: () => context.push(AppRoutes.seeAllActivities),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),
                      SliverToBoxAdapter(
                        child: ctrl.activities.isEmpty
                            ? _EmptyHint(text: 'No activities yet. Create one!')
                            : _ActivitiesList(activities: ctrl.activities),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push(AppRoutes.createActivity),
            backgroundColor: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 4,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: const TribalBottomNav(),
        );
      },
    );
  }
}

// =============================================================================
// Greeting Header
// =============================================================================

class _GreetingHeader extends StatelessWidget {
  final HomeController ctrl;

  const _GreetingHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<CurrentUserController>();
    final userName = currentUser.fullName?.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push(AppRoutes.tribeStatus),
            child: Hero(
              tag: 'my-avatar',
              child: UserAvatar.me(radius: 24),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                Text(
                  userName != null && userName.isNotEmpty
                      ? 'Hey, $userName 👋'
                      : 'Hey 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Bell with unread badge
          GestureDetector(
            onTap: () => context.push(AppRoutes.notifications),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),

                if (ctrl.unreadNotifications > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        ctrl.unreadNotifications > 9
                            ? '9+'
                            : '${ctrl.unreadNotifications}',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Search Bar (tappable — navigates to search screen)
// =============================================================================

class _SearchBarTap extends StatelessWidget {
  const _SearchBarTap();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.search),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Find activities or people...',
                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint)),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 14),
                    const SizedBox(width: 3),
                    Text('KTM',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Section Header
// =============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          GestureDetector(
            onTap: onSeeAll,
            child: Text('See all',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// People List
// =============================================================================

class _PeopleList extends StatelessWidget {
  final List<PersonMatchModel> people;
  const _PeopleList({required this.people});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: people.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _PersonCard(person: people[i]),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final PersonMatchModel person;
  const _PersonCard({required this.person});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.otherUserProfilePath(person.id),
        extra: OtherProfileNavArgs(fallbackMatchPercent: person.matchPercent),
      ),
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                UserAvatar(imageUrl: person.profileImage, fullName: person.fullName, radius: 30),
                Positioned(
                  bottom: -10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                        person.matchPercent != null
                            ? '${person.matchPercent}% match'
                            : 'Vibe ✨',
                        style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(person.fullName,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
            child: Wrap(
              spacing: 4, runSpacing: 4, alignment: WrapAlignment.center,
              children: person.interests.take(2)
                  .map((i) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                child: Text(i,
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              ))
                  .toList(),
            ),
            )
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Activities List
// =============================================================================

class _ActivitiesList extends StatelessWidget {
  final List<ActivityCardModel> activities;
  const _ActivitiesList({required this.activities});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: activities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _ActivityCardWidget(activity: activities[i]),
      ),
    );
  }
}

class _ActivityCardWidget extends StatelessWidget {
  final ActivityCardModel activity;
  const _ActivityCardWidget({required this.activity});

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.72;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.activityDetail, extra: activity.id),
      child: Container(
        width: cardWidth,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: AppColors.surface),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            activity.imageUrl != null && activity.imageUrl!.isNotEmpty
                ? Image.network(activity.imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _PlaceholderBg())
                : _PlaceholderBg(),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Distance pill
            Positioned(
              top: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      activity.distanceKm != null ? '${activity.distanceKm} km' : activity.location,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom content
            Positioned(
              left: 12, right: 12, bottom: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StackedAvatars(count: activity.memberCount),
                        const SizedBox(height: 6),
                        Text(activity.title,
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (activity.matchPercent != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 13),
                          const SizedBox(width: 3),
                          Text('${activity.matchPercent}% Match',
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF4A7A5A), Color(0xFF1A3D28)],
      ),
    ),
    child: const Icon(Icons.landscape_rounded, color: Colors.white24, size: 80),
  );
}

class _StackedAvatars extends StatelessWidget {
  final int count;
  const _StackedAvatars({required this.count});

  @override
  Widget build(BuildContext context) {
    const avatarSize = 26.0;
    const overlap = 10.0;
    final shown = count.clamp(0, 3);
    final extra = count - shown;

    return SizedBox(
      height: avatarSize,
      width: avatarSize * (shown + (extra > 0 ? 1 : 0)) - overlap * shown + 10,
      child: Stack(
        children: [
          for (int i = 0; i < shown; i++)
            Positioned(
              left: i * (avatarSize - overlap),
              child: CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor: Colors.grey[300 + (i * 100 > 300 ? 300 : i * 100)],
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 14),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown * (avatarSize - overlap),
              child: CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor: AppColors.surface,
                child: Text('+$extra',
                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Text(text, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
  );
}