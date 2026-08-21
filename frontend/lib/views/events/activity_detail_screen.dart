import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/current_user_controller.dart';
import '../../controllers/home_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/activity_model.dart';
import '../../services/weather_service.dart';
import '../../widgets/tribal_bottom_nav.dart';
import '../../widgets/user_avatar.dart';

class ActivityDetailScreen extends StatefulWidget {
  final int activityId;
  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().loadActivityDetail(widget.activityId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, ctrl, _) {
        final activity = ctrl.activityDetail;
        final currentUserId = context.watch<CurrentUserController>().id;
        final isHost = activity != null && currentUserId != null &&
            activity.host.id.toString() == currentUserId;

        return Scaffold(
          backgroundColor: AppColors.background,
          bottomNavigationBar: activity == null
              ? const TribalBottomNav()
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BottomActions(activity: activity, ctrl: ctrl),
              const TribalBottomNav(),
            ],
          ),
          body: activity == null
              ? ctrl.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ctrl.error ?? 'Failed to load activity.',
                    style: GoogleFonts.poppins(color: Colors.red)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ctrl.loadActivityDetail(widget.activityId),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            ),
          )
              : _ActivityDetailBody(activity: activity, isHost: isHost),
        );
      },
    );
  }
}

class _ActivityDetailBody extends StatelessWidget {
  final ActivityDetailModel activity;
  final bool isHost;

  const _ActivityDetailBody({required this.activity, required this.isHost});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Hero cover image with back + share buttons
        SliverToBoxAdapter(child: _CoverImage(activity: activity, isHost: isHost)),

        // All detail content — a white rounded-top sheet that overlaps
        // the bottom edge of the cover image.
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + weather stub
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            activity.title,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _WeatherBadge(
                          latitude: activity.latitude,
                          longitude: activity.longitude,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(activity.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Host card
                    _HostCard(host: activity.host, matchPercent: activity.matchPercent),
                    const SizedBox(height: 16),

                    // Members row
                    _MembersRow(activity: activity),
                    const SizedBox(height: 16),

                    // Tags
                    _TagsRow(activity: activity),
                    const SizedBox(height: 24),

                    // Divider
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 20),

                    // About section
                    Text('About Activity',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(
                      activity.description.isNotEmpty
                          ? activity.description
                          : 'No description provided.',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.6),
                    ),
                    const SizedBox(height: 24),

                    // Date + Time row
                    Row(
                      children: [
                        Expanded(child: _InfoTile(
                          icon: Icons.calendar_today_rounded,
                          label: 'DATE',
                          value: _formatDate(activity.date),
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _InfoTile(
                          icon: Icons.access_time_rounded,
                          label: 'TIME',
                          value: _formatTime(activity.time),
                        )),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Meeting point map card
                    if (activity.meetingPoint.isNotEmpty)
                      _MeetingPointCard(
                        meetingPoint: activity.meetingPoint,
                        latitude: activity.latitude,
                        longitude: activity.longitude,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String date) {
    // date comes as "2024-10-24" from API
    try {
      final parts = date.split('-');
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[int.parse(parts[1])]} ${parts[2]}, ${parts[0]}';
    } catch (_) {
      return date;
    }
  }

  String _formatTime(String time) {
    // time comes as "06:30:00" from API
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (_) {
      return time;
    }
  }
}

// ── Cover image with back + share ─────────────────────────────────────────────

class _CoverImage extends StatelessWidget {
  final ActivityDetailModel activity;
  final bool isHost;
  const _CoverImage({required this.activity, required this.isHost});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image or gradient fallback
          activity.imageUrl != null && activity.imageUrl!.isNotEmpty
              ? Image.network(activity.imageUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gradientBox())
              : _gradientBox(),

          // Dark overlay at top for icon readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                stops: const [0.0, 0.5],
              ),
            ),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),

          // Share button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: isHost ? 62 : 16,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),

          // Host-only edit/delete menu
          if (isHost)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 18),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'edit') {
                      context.push(AppRoutes.createActivity, extra: activity);
                    } else if (value == 'delete') {
                      _confirmDelete(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_rounded, size: 18, color: AppColors.textPrimary),
                        SizedBox(width: 10),
                        Text('Edit Activity'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Delete Activity', style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this activity?'),
        content: const Text(
          'This will permanently delete the activity for everyone who joined. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final ctrl = context.read<HomeController>();
              final success = await ctrl.deleteActivity(activity.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Activity deleted.')),
                );
                context.pop();
              } else if (context.mounted && ctrl.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ctrl.error!)),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _gradientBox() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF4A7A5A), Color(0xFF1A3D28)],
      ),
    ),
    child: const Icon(Icons.landscape_rounded, color: Colors.white24, size: 100),
  );
}

// ── Weather badge — real-time weather at the activity's coordinates ────────────
// Uses Open-Meteo (free, no API key) keyed to the activity's lat/lng, so the
// same coordinates shown on the meeting-point map drive this too.

class _WeatherBadge extends StatefulWidget {
  final double latitude;
  final double longitude;
  const _WeatherBadge({required this.latitude, required this.longitude});

