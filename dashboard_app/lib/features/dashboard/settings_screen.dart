import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_provider.dart';
import '../voice/services/language_detector.dart';

/// Elderly-friendly standalone Settings Screen for Smriti AI.
///
/// Provides large touch targets, high contrast, and accessible options for:
/// - App language selection
/// - Voice response language mode
/// - Text size adjustment
/// - Reduced motion toggle
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _textScale = 1.0;
  bool _reducedMotion = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _textScale = prefs.getDouble('text_scale') ?? 1.0;
        _reducedMotion = prefs.getBool('reduced_motion') ?? false;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          tooltip: loc.back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                children: [
                  // Text Size Section
                  Text(
                    loc.textSize,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.text_fields_rounded, size: 22),
                      Expanded(
                        child: Slider(
                          value: _textScale,
                          min: 1.0,
                          max: 1.5,
                          divisions: 5,
                          label: '${(_textScale * 100).round()}%',
                          onChanged: (value) async {
                            setState(() => _textScale = value);
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setDouble('text_scale', value);
                          },
                        ),
                      ),
                      const Icon(Icons.text_fields_rounded, size: 30),
                    ],
                  ),
                  Text(
                    loc.textSizeDesc,
                    style: const TextStyle(fontSize: 15, color: AppTheme.subtitleColor),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Reduced Motion Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      loc.reducedMotion,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    subtitle: Text(
                      loc.reducedMotionDesc,
                      style: const TextStyle(fontSize: 15, color: AppTheme.subtitleColor),
                    ),
                    value: _reducedMotion,
                    onChanged: (value) async {
                      setState(() => _reducedMotion = value);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('reduced_motion', value);
                    },
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Voice Response Language Mode
                  Consumer<LanguageProvider>(
                    builder: (context, langProvider, _) {
                      final currentMode = langProvider.voiceResponseLanguageMode;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Voice Response Language',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        subtitle: Text(
                          currentMode.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 28),
                        onTap: () {
                          _showVoiceModePicker(context, langProvider);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 36),
                  const Divider(),
                  const SizedBox(height: 24),

                  // SMRITI-AI Branding
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/branding/smriti_logo.png',
                          height: 56,
                          fit: BoxFit.contain,
                          semanticLabel: 'SMRITI-AI logo',
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'SMRITI-AI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Memory support made simple',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  void _showVoiceModePicker(BuildContext context, LanguageProvider langProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Choose Voice Language Mode',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ...VoiceResponseLanguageMode.values.map((mode) {
                  final isSelected = langProvider.voiceResponseLanguageMode == mode;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? AppTheme.primaryColor : Colors.grey,
                    ),
                    title: Text(mode.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    onTap: () {
                      langProvider.setVoiceResponseLanguageMode(mode);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
