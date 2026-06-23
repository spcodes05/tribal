import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// TRIBAL logo widget — used on onboarding and auth screens.
/// Falls back to a Material icon if the asset hasn't been placed yet.
class TribalLogo extends StatelessWidget {
  const TribalLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logo,
      width: 60,
      height: 60,
      errorBuilder: (_, __, ___) => Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white24,
        ),
        child: const Icon(Icons.diversity_3, color: Colors.white, size: 18),
      ),
    );
  }
}

/// Gradient header shared by Login and Signup screens.
/// Contains: TRIBAL logo row, title, subtitle, and tab switcher.
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  /// 0 = Log In active, 1 = Sign Up active
  final int activeTab;
  final VoidCallback onTabSwitch;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.activeTab,
    required this.onTabSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo row
              Row(
                children: [
                  const TribalLogo(),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.appName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 4),

              // Subtitle
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 20),

              // Tab switcher
              AuthTabSwitcher(
                activeTab: activeTab,
                onTabSwitch: onTabSwitch,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped Log In / Sign Up tab switcher.
class AuthTabSwitcher extends StatelessWidget {
  final int activeTab;
  final VoidCallback onTabSwitch;

  const AuthTabSwitcher({
    super.key,
    required this.activeTab,
    required this.onTabSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          AuthTabItem(
            label: AppStrings.logIn,
            isActive: activeTab == 0,
            onTap: activeTab == 0 ? null : onTabSwitch,
          ),
          AuthTabItem(
            label: AppStrings.signUp,
            isActive: activeTab == 1,
            onTap: activeTab == 1 ? null : onTabSwitch,
          ),
        ],
      ),
    );
  }
}

/// Single tab item inside [AuthTabSwitcher].
class AuthTabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const AuthTabItem({
    super.key,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.primary : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// "or continue with" divider line.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            AppStrings.orContinueWith,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}
