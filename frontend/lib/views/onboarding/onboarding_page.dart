import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/onboarding_controller.dart';
import '../../core/constants/app_colors.dart';

/// Renders a single onboarding slide from [OnboardingPageData].
///
/// Layout (top → bottom):
///   - Circular image with icon badge
///   - Title
///   - Description
class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final imageSize = size.width * 0.58;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Circular image with icon badge ──────────────────────────────────
          Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              // White circle border
              Container(
                width: imageSize + 8,
                height: imageSize + 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(
                    child: Image.asset(
                      data.imagePath,
                      width: imageSize,
                      height: imageSize,
                      fit: BoxFit.cover,
                      // Graceful fallback while assets are not yet placed
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryLight,
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.white54,
                          size: imageSize * 0.35,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Icon badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: _BadgeIcon(iconPath: data.iconPath),
                ),
              ),
            ],
          ),

          SizedBox(height: size.height * 0.045),

          // ── Title ────────────────────────────────────────────────────────────
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 12),

          // ── Description ──────────────────────────────────────────────────────
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.85),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge icon inside the circular image overlay.
/// Falls back to a Material icon if the SVG asset isn't placed yet.
class _BadgeIcon extends StatelessWidget {
  final String iconPath;

  const _BadgeIcon({required this.iconPath});

  @override
  Widget build(BuildContext context) {
    // Determine which fallback icon to use based on the path
    IconData fallback = Icons.location_on_outlined;
    if (iconPath.contains('people')) fallback = Icons.people_outline;
    if (iconPath.contains('shield')) fallback = Icons.shield_outlined;

    return Icon(fallback, color: AppColors.primary, size: 22);
  }
}
