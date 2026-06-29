import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/home_models.dart';

/// Home screen for TRIBAL.
///
/// Displays:
///   - Greeting header with notification bell
///   - Search bar with current city tag
///   - "People You Might Vibe With" horizontal list
///   - "Activities Near You" horizontal cards
///   - Bottom navigation bar
///   - Floating "+" action button
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ---------------------------------------------------------------------------
  // Placeholder data — replace with real API calls via a HomeController
  // ---------------------------------------------------------------------------
  static const _people = [
    PersonMatch(
      name: 'Aarav S.',
      matchPercent: 92,
      interests: ['Hiking', 'Coffee'],
    ),
    PersonMatch(
      name: 'Priya M.',
      matchPercent: 88,
      interests: ['Music', 'Yoga'],
    ),
    PersonMatch(
      name: 'Rohan K.',
      matchPercent: 85,
      interests: ['Art', 'Travel'],
    ),
  ];

  static const _activities = [
    ActivityCard(
      title: 'Weekend Shivapuri Hike',
      distanceKm: '4.2',
      matchPercent: 95,
    ),
    ActivityCard(
      title: 'Evening Jazz Night',
      distanceKm: '1.8',
      matchPercent: 89,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GreetingHeader(userName: 'Sampada'),
                    const SizedBox(height: 16),
                    const _SearchBar(city: 'KTM'),
                    const SizedBox(height: 28),
                    _SectionHeader(
                      title: 'People You Might Vibe With',
                      onSeeAll: () {},
                    ),
                    const SizedBox(height: 14),
                    _PeopleList(people: _people),
                    const SizedBox(height: 28),
                    _SectionHeader(
                      title: 'Activities Near You',
                      onSeeAll: () {},
                    ),
                    const SizedBox(height: 14),
                    _ActivitiesList(activities: _activities),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _AddFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

// =============================================================================
// Greeting Header
// =============================================================================

class _GreetingHeader extends StatelessWidget {
  final String userName;

  const _GreetingHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // Avatar
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surface,
            child: Icon(
              Icons.person_outline_rounded,
              color: AppColors.textSecondary,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          // Welcome text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Hey $userName',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Bell icon
          Stack(
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
              // Notification dot
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
        ],
      ),
    );
  }
}

// =============================================================================
// Search Bar
// =============================================================================

class _SearchBar extends StatelessWidget {
  final String city;

  const _SearchBar({required this.city});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
            Icon(
              Icons.search_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Find activities or people...',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
              ),
            ),
            // City tag
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    city,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
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
  final List<PersonMatch> people;

  const _PeopleList({required this.people});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: people.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _PersonCard(person: people[index]),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final PersonMatch person;

  const _PersonCard({required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar + match badge
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.surface,
                child: Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.textSecondary,
                  size: 30,
                ),
              ),
              Positioned(
                bottom: -10,
                child: _MatchBadge(percent: person.matchPercent),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Name
          Text(
            person.name,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Interest chips
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: person.interests
                .map((i) => _SmallChip(label: i))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Dark-red "92% match" badge shown below the avatar.
class _MatchBadge extends StatelessWidget {
  final int percent;

  const _MatchBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$percent% match',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Tiny chip shown under a person's name listing their interests.
class _SmallChip extends StatelessWidget {
  final String label;

  const _SmallChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// =============================================================================
// Activities List
// =============================================================================

class _ActivitiesList extends StatelessWidget {
  final List<ActivityCard> activities;

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
        itemBuilder: (context, index) =>
            _ActivityCardWidget(activity: activities[index]),
      ),
    );
  }
}

class _ActivityCardWidget extends StatelessWidget {
  final ActivityCard activity;

  const _ActivityCardWidget({required this.activity});

  @override
  Widget build(BuildContext context) {
    // Card is roughly 75% of screen width for a peek effect
    final cardWidth = MediaQuery.of(context).size.width * 0.72;

    return Container(
      width: cardWidth,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image or gradient placeholder
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF4A7A5A),
                  const Color(0xFF2E5E40),
                  const Color(0xFF1A3D28),
                ],
              ),
            ),
            child: const Icon(
              Icons.landscape_rounded,
              color: Colors.white24,
              size: 80,
            ),
          ),

          // Overlay gradient for text readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.65),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),

          // Distance pill (top-left)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${activity.distanceKm} km',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom content: avatars + title + match badge
          Positioned(
            left: 12,
            right: 12,
            bottom: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stacked mini avatars
                      _StackedAvatars(),
                      const SizedBox(height: 6),
                      Text(
                        activity.title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Match badge
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.orangeAccent,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${activity.matchPercent}% Match',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
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

/// Three overlapping placeholder avatars shown on the activity card.
class _StackedAvatars extends StatelessWidget {
  const _StackedAvatars();

  @override
  Widget build(BuildContext context) {
    const avatarSize = 26.0;
    const overlap = 10.0;

    return SizedBox(
      height: avatarSize,
      width: avatarSize * 3 - overlap * 2 + 24,
      child: Stack(
        children: [
          for (int i = 0; i < 3; i++)
            Positioned(
              left: i * (avatarSize - overlap),
              child: CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor: Colors.grey[300 + (i * 100)],
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          // "+4" badge
          Positioned(
            left: 3 * (avatarSize - overlap),
            child: CircleAvatar(
              radius: avatarSize / 2,
              backgroundColor: AppColors.surface,
              child: Text(
                '+4',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Floating Action Button
// =============================================================================

class _AddFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {},
      backgroundColor: AppColors.primary,
      shape: const CircleBorder(),
      elevation: 4,
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    );
  }
}

// =============================================================================
// Bottom Navigation Bar
// =============================================================================

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    // Using index 0 (Home) as active by default.
    // Lift state to a controller when wiring up the rest of the app.
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
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: true,
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                label: 'Explore',
                isActive: false,
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
                isActive: false,
              ),
              _NavItem(
                icon: Icons.people_outline_rounded,
                label: 'Roommate',
                isActive: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: color,
          ),
        ),
      ],
    );
  }
}