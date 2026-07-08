import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/roommate_match_card.dart';
import '../../widgets/tribal_bottom_nav.dart';

/// The "Find a Roommate" tab. Cards are populated from
/// `GET /api/roommate/find/` via [RoommateQuizController.matches].
class RoommateHomeScreen extends StatefulWidget {
  const RoommateHomeScreen({super.key});

  @override
  State<RoommateHomeScreen> createState() => _RoommateHomeScreenState();
}

class _RoommateHomeScreenState extends State<RoommateHomeScreen> {
  @override
  void initState() {
    super.initState();
    // If this screen is opened directly (bottom-nav tap) with no matches
    // cached yet in this shell session — e.g. the user already has a
    // roommate profile from before — fetch them now instead of showing
    // an empty screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = context.read<RoommateQuizController>();
      if (ctrl.matches.isEmpty && !ctrl.isLoadingMatches && ctrl.matchesError == null) {
        ctrl.fetchMatches();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoommateQuizController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const TribalBottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Find a Roommate', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                    child: const Icon(Icons.tune_rounded, color: AppColors.textPrimary, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => context.push(AppRoutes.roommateIntro),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Take Compatibility Quiz', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text('Improve your match accuracy', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.85))),
                          ],
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _buildMatchesSection(ctrl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchesSection(RoommateQuizController ctrl) {
    if (ctrl.isLoadingMatches) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (ctrl.matchesError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Text(
              ctrl.matchesError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: ctrl.fetchMatches,
              child: Text('Retry', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    if (ctrl.matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          'No matches yet — take the compatibility quiz to get started.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        for (final match in ctrl.matches) ...[
          RoommateMatchCard(
            name: match.displayName,
            tags: match.displayTags,
            compatibility: match.score,
            dealBreaker: match.dealBreaker,
            onChatTap: () {}, // TODO: wire to chat once a chat-with-user route exists
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}