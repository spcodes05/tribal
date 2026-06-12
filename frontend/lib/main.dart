import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for consistent mobile UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar so gradient bleeds into system bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const TribalApp());
}

/// Root application widget.
///
/// Registers global providers and bootstraps GoRouter.
/// Screen-level [ChangeNotifierProvider]s are created inline within each
/// screen (see onboarding_screen.dart, login_screen.dart, signup_screen.dart)
/// so they are automatically disposed when the route is popped.
class TribalApp extends StatelessWidget {
  const TribalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TRIBAL',
      debugShowCheckedModeBanner: false,

      // Global theme
      theme: AppTheme.light,

      // GoRouter config
      routerConfig: AppRoutes.router,
    );
  }
}
