import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_strings.dart';

/// Data model for a single onboarding page.
class OnboardingPageData {
  final String title;
  final String description;
  final String imagePath;
  final String iconPath;

  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.iconPath,
  });
}

/// Controller for the onboarding flow.
///
/// Manages current page index, navigation logic, and the
/// "has seen onboarding" preference flag.
class OnboardingController extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  int _currentPage = 0;
  int get currentPage => _currentPage;

  bool get isLastPage => _currentPage == pages.length - 1;

  // ── Page Definitions ───────────────────────────────────────────────────────
  static const List<OnboardingPageData> pages = [
    OnboardingPageData(
      title: AppStrings.onboarding1Title,
      description: AppStrings.onboarding1Desc,
      imagePath: AppAssets.onboarding1,
      iconPath: AppAssets.icLocationPin,
    ),
    OnboardingPageData(
      title: AppStrings.onboarding2Title,
      description: AppStrings.onboarding2Desc,
      imagePath: AppAssets.onboarding2,
      iconPath: AppAssets.icPeople,
    ),
    OnboardingPageData(
      title: AppStrings.onboarding3Title,
      description: AppStrings.onboarding3Desc,
      imagePath: AppAssets.onboarding3,
      iconPath: AppAssets.icShield,
    ),
  ];

  // ── PageController ─────────────────────────────────────────────────────────
  final PageController pageController = PageController();

  // ── Page Events ────────────────────────────────────────────────────────────

  /// Called when the PageView reports a new page index.
  void onPageChanged(int index) {
    _currentPage = index;
    notifyListeners();
  }

  /// Advances to the next onboarding page.
  void nextPage() {
    if (!isLastPage) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  static const String _onboardingSeenKey = 'tribal_onboarding_seen';

  /// Marks onboarding as completed in SharedPreferences.
  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }

  /// Returns true if the user has already seen the onboarding flow.
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
