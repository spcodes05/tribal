import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/onboarding_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/auth_shared_widgets.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/onboarding_indicator.dart';
import 'onboarding_page.dart';

/// The full onboarding screen hosting a PageView of three slides.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingController(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView();

  void _navigateToLogin(BuildContext context) async {
    final ctrl = context.read<OnboardingController>();
    await ctrl.markOnboardingSeen();
    if (context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<OnboardingController>();

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Bar: Logo + Skip ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const TribalLogo(),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.appName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _navigateToLogin(context),
                      child: Text(
                        AppStrings.skip,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Page View ─────────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: ctrl.pageController,
                  onPageChanged: ctrl.onPageChanged,
                  itemCount: OnboardingController.pages.length,
                  itemBuilder: (_, index) => OnboardingPage(
                    data: OnboardingController.pages[index],
                  ),
                ),
              ),

              // ── Bottom: Indicator + Button ────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                child: Column(
                  children: [
                    OnboardingIndicator(
                      pageCount: OnboardingController.pages.length,
                      currentIndex: ctrl.currentPage,
                    ),
                    const SizedBox(height: 24),
                    CustomButtonLight(
                      label: ctrl.isLastPage
                          ? AppStrings.getStarted
                          : AppStrings.next,
                      suffix: const Icon(Icons.arrow_forward, size: 18),
                      onTap: ctrl.isLastPage
                          ? () => _navigateToLogin(context)
                          : ctrl.nextPage,
                    ),
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
