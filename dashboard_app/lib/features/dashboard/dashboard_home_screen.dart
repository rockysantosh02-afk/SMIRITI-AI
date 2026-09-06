import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/localization/app_languages.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_provider.dart';
import '../../core/firebase/firebase_service.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/sync_service.dart';
import '../../core/sync/connectivity_watcher.dart';
import '../../core/sync/sync_debug_indicator.dart';
import '../auth/login_screen.dart';
import '../games/games_hub_screen.dart';
import '../memory/family_member_screen.dart';
import '../journal/journal_screen.dart';
import '../voice/screens/voice_assistant_screen.dart';
import '../voice/services/language_detector.dart';
import '../reminders/reminders_screen.dart';


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

  String _getGreeting(AppLocalizations loc) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return loc.greetingMorning;
    } else if (hour < 17) {
      return loc.greetingAfternoon;
    } else {
      return loc.greetingEvening;
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
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/branding/smriti_logo_mark.png',
              height: 28,
              width: 28,
              fit: BoxFit.contain,
              semanticLabel: 'SMRITI-AI logo',
            ),
            const SizedBox(width: 8),
            const Text(
              'SMRITI-AI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
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
            tooltip: loc.settings,
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
              // SMRITI-AI Primary Branding
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isTablet = MediaQuery.sizeOf(context).width > 600;
                      return Image.asset(
                        'assets/branding/smriti_logo.png',
                        height: isTablet ? 84 : 64,
                        fit: BoxFit.contain,
                        semanticLabel: 'SMRITI-AI logo',
                      );
                    },
                  ),
                ),
              ),

              // Greeting
              Text(
                '${_getGreeting(loc)}, $_userName',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.howAreYouFeeling,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.subtitleColor,
                ),
              ),
              
              const SizedBox(height: 28),
              
              // Today's Card (placeholders for now)
              _buildTodayCard(),
              
              const SizedBox(height: 28),
              
              // Feature Tiles
              _buildFeatureTiles(loc),
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

  Widget _buildFeatureTiles(AppLocalizations loc) {
    return Column(
      children: [
        // Row 1: Games, Voice Assistant
        Row(
          children: [
            Expanded(
              child: _FeatureTile(
                icon: Icons.games_rounded,
                label: loc.games,
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
                label: loc.voiceAssistant,
                color: const Color(0xFF4682B4), // Steel blue
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VoiceAssistantScreen()),
                ),
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
                label: loc.journal,
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
                label: loc.reminders,
                color: const Color(0xFFCD853F), // Peru/tan
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RemindersScreen()),
                ),
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
                label: loc.familyMemories,
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

  void _showLanguageSelectionDialog(
    BuildContext context,
    LanguageProvider langProvider,
  ) {
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(
            loc.selectLanguage,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: RadioGroup<AppLanguage>(
            groupValue: langProvider.currentLanguage,
            onChanged: (val) {
              if (val != null) {
                langProvider.setLanguage(val);
                Navigator.of(dialogCtx).pop();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: AppLanguages.supportedLanguages.map((lang) {
                final isSelected = langProvider.currentLanguage == lang;
                final label = lang == AppLanguage.english
                    ? 'English'
                    : '${lang.nativeName} (${lang.displayName})';

                return RadioListTile<AppLanguage>(
                  title: Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
                    ),
                  ),
                  value: lang,
                  activeColor: AppTheme.primaryColor,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(loc.cancel, style: const TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _showVoiceResponseModeDialog(
    BuildContext context,
    LanguageProvider langProvider,
  ) {
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text(
            'Voice Response Language',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: RadioGroup<VoiceResponseLanguageMode>(
            groupValue: langProvider.voiceResponseLanguageMode,
            onChanged: (val) {
              if (val != null) {
                langProvider.setVoiceResponseLanguageMode(val);
                Navigator.of(dialogCtx).pop();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: VoiceResponseLanguageMode.values.map((mode) {
                final isSelected = langProvider.voiceResponseLanguageMode == mode;
                return RadioListTile<VoiceResponseLanguageMode>(
                  title: Text(
                    mode.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
                    ),
                  ),
                  value: mode,
                  activeColor: AppTheme.primaryColor,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(loc.cancel, style: const TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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
                loc.settings,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),

              // Language Selection Tile
              Consumer<LanguageProvider>(
                builder: (context, langProvider, _) {
                  final current = langProvider.currentLanguage;
                  final currentLabel = switch (current) {
                    AppLanguage.english => 'English >',
                    AppLanguage.telugu => 'తెలుగు >',
                    AppLanguage.hindi => 'हिन्दी >',
                  };

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showLanguageSelectionDialog(context, langProvider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.language_rounded, size: 28, color: AppTheme.primaryColor),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.language,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentLabel,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppTheme.subtitleColor),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),

              // Voice Response Language Mode Tile
              Consumer<LanguageProvider>(
                builder: (context, langProvider, _) {
                  final currentMode = langProvider.voiceResponseLanguageMode;

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showVoiceResponseModeDialog(context, langProvider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.record_voice_over_rounded, size: 28, color: AppTheme.primaryColor),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Voice Response Language',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${currentMode.displayName} >',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppTheme.subtitleColor),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              
              // Text Size Slider
              Text(
                loc.textSize,
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
                loc.textSizeDesc,
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
                          loc.reducedMotion,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.reducedMotionDesc,
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
              
              const SizedBox(height: 36),
              // SMRITI-AI Branding
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/branding/smriti_logo.png',
                      height: 52,
                      fit: BoxFit.contain,
                      semanticLabel: 'SMRITI-AI logo',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'SMRITI-AI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Memory support made simple',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(loc.signOut),
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
