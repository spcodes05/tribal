import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/auth_shared_widgets.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/social_button.dart';

/// Sign Up screen for TRIBAL.
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatelessWidget {
  const _SignupView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient header — Sign Up tab active
            AuthHeader(
              title: AppStrings.joinTheTribe,
              subtitle: AppStrings.signUpSubtitle,
              activeTab: 1,
              onTabSwitch: () => context.go(AppRoutes.login),
            ),

            // White form section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: const _SignupForm(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignupForm extends StatelessWidget {
  const _SignupForm();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AuthController>();
    final isLoading = ctrl.status == AuthStatus.loading;

    return Form(
      key: ctrl.signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name
          CustomTextField(
            controller: ctrl.signupNameController,
            label: AppStrings.fullName,
            hintText: AppStrings.fullNameHint,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return AppStrings.fieldRequired;
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Email
          CustomTextField(
            controller: ctrl.signupEmailController,
            label: AppStrings.email,
            hintText: AppStrings.emailHint,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return AppStrings.fieldRequired;
              if (!v.contains('@')) return AppStrings.invalidEmail;
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Password
          Consumer<AuthController>(
            builder: (_, c, __) => CustomTextField(
              controller: c.signupPasswordController,
              label: AppStrings.password,
              hintText: AppStrings.passwordHint,
              obscureText: c.obscurePassword,
              textInputAction: TextInputAction.done,
              suffixIcon: IconButton(
                icon: Icon(
                  c.obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: c.togglePasswordVisibility,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                if (v.length < 6) return AppStrings.passwordTooShort;
                return null;
              },
            ),
          ),

          const SizedBox(height: 6),

          // Error message
          if (ctrl.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                ctrl.errorMessage!,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
              ),
            ),

          const SizedBox(height: 10),

          // Create Account button
          CustomButton(
            label: AppStrings.createAccountButton,
            isLoading: isLoading,
            onTap: () async {
              final success = await ctrl.register();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account created! Welcome to the tribe 🎉'),
                  ),
                );
                // Continue into the profile completion flow
                // (Phone Verification -> Gender -> Social -> Profile Setup).
                context.push(AppRoutes.phoneVerification);
              }
            },
          ),

          const SizedBox(height: 20),

          // Divider
          const OrDivider(),

          const SizedBox(height: 16),

          // Social buttons
          Row(
            children: [
              Expanded(
                child: SocialButton(
                  provider: SocialProvider.google,
                  onTap: () => ctrl.signInWithGoogle(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SocialButton(
                  provider: SocialProvider.apple,
                  onTap: () => ctrl.signInWithApple(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Already have account link
          Center(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                children: [
                  const TextSpan(text: AppStrings.alreadyHaveAccount),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: Text(
                        AppStrings.loginLink,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
