import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive database
  try {
    await DatabaseService.instance.init();
  } catch (e, stackTrace) {
    debugPrint('Database initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
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
    // Close boxes to ensure data is committed to IndexedDB
    DatabaseService.instance.closeAll();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Ensure data is saved when app is paused/closed
      DatabaseService.instance.closeAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Progress',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
