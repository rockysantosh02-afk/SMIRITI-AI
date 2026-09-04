import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/voice_intent.dart';
import '../services/voice_service.dart';
import '../services/voice_intent_matcher.dart';
import '../voice_prompts.dart';

/// Full-screen, elderly-accessible Voice Assistant for Smriti AI.
///
/// Designed with:
/// - **Large 80dp+ touch target**: High-contrast, tactile microphone button.
/// - **Explicit push-to-talk**: Never listens automatically on screen load.
/// - **Live transcription**: Real-time display of spoken words.
/// - **Calm, respectful feedback**: Non-distressing messages for unrecognized speech.
class VoiceAssistantScreen extends StatefulWidget {
  final IVoiceService? voiceService;
  final String initialLanguage;

  const VoiceAssistantScreen({
    super.key,
    this.voiceService,
    this.initialLanguage = 'en',
  });

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  late final IVoiceService _voiceService;
  late String _selectedLanguage;

  String _recognizedText = '';
  VoiceIntentResult? _intentResult;
  Timer? _autoNavigateTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialLanguage;
    _voiceService = widget.voiceService ?? VoiceService();

    // Setup listening pulse animation (starts only while actively listening)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen for status changes (e.g. permissionDenied, unavailable)
    if (_voiceService is ChangeNotifier) {
      (_voiceService as ChangeNotifier).addListener(_onVoiceStatusChanged);
    }

