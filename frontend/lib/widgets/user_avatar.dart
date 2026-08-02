import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/current_user_controller.dart';
import '../core/constants/app_colors.dart';

/// The ONE avatar widget used everywhere in Tribal — Home, Tribe Status,
/// Other User Profile, Chat, People You Might Vibe With, Roommate Matches,
/// Activity Host/Members, everywhere else a user's photo appears.
///
/// Handles, in one place, so no screen has to reimplement any of this:
///   - a real uploaded photo
///   - a broken/expired URL (falls back to initials, never crashes)
///   - no photo at all (initials, or a generic icon if there's no name yet)
///   - consistent sizing via [radius]
///   - an optional squircle shape via [cornerRadius] (e.g. Roommate cards)
///
/// For the LOGGED-IN user's own avatar, use [UserAvatar.me] instead of
/// wiring imageUrl/fullName by hand — it watches [CurrentUserController]
/// directly, so it updates instantly, everywhere it's used, the moment a
/// photo is uploaded or removed. No screen refresh, no restart, no manual
/// plumbing per screen.
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? fullName;
  final double radius;
  final Color? backgroundColor;

  /// If set, renders as a rounded-square ("squircle") of that corner
  /// radius instead of a circle — e.g. the Roommate match card's existing
  /// squircle avatar style. Leave null for the standard circular avatar
  /// used everywhere else in the app.
  final double? cornerRadius;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    required this.fullName,
    this.radius = 24,
    this.backgroundColor,
    this.cornerRadius,
  });

  /// The current logged-in user's avatar. Rebuilds automatically whenever
  /// the photo changes anywhere in the app.
  static Widget me({Key? key, double radius = 24, Color? backgroundColor}) {
    return _MyAvatar(key: key, radius: radius, backgroundColor: backgroundColor);
  }

  /// Deterministic color from a name, so the same person always gets the
  /// same initials-fallback color across every screen.
  static Color colorForName(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return AppColors.textSecondary;
    const palette = [
      AppColors.primary,
      Color(0xFF3E7CB1),
      Color(0xFF4F9D69),
      Color(0xFFB18A3E),
      Color(0xFF8E5FB1),
      Color(0xFFB1553E),
    ];
    return palette[trimmed.codeUnitAt(0) % palette.length];
  }

  static String initialsForName(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final color = backgroundColor ?? colorForName(fullName);
    final initials = initialsForName(fullName);

    final content = hasImage
        ? Image.network(
      // Backend guarantees a fresh, unique URL on every upload
      // (see apps.users.models.profile_image_upload_path), so
      // there's no risk of Flutter's ImageCache ever serving a
      // stale photo — no manual cache-busting needed here.
      imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          _AvatarFallback(color: color, initials: initials, radius: radius),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _AvatarFallback(color: color, initials: initials, radius: radius);
      },
    )
        : _AvatarFallback(color: color, initials: initials, radius: radius);

    final clipped = cornerRadius != null
        ? ClipRRect(borderRadius: BorderRadius.circular(cornerRadius!), child: content)
        : ClipOval(child: content);

    return SizedBox(width: size, height: size, child: clipped);
  }
}

class _AvatarFallback extends StatelessWidget {
  final Color color;
  final String initials;
  final double radius;
  const _AvatarFallback({required this.color, required this.initials, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: initials.isEmpty ? AppColors.surface : color,
      alignment: Alignment.center,
      child: initials.isNotEmpty
          ? Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      )
          : Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: radius * 0.9),
    );
  }
}

/// Watches [CurrentUserController] so "my" avatar updates live everywhere.
class _MyAvatar extends StatelessWidget {
  final double radius;
  final Color? backgroundColor;
  const _MyAvatar({super.key, required this.radius, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<CurrentUserController>();
    return UserAvatar(
      imageUrl: me.profileImage,
      fullName: me.fullName,
      radius: radius,
      backgroundColor: backgroundColor,
    );
  }
}