import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/profile_setup_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/gradient_background.dart';

/// Final "Finding your tribe..." loading state shown after the user taps
/// "Find My Tribe" on [ProfileSetupScreen].
///
/// Submits the collected [OnboardingProfileModel] via
/// [ProfileSetupController.submitProfile] (stubbed) while showing an
/// animated TRIBAL logo and progress indicator.
///
/// NOTE: Per current scope, this screen does NOT navigate to a dashboard —
/// it simply completes the loading animation and stays on screen, ready to
/// be wired to a real destination once the dashboard is built.
class FindingTribeLoadingScreen extends StatefulWidget {
  const FindingTribeLoadingScreen({super.key});

  @override
  State<FindingTribeLoadingScreen> createState() =>
      _FindingTribeLoadingScreenState();
}

class _FindingTribeLoadingScreenState
    extends State<FindingTribeLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _runSubmission();
  }

  Future<void> _runSubmission() async {
    final ctrl = context.read<ProfileSetupController>();
    await ctrl.submitProfile();
    if (mounted) {
      setState(() => _isComplete = true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated pulsing logo
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (_pulseController.value * 0.12);

                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo_white.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Title
                  Text(
                    _isComplete
                        ? 'You found your tribe! 🎉'
                        : AppStrings.findingYourTribe,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    AppStrings.findingYourTribeSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Progress animation
                  if (!_isComplete)
                    SizedBox(
                      width: 160,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          color: Colors.white,
                          minHeight: 5,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
