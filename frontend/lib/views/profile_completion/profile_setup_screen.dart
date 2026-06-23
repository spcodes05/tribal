import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controllers/profile_setup_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../models/onboarding_profile_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/interest_chip.dart';
import '../../widgets/profile_flow_header.dart';

/// Step 4 of 4 — Profile Setup.
///
/// Final step before the "Finding your tribe..." loading state. Collects
/// profile picture, "About Me" bio, and interests — all of which feed the
/// Smart Matching Algorithm's interest/tag scoring (proposal Section 3.3.1).
class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProfileSetupController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileFlowHeader(
              currentStep: 4,
              totalSteps: 4,
              title: AppStrings.profileSetupTitle,
              subtitle: AppStrings.profileSetupSubtitle,
              onBack: () => context.pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile Picture ──────────────────────────────────────
                  const Center(child: _AvatarPicker()),

                  const SizedBox(height: 32),

                  // ── About Me ──────────────────────────────────────────────
                  Text(
                    AppStrings.aboutMeLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _AboutMeField(),

                  const SizedBox(height: 28),

                  // ── Interests ─────────────────────────────────────────────
                  Text(
                    AppStrings.interestsLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kAvailableInterests.map((interest) {
                      return InterestChip(
                        label: interest,
                        isSelected: ctrl.isInterestSelected(interest),
                        onTap: () => ctrl.toggleInterest(interest),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 40),

                  // ── Find My Tribe CTA ────────────────────────────────────
                  CustomButton(
                    label: AppStrings.findMyTribe,
                    suffix: const Icon(Icons.diversity_3_rounded, size: 18),
                    onTap: ctrl.canFindTribe
                        ? () => context.push(AppRoutes.findingTribe)
                        : null,
                  ),

                  if (!ctrl.canFindTribe)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Select at least one interest to continue',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular avatar picker with camera overlay icon.
/// Uses [ImagePicker] to select from gallery; "Skip" simply leaves it empty.
class _AvatarPicker extends StatefulWidget {
  const _AvatarPicker();

  @override
  State<_AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<_AvatarPicker> {
  Future<void> _pickImage(BuildContext context) async {
    final ctrl = context.read<ProfileSetupController>();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        ctrl.setProfileImage(picked.path);
      }
    } catch (_) {
      // Picker not available on this platform/build — fail silently,
      // user can still proceed without a profile picture.
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProfileSetupController>();
    final imagePath = ctrl.profileImagePath;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.inputFill,
                border: Border.all(color: AppColors.inputBorder),
                image: imagePath != null
                    ? DecorationImage(
                  image: FileImage(File(imagePath)),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: imagePath == null
                  ? const Icon(
                Icons.person_outline_rounded,
                size: 48,
                color: AppColors.textHint,
              )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _pickImage(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (imagePath == null)
          Text(
            AppStrings.skipForNow,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

/// Multiline "About Me" field with a live character counter (max 150).
class _AboutMeField extends StatelessWidget {
  const _AboutMeField();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProfileSetupController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: ctrl.aboutMeController,
          maxLength: ProfileSetupController.aboutMeMaxLength,
          maxLines: 4,
          onChanged: ctrl.onAboutMeChanged,
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: AppStrings.aboutMeHint,
            counterText: '',
            contentPadding: const EdgeInsets.all(16),
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textHint,
              height: 1.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 4),
          child: Text(
            '${ctrl.aboutMeController.text.length}/${ProfileSetupController.aboutMeMaxLength}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }
}
