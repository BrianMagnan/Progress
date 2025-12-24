import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'services/supabase_database_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use path-based URLs for web (instead of hash-based)
  GoRouter.optionURLReflectsImperativeAPIs = true;

  // Initialize Supabase database
  try {
    await SupabaseDatabaseService.instance.init();
  } catch (e, stackTrace) {
    debugPrint('Database initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }

  // Initialize local notifications (works on mobile platforms)
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Notification initialization failed: $e');
    // Continue without notifications if initialization fails
  }

  // Set preferred orientations (optional)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProgressApp());
}

class ProgressApp extends StatefulWidget {
  const ProgressApp({super.key});

  @override
  State<ProgressApp> createState() => _ProgressAppState();
}

class _ProgressAppState extends State<ProgressApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Supabase handles persistence automatically
    SupabaseDatabaseService.instance.closeAll();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Supabase handles persistence automatically
    // No need to manually save data
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Progress',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
