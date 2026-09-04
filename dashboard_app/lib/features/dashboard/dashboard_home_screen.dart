import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/firebase/firebase_service.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/sync_service.dart';
import '../../core/sync/connectivity_watcher.dart';
import '../../core/sync/sync_debug_indicator.dart';
import '../auth/login_screen.dart';
import '../games/games_hub_screen.dart';
import '../memory/family_member_screen.dart';
import '../journal/journal_screen.dart';

/// Dashboard Home Screen for Smriti AI
/// 
/// Single-user dashboard showing:
/// - Time-based greeting with user's name
/// - 5 feature tiles: Games, Voice Assistant, My Journal, Reminders, My Progress
/// - Today card with reminders and streak (placeholders)
/// - Settings accessible from top-right
class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen>
    with WidgetsBindingObserver {
  final FirebaseService _firebaseService = FirebaseService.instance;
  late final SyncService _syncService;
  late final ConnectivityWatcher _connectivityWatcher;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  String _userName = 'Friend';
  double _textScale = 1.0;
  bool _reducedMotion = false;
  int _pendingCount = 0;
  bool _isOnline = true;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncService = SyncService(db: _db, getIdToken: _firebaseService.getIdToken);
    _connectivityWatcher = ConnectivityWatcher(onSync: _syncService.syncNow);
    _connectivityWatcher.start();
    _syncService.startPeriodicSync();
    _syncService.syncNow(); // immediate first sync
    _loadSettings();
    _loadUserName();
    _refreshPendingCount();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });
  }

  AppDatabase get _db => DatabaseProvider.instance;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _textScale = prefs.getDouble('text_scale') ?? 1.0;
      _reducedMotion = prefs.getBool('reduced_motion') ?? false;
    });
  }

  Future<void> _loadUserName() async {
    final name = _firebaseService.displayName;
    if (name != null && name.isNotEmpty) {
      setState(() {
        _userName = name.split(' ').first;
      });
    } else {
      final email = _firebaseService.email;
      if (email != null && email.isNotEmpty) {
        setState(() {
          _userName = email.split('@').first;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text(
          'This feature is coming soon! Stay tuned.',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SettingsSheet(
        textScale: _textScale,
        reducedMotion: _reducedMotion,
        onTextScaleChanged: (value) async {
          setState(() => _textScale = value);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble('text_scale', value);
        },
        onReducedMotionChanged: (value) async {
          setState(() => _reducedMotion = value);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('reduced_motion', value);
        },
        onSignOut: () async {
          Navigator.pop(context); // Close settings
          _syncService.stopPeriodicSync();
          _connectivityWatcher.stop();
          await _firebaseService.signOut();
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        },
      ),
    );
  }

  Future<void> _refreshPendingCount() async {
    final count = await _syncService.pendingCount;
    if (mounted) {
      setState(() {
        _pendingCount = count;
        _lastSyncTime = _syncService.lastSyncTime;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncService.syncNow().then((_) => _refreshPendingCount());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _syncService.dispose();
    _connectivityWatcher.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smriti AI'),
        automaticallyImplyLeading: false,
        actions: [
          SyncDebugIndicator(
            pendingCount: _pendingCount,
            isOnline: _isOnline,
            lastSyncTime: _lastSyncTime,
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            iconSize: 28,
            onPressed: _showSettings,
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Greeting
              Text(
                '${_getGreeting()}, $_userName',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'What would you like to do today?',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.subtitleColor,
                ),
              ),
              
              const SizedBox(height: 28),
              
              // Today's Card (placeholders for now)
              _buildTodayCard(),
              
              const SizedBox(height: 28),
              
              // Feature Tiles
              _buildFeatureTiles(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.today_rounded,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Today',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            // Reminders placeholder
            Row(
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: AppTheme.secondaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No reminders for today',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Streak placeholder
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Keep your streak going!',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTiles() {
    return Column(
      children: [
        // Row 1: Games, Voice Assistant
        Row(
          children: [
            Expanded(
              child: _FeatureTile(
                icon: Icons.games_rounded,
                label: 'Games',
                color: const Color(0xFF6B8E23), // Olive green
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GamesHubScreen()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FeatureTile(
                icon: Icons.mic_rounded,
                label: 'Voice Assistant',
                color: const Color(0xFF4682B4), // Steel blue
                onTap: () => _showComingSoon('Voice Assistant'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Row 2: My Journal, Reminders
        Row(
          children: [
            Expanded(
              child: _FeatureTile(
                icon: Icons.book_rounded,
                label: 'My Journal',
                color: const Color(0xFF8B4513), // Saddle brown
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JournalScreen()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FeatureTile(
                icon: Icons.alarm_rounded,
                label: 'Reminders',
                color: const Color(0xFFCD853F), // Peru/tan
                onTap: () => _showComingSoon('Reminders'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Row 3: My Memories, My Progress
        Row(
          children: [
            Expanded(
              child: _FeatureTile(
                icon: Icons.family_restroom_rounded,
                label: 'My Memories',
                color: const Color(0xFF9C27B0), // Warm Purple
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FamilyMemberScreen()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FeatureTile(
                icon: Icons.trending_up_rounded,
                label: 'My Progress',
                color: AppTheme.primaryColor,
                onTap: () => _showComingSoon('My Progress'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A large, tappable tile for dashboard features
class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for app settings
class _SettingsSheet extends StatelessWidget {
  final double textScale;
  final bool reducedMotion;
  final ValueChanged<double> onTextScaleChanged;
  final ValueChanged<bool> onReducedMotionChanged;
  final VoidCallback onSignOut;

  const _SettingsSheet({
    required this.textScale,
    required this.reducedMotion,
    required this.onTextScaleChanged,
    required this.onReducedMotionChanged,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              
              // Text Size Slider
              Text(
                'Text Size',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.text_fields_rounded, size: 20),
                  Expanded(
                    child: Slider(
                      value: textScale,
                      min: 1.0,
                      max: 1.5,
                      divisions: 5,
                      label: '${(textScale * 100).round()}%',
                      onChanged: onTextScaleChanged,
                    ),
                  ),
                  const Icon(Icons.text_fields_rounded, size: 28),
                ],
              ),
              Text(
                'Adjust text size for better readability',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.subtitleColor,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Reduced Motion Toggle
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reduced Motion',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use simple fade animations',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: reducedMotion,
                    onChanged: onReducedMotionChanged,
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 16),
              
              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade700),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
