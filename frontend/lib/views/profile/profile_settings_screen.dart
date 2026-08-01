import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/profile_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

/// No settings screen existed in the project before this — built fresh
/// using the existing design language (inputFill/inputBorder text fields,
/// CustomButton, 30px pill radius).
class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileController(),
      child: const _ProfileSettingsView(),
    );
  }
}

class _ProfileSettingsView extends StatefulWidget {
  const _ProfileSettingsView();

  @override
  State<_ProfileSettingsView> createState() => _ProfileSettingsViewState();
}

class _ProfileSettingsViewState extends State<_ProfileSettingsView> {
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _universityCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  bool _isLoadingUser = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final UserModel me = await AuthService.instance.getCurrentUser();
      _usernameCtrl.text = me.username ?? '';
      _bioCtrl.text = me.bio ?? '';
      _ageCtrl.text = me.age?.toString() ?? '';
      _occupationCtrl.text = me.occupation ?? '';
      _universityCtrl.text = me.university ?? '';
      _locationCtrl.text = me.location ?? '';
    } catch (_) {
      _loadError = 'Could not load your profile.';
    } finally {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _ageCtrl.dispose();
    _occupationCtrl.dispose();
    _universityCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final ctrl = context.read<ProfileController>();
    final data = <String, dynamic>{
      'username': _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'age': int.tryParse(_ageCtrl.text.trim()),
      'occupation': _occupationCtrl.text.trim(),
      'university': _universityCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
    };
    final ok = await ctrl.updateProfile(data);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ctrl.error ?? 'Could not save changes.')),
      );
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProfileController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
        ),
        title: Text('Profile Settings',
            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: _isLoadingUser
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (_loadError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_loadError!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent)),
              ),
            _Field(label: 'Username', controller: _usernameCtrl, hint: 'e.g. sampada_r'),
            const SizedBox(height: 16),
            _Field(label: 'Bio', controller: _bioCtrl, hint: 'Tell your tribe about yourself', maxLines: 3),
            const SizedBox(height: 16),
            _Field(label: 'Age', controller: _ageCtrl, hint: 'e.g. 21', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _Field(label: 'Occupation', controller: _occupationCtrl, hint: 'e.g. Student'),
            const SizedBox(height: 16),
            _Field(label: 'University', controller: _universityCtrl, hint: 'e.g. Kathmandu Engineering College'),
            const SizedBox(height: 16),
            _Field(label: 'Location', controller: _locationCtrl, hint: 'e.g. Kathmandu, Nepal'),
            const SizedBox(height: 28),
            CustomButton(label: 'Save Changes', isLoading: ctrl.isSaving, onTap: _handleSave),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _handleLogout,
                child: Text('Log Out', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.redAccent)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}