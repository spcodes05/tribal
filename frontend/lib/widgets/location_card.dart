import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/constants/app_colors.dart';

/// "Live Location" card shown inside a chat conversation.
///
/// Reuses the same `google_maps_flutter` package/API-key configuration as
/// the Explore page (see views/explore/explore_screen.dart) — no new key,
/// no new map config. The marker moves as [latitude]/[longitude] change;
/// the caller (MessageBubble, driven by ConversationController) is
/// responsible for passing updated coordinates as WebSocket events arrive,
/// this widget only renders whatever it's given.
class LocationCard extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final VoidCallback? onViewMap;

  const LocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.isActive,
    this.onViewMap,
  });

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  GoogleMapController? _mapController;

  @override
  void didUpdateWidget(covariant LocationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lat = widget.latitude;
    final lng = widget.longitude;
    if (lat == null || lng == null) return;

    final moved = oldWidget.latitude != lat || oldWidget.longitude != lng;
    if (moved && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(lat, lng)),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasCoords = widget.latitude != null && widget.longitude != null;
    final statusLabel = widget.isActive ? 'LIVE' : 'Ended';
    final statusColor =
        widget.isActive ? const Color(0xFF3FCE6B) : AppColors.textSecondary;

    return Container(
      width: 260,
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isActive ? 'Live Location' : 'Live Location Ended',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: widget.isActive ? const Color(0xFF1F8A46) : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: hasCoords
                ? IgnorePointer(
                    // Card map is a preview only — full interaction happens
                    // via onViewMap (tap "View on Map"), same convention as
                    // the previous placeholder implementation.
                    ignoring: true,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(widget.latitude!, widget.longitude!),
                        zoom: 15,
                      ),
                      onMapCreated: (c) => _mapController = c,
                      markers: {
                        Marker(
                          markerId: const MarkerId('live_location'),
                          position: LatLng(widget.latitude!, widget.longitude!),
                        ),
                      },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      liteModeEnabled: true,
                    ),
                  )
                : Container(
                    color: AppColors.surface,
                    alignment: Alignment.center,
                    child: Text(
                      'Waiting for location…',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
          ),
          InkWell(
            onTap: hasCoords ? widget.onViewMap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  widget.isActive ? 'View on Map' : 'Sharing Ended',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.isActive ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