    // Initialize voice service silently - DO NOT START LISTENING
    _voiceService.initialize();
  }

  void _onVoiceStatusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    _pulseController.stop();
    _pulseController.dispose();
    if (_voiceService is ChangeNotifier) {
      (_voiceService as ChangeNotifier).removeListener(_onVoiceStatusChanged);
    }
    if (widget.voiceService == null) {
      _voiceService.dispose();
    }
    super.dispose();
  }

  void _handleMicrophoneTap() {
    if (_voiceService.isListening) {
      _stopListeningWithAnimation();
    } else {
      _autoNavigateTimer?.cancel();
      setState(() {
        _recognizedText = '';
        _intentResult = null;
      });

      _pulseController.repeat(reverse: true);

      _voiceService.startListening(
        languageCode: _selectedLanguage,
        onResult: (words) {
          if (mounted) {
            setState(() {
              _recognizedText = words;
            });
          }
        },
        onComplete: () {
          _stopPulseAnimation();
          if (mounted) {
            setState(() {
              _intentResult = _voiceService.lastIntentResult;
            });

            // If intent is actionable, schedule gentle auto-navigation
            final route = _intentResult?.targetRoute;
            if (route != null && mounted) {
              _autoNavigateTimer = Timer(const Duration(milliseconds: 1600), () {
                if (mounted) {
                  _executeNavigation(route);
                }
              });
            }
          }
        },
      );
    }
  }

  void _stopListeningWithAnimation() {
    _stopPulseAnimation();
    _voiceService.stopListening();
  }

  void _stopPulseAnimation() {
    if (_pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _executeNavigation(String route) {
    _autoNavigateTimer?.cancel();
    if (route == '/dashboard') {
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      Navigator.of(context).pushNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ভইচ সহায়ক (Voice Assistant)'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Language Selector Chips
              _buildLanguageSelector(),

              const SizedBox(height: 20),

              // Live Transcription & State Feedback
              _buildStatusAndTranscription(),

              const SizedBox(height: 16),

              // Action Result Card (if matched)
              if (_intentResult != null) ...[
                _buildResultCard(),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              // Large 80dp+ Push-to-Talk Microphone Button
              _buildMicrophoneButton(),

              const SizedBox(height: 16),

              // Status Label under Button
              _buildButtonStatusLabel(),

              const SizedBox(height: 28),

              // Quick Hint Chips for Elders
              _buildQuickHints(),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final languages = [
      {'code': 'en', 'label': 'English'},
      {'code': 'as', 'label': 'অসমীয়া'},
      {'code': 'bn', 'label': 'বাংলা'},
      {'code': 'hi', 'label': 'हिन्दी'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: languages.map((lang) {
          final isSelected = _selectedLanguage == lang['code'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                lang['label']!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppTheme.textColor,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.primaryColor,
              backgroundColor: AppTheme.surfaceColor,
              onSelected: (selected) {
                if (selected && !_voiceService.isListening) {
                  setState(() {
                    _selectedLanguage = lang['code']!;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusAndTranscription() {
    final status = _voiceService.status;

    // Handle permission denied or unavailable
    if (status == VoiceAssistantStatus.permissionDenied) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                VoicePrompts.get(VoicePrompts.permissionDenied, _selectedLanguage),
                style: const TextStyle(fontSize: 16, color: AppTheme.textColor),
              ),
            ),
          ],
        ),
      );
    }

    if (status == VoiceAssistantStatus.unavailable) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.mic_off_rounded, color: Colors.grey, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                VoicePrompts.get(VoicePrompts.speechUnavailable, _selectedLanguage),
                style: const TextStyle(fontSize: 16, color: AppTheme.textColor),
              ),
            ),
          ],
        ),
      );
    }

    // Default display during listening or idle
    return Column(
      children: [
        if (_voiceService.isListening) ...[
          Text(
            VoicePrompts.get(VoicePrompts.listening, _selectedLanguage),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 14),
        ] else if (status == VoiceAssistantStatus.processing) ...[
          Text(
            VoicePrompts.get(VoicePrompts.processing, _selectedLanguage),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Live transcription container
        Container(
          width: double.infinity,
          constraints: const Duration(seconds: 1) == Duration.zero
              ? null
              : const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _voiceService.isListening
                  ? AppTheme.primaryColor
                  : AppTheme.primaryColor.withValues(alpha: 0.15),
              width: _voiceService.isListening ? 2 : 1,
            ),
          ),
          child: Text(
            _recognizedText.isNotEmpty
                ? _recognizedText
                : 'আপুনি যিকোনো কমাণ্ড ক\'ব পাৰে যেনে "ডায়েরী খোলক" বা "খেলিম"\n(Say a command like "Open Journal" or "Play Games")',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontStyle: _recognizedText.isEmpty ? FontStyle.italic : FontStyle.normal,
              color: _recognizedText.isNotEmpty
                  ? AppTheme.textColor
                  : AppTheme.subtitleColor,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    final res = _intentResult!;
    final isMatched = res.intent != VoiceIntent.unknown;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMatched
            ? AppTheme.secondaryColor.withValues(alpha: 0.12)
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMatched
              ? AppTheme.secondaryColor.withValues(alpha: 0.4)
              : Colors.orange.shade300,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isMatched ? Icons.check_circle_outline_rounded : Icons.help_outline_rounded,
                color: isMatched ? AppTheme.secondaryColor : Colors.orange.shade800,
                size: 26,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  res.feedbackMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isMatched ? AppTheme.secondaryColor : Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          if (res.targetRoute != null) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _executeNavigation(res.targetRoute!),
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: const Text('এতিয়াই যাওক (Go Now)', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMicrophoneButton() {
    final isListening = _voiceService.isListening;

    return Center(
      child: ScaleTransition(
        scale: isListening ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
        child: Semantics(
          label: isListening ? 'Stop listening' : 'Start listening',
          button: true,
          child: Material(
            shape: const CircleBorder(),
            color: isListening ? Colors.red.shade600 : AppTheme.primaryColor,
            elevation: isListening ? 8 : 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _handleMicrophoneTap,
              child: Container(
                width: 96,
                height: 96, // Minimum 80dp touch target exceeded comfortably
                alignment: Alignment.center,
                child: Icon(
                  isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonStatusLabel() {
    final isListening = _voiceService.isListening;
    final text = isListening
        ? VoicePrompts.get(VoicePrompts.tapToStop, _selectedLanguage)
        : VoicePrompts.get(VoicePrompts.tapToSpeak, _selectedLanguage);

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isListening ? Colors.red.shade700 : AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildQuickHints() {
    final hints = [
      {'text': 'ডায়েরী খোলক (Open Journal)', 'raw': 'open my journal'},
      {'text': 'নতুন স্মৃতি (New Memory)', 'raw': 'create a memory'},
      {'text': 'খেল খোলক (Play Games)', 'raw': 'play a game'},
      {'text': 'ঘৰলৈ (Go Home)', 'raw': 'go home'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ক\'ব পৰা কমাণ্ডসমূহ (Sample Commands):',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.subtitleColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hints.map((h) {
            return ActionChip(
              backgroundColor: AppTheme.surfaceColor,
              side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              label: Text(
                h['text']!,
                style: const TextStyle(fontSize: 14, color: AppTheme.textColor),
              ),
              onPressed: () {
                if (!_voiceService.isListening) {
                  setState(() {
                    _recognizedText = h['raw']!;
                    _intentResult = const VoiceIntentMatcher().match(
                      h['raw']!,
                      languageCode: _selectedLanguage,
                    );
                  });

                  final route = _intentResult?.targetRoute;
                  if (route != null) {
                    _autoNavigateTimer?.cancel();
                    _autoNavigateTimer = Timer(const Duration(milliseconds: 1400), () {
                      if (mounted) _executeNavigation(route);
                    });
                  }
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
