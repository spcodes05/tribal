import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

/// Card matching the "Find a Roommate" mockup — score bar reflects
/// `compatibility_score` returned by `calculate_compatibility_score()`.
class RoommateMatchCard extends StatelessWidget {
  final String name;
  final int? age;
  final String? location;
  final List<String> tags;
  final double compatibility;
  final bool isVerified;
  final bool dealBreaker;
  final VoidCallback onChatTap;

  const RoommateMatchCard({
    super.key,
    required this.name,
    this.age,
    this.location,
    required this.tags,
    required this.compatibility,
    this.isVerified = false,
    this.dealBreaker = false,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.person_outline, color: AppColors.textHint, size: 30),
                  ),
                  if (isVerified) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 14, color: Color(0xFFD4A017)),
                        const SizedBox(width: 3),
                        Text('Gold', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(age != null ? '$name, $age' : name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    if (location != null) ...[
                      const SizedBox(height: 2),
                      Text(location!, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags.map((t) => _Tag(label: t)).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (dealBreaker) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Lifestyle Conflict',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            '${compatibility.round()}% compatible',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (compatibility / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.divider,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onChatTap,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.primary),
              label: Text('Start Chat', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
    );
  }
}