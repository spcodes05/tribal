import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'controllers/home_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/current_user_controller.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (API keys etc.) from .env file.
  // The .env file is gitignored — see .env.example for required keys.


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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        // HomeController is app-wide so it persists across navigation
        // (keeps feed data, notification count, etc. without re-fetching
        // every time the user navigates back to home).
        ChangeNotifierProvider(create: (_) => HomeController()),
        // Single source of truth for the logged-in user's own avatar
        // (name + photo). Every UserAvatar.me() in the app watches this
        // same instance, so uploading/removing a photo on Tribe Status
        // updates every "my avatar" on screen immediately, everywhere,
        // with no per-screen wiring. Eager-loads here; also re-loaded
        // from HomeScreen.initState() once the user is authenticated.
        ChangeNotifierProvider(create: (_) => CurrentUserController()..load()),
      ],
      child: MaterialApp.router(
        title: 'TRIBAL',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: AppRoutes.router,
      ),
    );
  }
}