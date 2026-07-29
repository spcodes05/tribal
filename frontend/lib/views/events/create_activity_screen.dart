import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/home_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../services/events_service.dart';
import '../../widgets/custom_button.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _meetingPointController = TextEditingController();
  final _maxMembersController = TextEditingController(text: '20');
  final _imageUrlController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  bool _isWomenOnly = false;
  bool _isAccessible = false;
  bool _isFree = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingPointController.dispose();
    _maxMembersController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String get _formattedDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';
  }

  String get _formattedTime {
    final hour = _selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod;
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ctrl = context.read<HomeController>();
    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': _locationController.text.trim(),
      'meeting_point': _meetingPointController.text.trim(),
      'date': '${_selectedDate.year}-'
          '${_selectedDate.month.toString().padLeft(2, '0')}-'
          '${_selectedDate.day.toString().padLeft(2, '0')}',
      'time': '${_selectedTime.hour.toString().padLeft(2, '0')}:'
          '${_selectedTime.minute.toString().padLeft(2, '0')}:00',
      'is_women_only': _isWomenOnly,
      'is_accessible': _isAccessible,
      'is_free': _isFree,
      'max_members': int.tryParse(_maxMembersController.text) ?? 20,
      if (_imageUrlController.text.trim().isNotEmpty)
        'image_url': _imageUrlController.text.trim(),
    };

    final created = await ctrl.createActivity(data);
    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity created! 🎉')),
      );
      context.pop();
    } else if (mounted && ctrl.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ctrl.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, ctrl, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
          title: Text('Create Activity',
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Title ──────────────────────────────────────────────────────
              _FieldLabel('Activity Title'),
              _FormField(
                controller: _titleController,
                hint: 'e.g. Weekend Shivapuri Hike',
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 18),

              // ── Description ────────────────────────────────────────────────
              _FieldLabel('Description'),
              _FormField(
                controller: _descriptionController,
                hint: 'Tell people what this activity is about...',
                maxLines: 4,
              ),
              const SizedBox(height: 18),

              // ── Location ───────────────────────────────────────────────────
              _FieldLabel('Location'),
              _FormField(
                controller: _locationController,
                hint: 'e.g. Shivapuri, Nepal',
                prefixIcon: Icons.location_on_rounded,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 18),

              // ── Meeting Point ──────────────────────────────────────────────
              _FieldLabel('Meeting Point'),
              _FormField(
                controller: _meetingPointController,
                hint: 'e.g. Mulhan Pokhari Gate',
                prefixIcon: Icons.pin_drop_rounded,
              ),
              const SizedBox(height: 18),

              // ── Date + Time ────────────────────────────────────────────────
              _FieldLabel('Date & Time'),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: _SelectionCard(
                        icon: Icons.calendar_today_rounded,
                        label: 'DATE',
                        value: _formattedDate,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickTime,
                      child: _SelectionCard(
                        icon: Icons.access_time_rounded,
                        label: 'TIME',
                        value: _formattedTime,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── Max Members ────────────────────────────────────────────────
              _FieldLabel('Max Members'),
              _FormField(
                controller: _maxMembersController,
                hint: '20',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.people_rounded,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 2) return 'Enter a number ≥ 2';
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // ── Image URL (optional) ───────────────────────────────────────
              _FieldLabel('Cover Image URL (optional)'),
              _FormField(
                controller: _imageUrlController,
                hint: 'https://...',
                prefixIcon: Icons.image_rounded,
              ),
              const SizedBox(height: 24),

              // ── Tags ───────────────────────────────────────────────────────
              _FieldLabel('Tags'),
              _TagToggle(
                label: 'Women-only 👩',
                value: _isWomenOnly,
                onChanged: (v) => setState(() => _isWomenOnly = v),
              ),
              const SizedBox(height: 10),
              _TagToggle(
                label: 'Accessible ♿',
                value: _isAccessible,
                onChanged: (v) => setState(() => _isAccessible = v),
              ),
              const SizedBox(height: 10),
              _TagToggle(
                label: 'Free 💸',
                value: _isFree,
                onChanged: (v) => setState(() => _isFree = v),
              ),
              const SizedBox(height: 32),

              // ── Submit ─────────────────────────────────────────────────────
              CustomButton(
                label: 'Create Activity',
                isLoading: ctrl.isCreating,
                onTap: _submit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Shared form sub-widgets
// =============================================================================

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.primary, size: 20)
            : null,
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SelectionCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _TagToggle({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: value ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? AppColors.primary : AppColors.inputBorder,
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: value ? AppColors.primary : AppColors.textSecondary)),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? AppColors.primary : Colors.transparent,
                border: Border.all(
                    color: value ? AppColors.primary : AppColors.textHint, width: 2),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}