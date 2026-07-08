import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/gradient_background.dart';

class FindingRoommateScreen extends StatefulWidget {
  const FindingRoommateScreen({super.key});

  @override
  State<FindingRoommateScreen> createState() => _FindingRoommateScreenState();
}

class _FindingRoommateScreenState extends State<FindingRoommateScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _run();
  }

  Future<void> _run() async {
    final ctrl = context.read<RoommateQuizController>();
    final success = await ctrl.submitQuiz();

    if (!mounted) return;

    if (!success) {
      // Same pattern as FindingTribeLoadingScreen: show the error and let
      // the user retry instead of silently pretending it worked. Do NOT
      // navigate away on failure.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ctrl.submitError ?? 'Failed to save your roommate profile.'),
          action: SnackBarAction(label: 'Retry', onPressed: _run),
        ),
      );
      return;
    }

    // Profile saved — now fetch real matches before landing on the home
    // screen, so it renders with data already available.
    await ctrl.fetchMatches();
    if (!mounted) return;

    setState(() => _isComplete = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    GoRouter.of(context).go(AppRoutes.roommateHome);
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
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (_pulseController.value * 0.12);
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
                      child: Icon(
                        _isComplete ? Icons.check_rounded : Icons.groups_2_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    _isComplete ? 'Matches ready! 🎉' : 'Finding your roommates...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Comparing your answers against nearby profiles',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 40),
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