import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../controllers/explore_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/activity_model.dart';
import '../../widgets/tribal_bottom_nav.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final MapController _mapController = MapController();
  final _sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreController>().init();
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreController>(
      builder: (context, ctrl, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          bottomNavigationBar: const TribalBottomNav(),
          body: Stack(
            children: [
              // ── Full-screen map ──────────────────────────────────────────
              _MapLayer(
                ctrl: ctrl,
                mapController: _mapController,
              ),

              // ── Top search bar ───────────────────────────────────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16, right: 16,
                child: _SearchBar(),
              ),

              // ── Sliding bottom sheet ─────────────────────────────────────
              _BottomSheet(
                ctrl: ctrl,
                sheetController: _sheetController,
              ),

              // ── Selected pin info card (replaces Google's InfoWindow) ─────
              if (ctrl.selectedPin != null)
                Positioned(
                  left: 16, right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 260,
                  child: _SelectedPinCard(pin: ctrl.selectedPin!),
                ),

              // ── Auto-Match Me FAB ─────────────────────────────────────────
              Positioned(
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 80,
                child: _AutoMatchFab(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// Selected pin info card
// =============================================================================

class _SelectedPinCard extends StatelessWidget {
  final ActivityPinModel pin;
  const _SelectedPinCard({required this.pin});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.activityDetail, extra: pin.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48, height: 48,
                child: pin.imageUrl != null && pin.imageUrl!.isNotEmpty
                    ? Image.network(pin.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.primary.withOpacity(0.15)))
                    : Container(color: AppColors.primary.withOpacity(0.15)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pin.title,
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(pin.pinLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Map layer
// =============================================================================

class _MapLayer extends StatelessWidget {
  final ExploreController ctrl;
  final MapController mapController;

  const _MapLayer({required this.ctrl, required this.mapController});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: ctrl.userLocation,
        initialZoom: 13,
        onTap: (_, __) => ctrl.selectPin(null), // dismiss selected pin
        onMapReady: () {
          // Give the map a moment to settle, then center on the user —
          // mirrors the old GoogleMap "animate to user location" behavior.
          Future.delayed(const Duration(milliseconds: 500), () {
            mapController.move(ctrl.userLocation, 13);
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // Required by OpenStreetMap's usage policy — identifies this app
          // to the tile server, avoids being silently blocked.
          userAgentPackageName: 'com.tribal.app',
        ),
        // My-location marker (blue dot) — no built-in "myLocationEnabled"
        // flag like GoogleMap, so draw it ourselves.
        MarkerLayer(markers: [
          Marker(
            point: ctrl.userLocation,
            width: 20, height: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          ),
        ]),
        // Activity pins
        MarkerLayer(
          markers: ctrl.pins.map((pin) {
            final isSelected = ctrl.selectedPin?.id == pin.id;
            return Marker(
              point: LatLng(pin.latitude, pin.longitude),
              width: 40, height: 40,
              child: GestureDetector(
                onTap: () => ctrl.selectPin(pin),
                child: Icon(
                  Icons.location_on_rounded,
                  color: isSelected ? AppColors.primary : Colors.redAccent,
                  size: isSelected ? 40 : 34,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// =============================================================================
// Search bar
// =============================================================================

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push(AppRoutes.search),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search_rounded,
                      color: AppColors.textHint, size: 20),
                  const SizedBox(width: 8),
                  Text('Search area...',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textHint)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Filter button
        GestureDetector(
          onTap: () => _showFilterSheet(context),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(Icons.tune_rounded,
                color: AppColors.primary, size: 22),
          ),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    final ctrl = context.read<ExploreController>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: ctrl,
        child: const _FilterSheet(),
      ),
    );
  }
}

// =============================================================================
// Filter bottom sheet
// =============================================================================

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreController>(
      builder: (context, ctrl, _) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: () {
                    ctrl.clearFilters();
                    Navigator.pop(context);
                  },
                  child: Text('Clear all',
                      style: GoogleFonts.poppins(
                          color: AppColors.primary, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 4),

            Text('Quick Filters',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _QuickChip(
                  label: 'Free',
                  active: ctrl.filter.isFree,
                  onTap: () { ctrl.toggleFree(); Navigator.pop(context); },
                ),
                _QuickChip(
                  label: 'Women-only',
                  active: ctrl.filter.isWomenOnly,
                  onTap: () { ctrl.toggleWomenOnly(); Navigator.pop(context); },
                ),
                _QuickChip(
                  label: 'This Weekend',
                  active: ctrl.filter.thisWeekend,
                  onTap: () { ctrl.toggleThisWeekend(); Navigator.pop(context); },
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text('By Activity Type',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8, runSpacing: 8,
              children: ctrl.availableTags.map((tag) {
                final active = ctrl.filter.tag == tag;
                return _QuickChip(
                  label: tag,
                  active: active,
                  onTap: () {
                    ctrl.setTagFilter(active ? null : tag);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.inputBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Sliding bottom sheet with filter chips + activity cards
// =============================================================================

class _BottomSheet extends StatelessWidget {
  final ExploreController ctrl;
  final DraggableScrollableController sheetController;

  const _BottomSheet({required this.ctrl, required this.sheetController});

  @override
  Widget build(BuildContext context) {
    final bottomNavHeight = 72.0;
    final screenHeight = MediaQuery.of(context).size.height;

    return DraggableScrollableSheet(
      controller: sheetController,
      initialChildSize: 0.38,
      minChildSize: 0.15,
      maxChildSize: 0.75,
      snap: true,
      snapSizes: const [0.15, 0.38, 0.75],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Filter chips row ─────────────────────────────────────────
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: 'All',
                      active: ctrl.filter.tag == null &&
                          !ctrl.filter.isFree &&
                          !ctrl.filter.isWomenOnly &&
                          !ctrl.filter.thisWeekend,
                      onTap: ctrl.clearFilters,
                    ),
                    ...ctrl.availableTags.take(6).map((tag) => _FilterChip(
                      label: tag,
                      active: ctrl.filter.tag == tag,
                      onTap: () => ctrl.setTagFilter(
                          ctrl.filter.tag == tag ? null : tag),
                    )),
                    _FilterChip(
                      label: 'Free',
                      active: ctrl.filter.isFree,
                      onTap: ctrl.toggleFree,
                    ),
                    _FilterChip(
                      label: 'This Weekend',
                      active: ctrl.filter.thisWeekend,
                      onTap: ctrl.toggleThisWeekend,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Activity cards ───────────────────────────────────────────
              Expanded(
                child: ctrl.isLoading
                    ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                    : ctrl.filteredActivities.isEmpty
                    ? _EmptyState()
                    : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: ctrl.filteredActivities.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _ActivityPinCard(activity: ctrl.filteredActivities[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.inputBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ActivityPinCard extends StatelessWidget {
  final ActivityCardModel activity;
  const _ActivityPinCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.activityDetail, extra: activity.id),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surface,
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          children: [
            // Thumbnail
            SizedBox(
              width: 100,
              child: activity.imageUrl != null && activity.imageUrl!.isNotEmpty
                  ? Image.network(activity.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _GradientThumb())
                  : _GradientThumb(),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      activity.title,
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: AppColors.primary, size: 12),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            activity.location,
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (activity.isFree)
                          _MiniTag('Free', AppColors.primary),
                        if (activity.isWomenOnly)
                          _MiniTag('Women-only', Colors.pink.shade300),
                        _MiniTag(
                          '${activity.memberCount}/${activity.maxMembers}',
                          AppColors.textSecondary,
                        ),
                      ],
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
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniTag(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(label,
        style: GoogleFonts.poppins(
            fontSize: 9, fontWeight: FontWeight.w600, color: color)),
  );
}

class _GradientThumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF4A7A5A), Color(0xFF1A3D28)],
      ),
    ),
    child: const Icon(Icons.landscape_rounded, color: Colors.white24, size: 40),
  );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.explore_outlined, size: 48, color: AppColors.textHint),
        const SizedBox(height: 12),
        Text('No activities found',
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text('Try clearing filters or create one!',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textHint)),
      ],
    ),
  );
}

// =============================================================================
// Auto-Match Me FAB
// =============================================================================

class _AutoMatchFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to home feed which already shows matched activities
        context.go(AppRoutes.home);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Auto-Match Me',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}