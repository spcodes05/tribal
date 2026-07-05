import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

/// Closes the gap between "account created" and "email verified".
///
/// Previously, [AuthController.register] and [AuthService.verifyEmail]
/// both existed but nothing in the UI ever called the latter — so every
/// new signup was permanently stuck behind the backend's
/// `is_email_verified` gate with no way to clear it.
///
/// This screen lets the user either:
///   1. Paste the token from the verification link, or
///   2. Ask the backend to send (or re-send) that link.
///
/// In local dev (console email backend), the link is printed to the
/// Django server terminal — copy the `token=` value from the URL and
/// paste it below.
class VerifyEmailScreen extends StatelessWidget {
  /// The email just used to register (or previously logged in with),
  /// passed via the `?email=` query param since this screen creates its
  /// own [AuthController] instance and can't see the signup screen's one.
  final String? initialEmail;

  const VerifyEmailScreen({super.key, this.initialEmail});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: _VerifyEmailView(initialEmail: initialEmail),
    );
  }
}

class _VerifyEmailView extends StatefulWidget {
  final String? initialEmail;

  const _VerifyEmailView({this.initialEmail});

  @override
  State<_VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<_VerifyEmailView> {
  final _tokenController = TextEditingController();
  late final TextEditingController _emailController =
      TextEditingController(text: widget.initialEmail ?? '');
  String? _infoMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AuthController>();
    final isLoading = ctrl.status == AuthStatus.loading;
    final knownEmail = ctrl.pendingVerificationEmail ?? widget.initialEmail;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.mark_email_unread_outlined,
                size: 56, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              'Verify your email',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              knownEmail != null
                  ? "We've sent a verification link to $knownEmail. "
                      "Open it on this device, or paste the token from the link below."
                  : "Enter the email you signed up with to get a verification link, "
                      "then paste the token from that link below.",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 28),

            // ── Paste token & verify ─────────────────────────────
            CustomTextField(
              controller: _tokenController,
              label: 'Verification token',
              hintText: 'Paste the token from the link (after ?token=)',
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 14),
            CustomButton(
              label: 'Verify',
              isLoading: isLoading,
              onTap: () async {
                final token = _tokenController.text.trim();
                if (token.isEmpty) {
                  setState(() => _infoMessage = 'Paste a token first.');
                  return;
                }
                setState(() => _infoMessage = null);
                final success = await ctrl.verifyEmail(token);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email verified! Continuing setup…'),
                    ),
                  );
                  context.pushReplacement(AppRoutes.phoneVerification);
                }
              },
            ),

            const SizedBox(height: 32),
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.divider)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "Didn't get it?",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.divider)),
              ],
            ),
            const SizedBox(height: 20),

            // ── Resend ─────────────────────────────────────────
            CustomTextField(
              controller: _emailController,
              label: 'Email address',
              hintText: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            CustomButton(
              label: 'Resend verification email',
              isLoading: isLoading,
              backgroundColor: AppColors.surface,
              textColor: AppColors.primary,
              onTap: () async {
                final email = _emailController.text.trim();
                if (email.isEmpty) {
                  setState(() => _infoMessage = 'Enter an email first.');
                  return;
                }
                final success = await ctrl.resendVerification(email);
                if (context.mounted) {
                  setState(() {
                    _infoMessage = success
                        ? 'If that email is registered, a new link was just sent.'
                        : ctrl.errorMessage;
                  });
                }
              },
            ),

            if (_infoMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _infoMessage!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            if (ctrl.status == AuthStatus.error &&
                _infoMessage == null &&
                ctrl.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                ctrl.errorMessage!,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