  @override
  State<_WeatherBadge> createState() => _WeatherBadgeState();
}

class _WeatherBadgeState extends State<_WeatherBadge> {
  late Future<ActivityWeather?> _future;

  @override
  void initState() {
    super.initState();
    _future = (widget.latitude == 0.0 && widget.longitude == 0.0)
        ? Future.value(null)
        : WeatherService.instance.getCurrentWeather(widget.latitude, widget.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ActivityWeather?>(
      future: _future,
      builder: (context, snapshot) {
        final weather = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 10, height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                )
              else
                Text(weather?.icon ?? '☀️', style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                weather != null
                    ? '${weather.temperatureCelsius.round()}°C'
                    : (loading ? '--' : 'N/A'),
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: const Color(0xFFF57F17)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Host card ─────────────────────────────────────────────────────────────────

class _HostCard extends StatelessWidget {
  final ActivityHost host;
  final int? matchPercent;
  const _HostCard({required this.host, this.matchPercent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          UserAvatar(imageUrl: host.profileImage, fullName: host.fullName, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hosted by ${host.fullName}',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                if (host.isVerified)
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: AppColors.primary, size: 13),
                      const SizedBox(width: 3),
                      Text('Verified Host',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.primary)),
                    ],
                  ),
              ],
            ),
          ),
          // Match badge (real ActivityScore from the recommendation engine)
          if (matchPercent != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$matchPercent% Match',
                  style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

// ── Members row ───────────────────────────────────────────────────────────────

class _MembersRow extends StatelessWidget {
  final ActivityDetailModel activity;
  const _MembersRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final shown = activity.recentMembers.take(3).length;
    final extra = activity.memberCount - shown;

    return Row(
      children: [
        // Stacked mini avatars
        SizedBox(
          height: 30,
          width: 30.0 * shown + (extra > 0 ? 30 : 0) - 8.0 * (shown - 1),
          child: Stack(
            children: [
              for (int i = 0; i < shown; i++)
                Positioned(
                  left: i * 22.0,
                  child: UserAvatar(
                    imageUrl: activity.recentMembers[i].profileImage,
                    fullName: activity.recentMembers[i].fullName,
                    radius: 15,
                  ),
                ),
              if (extra > 0)
                Positioned(
                  left: shown * 22.0,
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.surface,
                    child: Text('+$extra',
                        style: GoogleFonts.poppins(
                            fontSize: 8, fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${activity.memberCount} People Joined',
          style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Tags (Women-only, Accessible, Free) ──────────────────────────────────────

class _TagsRow extends StatelessWidget {
  final ActivityDetailModel activity;
  const _TagsRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        if (activity.isWomenOnly) _Tag(label: 'Women-only 👩', icon: Icons.female_rounded),
        if (activity.isAccessible) _Tag(label: 'Accessible ♿', icon: Icons.accessible_rounded),
        if (activity.isFree) _Tag(label: 'Free', icon: Icons.attach_money_rounded),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Tag({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
    );
  }
}

// ── Date / Time info tile ─────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Meeting point card ────────────────────────────────────────────────────────

class _MeetingPointCard extends StatelessWidget {
  final String meetingPoint;
  final double latitude;
  final double longitude;
  const _MeetingPointCard({
    required this.meetingPoint,
    required this.latitude,
    required this.longitude,
  });

  String? _staticMapUrl() {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || (latitude == 0.0 && longitude == 0.0)) {
      return null;
    }
    final center = '$latitude,$longitude';
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$center'
        '&zoom=15'
        '&size=600x260'
        '&scale=2'
        '&maptype=roadmap'
        '&markers=color:0x6A1A12%7C$center'
        '&key=$apiKey';
  }

  @override
  Widget build(BuildContext context) {
    final mapUrl = _staticMapUrl();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 130,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Map or plain fallback
            mapUrl != null
                ? Image.network(
              mapUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _mapFallback(),
            )
                : _mapFallback(),

            // Meeting point label overlay (bottom-left)
            Positioned(
              left: 10, right: 10, bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_pin, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Meeting point: $meetingPoint',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapFallback() => Container(
    color: const Color(0xFFEEF2F5),
    child: const Icon(Icons.map_rounded, color: AppColors.textSecondary, size: 40),
  );
}

// ── Bottom action buttons ─────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final ActivityDetailModel activity;
  final HomeController ctrl;
  const _BottomActions({required this.activity, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Join / Leave button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: activity.isFull && !activity.hasJoined
                  ? null
                  : () async {
                final ok = await ctrl.toggleJoin(activity.id);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ctrl.error ?? 'Failed.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: activity.hasJoined
                    ? Colors.red.shade700
                    : AppColors.primary,
                disabledBackgroundColor: AppColors.divider,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: ctrl.isJoining
                  ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
                  : Text(
                  activity.isFull && !activity.hasJoined
                      ? 'Activity Full'
                      : activity.hasJoined
                      ? 'Leave Activity'
                      : 'Join Activity',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),

          // Enable Safety Features button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text('Enable Safety Features',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }
}