import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'controllers/home_controller.dart';
import 'controllers/auth_controller.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        // HomeController is app-wide so it persists across navigation
        // (keeps feed data, notification count, etc. without re-fetching
        // every time the user navigates back to home).
        ChangeNotifierProvider(create: (_) => HomeController()),
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
