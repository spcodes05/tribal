import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/onboarding_profile_model.dart';

/// Returns brand display info (icon + color) for a given [SocialPlatform].
/// Centralised here so the card and any future screens stay consistent.
class _PlatformVisuals {
  final IconData icon;
  final Color brandColor;
  final String label;

  const _PlatformVisuals(this.icon, this.brandColor, this.label);
}

const Map<SocialPlatform, _PlatformVisuals> _platformVisuals = {
  SocialPlatform.instagram: _PlatformVisuals(
      Icons.camera_alt_rounded, Color(0xFFE1306C), 'Instagram'),
  SocialPlatform.linkedin: _PlatformVisuals(
      Icons.work_rounded, Color(0xFF0A66C2), 'LinkedIn'),
  SocialPlatform.facebook: _PlatformVisuals(
      Icons.thumb_up_rounded, Color(0xFF1877F2), 'Facebook'),
  SocialPlatform.github: _PlatformVisuals(
      Icons.code_rounded, Color(0xFF24292E), 'GitHub'),
  SocialPlatform.spotify: _PlatformVisuals(
      Icons.music_note_rounded, Color(0xFF1DB954), 'Spotify'),
};

/// Card representing a single social platform connection in the
/// Social Verification screen.
///
/// Shows a "Connect" button when disconnected, a brief loading state while
/// [isConnecting] is true, and a "Connected" badge once connected.
class SocialPlatformCard extends StatelessWidget {
  final SocialPlatform platform;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onTap;

  const SocialPlatformCard({
    super.key,
    required this.platform,
    required this.isConnected,
    required this.isConnecting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visuals = _platformVisuals[platform]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isConnected
            ? AppColors.primary.withOpacity(0.05)
            : AppColors.inputFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isConnected ? AppColors.primary.withOpacity(0.4) : AppColors.inputBorder,
        ),
      ),
      child: Row(
        children: [
          // Platform icon badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: visuals.brandColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(visuals.icon, color: visuals.brandColor, size: 20),
          ),

          const SizedBox(width: 14),

          // Platform name
          Expanded(
            child: Text(
              visuals.label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Connect / Connected state
          _TrailingAction(
            isConnected: isConnected,
            isConnecting: isConnecting,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _TrailingAction extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onTap;

  const _TrailingAction({
    required this.isConnected,
    required this.isConnecting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isConnecting) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }

    if (isConnected) {
      return GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 16),
            const SizedBox(width: 4),
            Text(
              'Connected',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Connect',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
