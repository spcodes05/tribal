import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

/// Social authentication button variant.
enum SocialProvider { google, apple }

/// Renders a branded Google or Apple sign-in button.
///
/// Matches the design: Google button has white background + border,
/// Apple button has black background.
class SocialButton extends StatelessWidget {
  final SocialProvider provider;
  final VoidCallback? onTap;

  const SocialButton({
    super.key,
    required this.provider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isGoogle = provider == SocialProvider.google;

    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isGoogle
              ? AppColors.googleButtonBg
              : AppColors.appleButtonBg,
          foregroundColor: isGoogle ? AppColors.textPrimary : Colors.white,
          side: BorderSide(
            color: isGoogle ? AppColors.inputBorder : Colors.transparent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Provider icon (inline SVG-style using Flutter icons as fallback)
            _ProviderIcon(provider: provider),
            const SizedBox(width: 10),
            Text(
              isGoogle ? 'Google' : 'Apple',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isGoogle ? AppColors.textPrimary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline provider icon widget.
///
/// Uses custom-painted logos so no external SVG asset is required at runtime.
/// Replace with Image.asset(AppAssets.icGoogle) / Image.asset(AppAssets.icApple)
/// once SVG assets are placed in assets/icons/.
class _ProviderIcon extends StatelessWidget {
  final SocialProvider provider;

  const _ProviderIcon({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider == SocialProvider.google) {
      return _GoogleLogo();
    }
    return const Icon(Icons.apple, color: Colors.white, size: 20);
  }
}

/// Minimal Google "G" painted logo.
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Blue segment
    _drawArc(canvas, rect, -10, 100, const Color(0xFF4285F4));
    // Red segment
    _drawArc(canvas, rect, 91, 100, const Color(0xFFEA4335));
    // Yellow segment
    _drawArc(canvas, rect, 192, 82, const Color(0xFFFBBC05));
    // Green segment
    _drawArc(canvas, rect, 275, 85, const Color(0xFF34A853));

    // White center circle to create ring effect
    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.32,
      centerPaint,
    );

    // "G" horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = size.height * 0.28
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.92, size.height * 0.5),
      barPaint,
    );
  }

  void _drawArc(Canvas canvas, Rect rect, double startDeg, double sweepDeg, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final center = Offset(rect.width / 2, rect.height / 2);
    final radius = rect.width / 2;
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        rect,
        _toRad(startDeg),
        _toRad(sweepDeg),
        false,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  double _toRad(double deg) => deg * 3.14159265 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
