// Smriti AI - Main App Entry Point
//
// A single-user, offline-first cognitive wellness dashboard for elders.
// This app is designed to be used independently by the user - no caregiver role.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/firebase/firebase_options.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env file may not exist in development, continue anyway
    debugPrint('Note: .env file not found, using default configuration');
  }
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Load user preferences for theme settings
  final prefs = await SharedPreferences.getInstance();
  final textScale = prefs.getDouble('text_scale') ?? 1.0;
  final reducedMotion = prefs.getBool('reduced_motion') ?? false;
  
  // Update global theme settings
  globalTextScaleFactor = textScale;
  globalReducedMotion = reducedMotion;
  
  runApp(SmritiApp(
    textScale: textScale,
    reducedMotion: reducedMotion,
  ));
}

class SmritiApp extends StatefulWidget {
  final double textScale;
  final bool reducedMotion;

  const SmritiApp({
    super.key,
    required this.textScale,
    required this.reducedMotion,
  });

  @override
  State<SmritiApp> createState() => _SmritiAppState();
}

class _SmritiAppState extends State<SmritiApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smriti AI',
      debugShowCheckedModeBanner: false,
      
      // Apply accessibility theme with user's saved preferences
      theme: AppTheme.createTheme(
        textScaleFactor: widget.textScale,
        reducedMotion: widget.reducedMotion,
      ),
      
      // Route configuration
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardHomeScreen(),
      },
      
      // Handle unknown routes - redirect to login
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          return MaterialPageRoute(
            builder: (_) => const DashboardHomeScreen(),
          );
        }
        // Default to login
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      },
    );
  }
}