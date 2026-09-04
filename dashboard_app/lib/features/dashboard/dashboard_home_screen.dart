import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/firebase/firebase_service.dart';
import '../auth/login_screen.dart';

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

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  
  String _userName = 'Friend';
  double _textScale = 1.0;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUserName();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smriti AI'),
        automaticallyImplyLeading: false,
        actions: [
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
                onTap: () => _showComingSoon('Games'),
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
                onTap: () => _showComingSoon('My Journal'),
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
        
        // Row 3: My Progress (full width)
        _FeatureTile(
          icon: Icons.trending_up_rounded,
          label: 'My Progress',
          color: AppTheme.primaryColor,
          onTap: () => _showComingSoon('My Progress'),
          fullWidth: true,
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
  final bool fullWidth;

  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
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
            mainAxisAlignment: fullWidth 
                ? MainAxisAlignment.start 
                : MainAxisAlignment.center,
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
              if (fullWidth) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color.withValues(alpha: 0.5),
                  size: 20,
                ),
              ] else ...[
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
