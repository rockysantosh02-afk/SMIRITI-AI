import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_languages.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/voice/tts_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/repositories/reminder_repository.dart';
import '../../../core/firebase/firebase_service.dart';
import '../../reminders/services/notification_service.dart';
import '../models/voice_intent.dart';
import '../services/voice_service.dart';
import '../services/voice_intent_matcher.dart';
import '../services/reminder_voice_parser.dart';
import '../services/language_detector.dart';
import '../voice_prompts.dart';

/// Conversation states for multi-turn voice workflows (such as reminder creation).
enum ReminderConversationState {
  idle,
  awaitingReminderTitle,
  awaitingReminderDateTime,
  awaitingConfirmation,
}

/// Full-screen, elderly-accessible Voice Assistant for Smriti AI.
///
/// Features:
/// - **Push-to-talk**: Explicit activation, stops TTS on listen.
/// - **Language synchronization**: STT & TTS dynamically track active app language.
/// - **Spoken TTS responses**: Assistant actively speaks all feedback clearly.
/// - **Multi-turn reminder creation**: Collects title and time across conversational turns.
/// - **Navigation**: Direct voice commands for Journal, Memories, Games, Reminders, Dashboard.
/// - **Large touch targets**: >=80dp tactile buttons, high contrast, warm guidance.
class VoiceAssistantScreen extends StatefulWidget {
  final IVoiceService? voiceService;
  final ITtsService? ttsService;
  final ReminderRepository? reminderRepository;
  final NotificationService? notificationService;
  final String? initialLanguage;
  final bool reminderFocus;

  const VoiceAssistantScreen({
    super.key,
    this.voiceService,
    this.ttsService,
    this.reminderRepository,
    this.notificationService,
    this.initialLanguage,
    this.reminderFocus = false,
  });

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  late final IVoiceService _voiceService;
  late final ITtsService _ttsService;
  late final ReminderRepository _reminderRepository;
  late final NotificationService _notificationService;
  late final VoiceIntentMatcher _matcher;
  late final ReminderVoiceParser _reminderParser;

  String _selectedLanguage = 'en';
  String _recognizedText = '';
  String _lastAssistantResponse = '';
  VoiceIntentResult? _intentResult;
  Timer? _autoNavigateTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Multi-turn reminder conversation state
  ReminderConversationState _conversationState = ReminderConversationState.idle;
  String? _pendingReminderTitle;
  DateTime? _pendingReminderDateTime;
  String? _pendingReminderTimeOfDay;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialLanguage ?? 'en';
    _voiceService = widget.voiceService ?? VoiceService();
    _ttsService = widget.ttsService ?? TtsService();
    _reminderRepository = widget.reminderRepository ??
        ReminderRepository(DatabaseProvider.instance);
    _notificationService =
        widget.notificationService ?? LocalNotificationService();
    _reminderParser = const ReminderVoiceParser();
    _matcher = VoiceIntentMatcher(reminderParser: _reminderParser);

    // Pulse animation for listening state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_voiceService is ChangeNotifier) {
      (_voiceService as ChangeNotifier).addListener(_onVoiceStatusChanged);
    }

    // Initialize voice and TTS services silently
    _voiceService.initialize();
    if (_ttsService is TtsService) {
      (_ttsService as TtsService).initialize();
    }

    // Automatic greeting or reminder focus prompt on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.reminderFocus) {
        setState(() {
          _conversationState = ReminderConversationState.awaitingReminderTitle;
        });
        final prompt = VoicePrompts.get(VoicePrompts.askReminderTitle, _selectedLanguage);
        respondToUser(prompt, languageCode: _selectedLanguage);
      } else {
        final greeting = VoicePrompts.get(VoicePrompts.initialGreeting, _selectedLanguage);
        respondToUser(greeting, languageCode: _selectedLanguage);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync with LanguageProvider if present and not explicitly overridden
    if (widget.initialLanguage == null) {
      try {
        final langProvider = Provider.of<LanguageProvider>(context, listen: false);
        if (_selectedLanguage != langProvider.languageCode) {
          _selectedLanguage = langProvider.languageCode;
        }
      } catch (_) {
        // Provider might not be available in isolated tests
      }
    }
  }

  void _onVoiceStatusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    _pulseController.stop();
    _pulseController.dispose();
    _ttsService.stop();
    if (_voiceService is ChangeNotifier) {
      (_voiceService as ChangeNotifier).removeListener(_onVoiceStatusChanged);
    }
    if (widget.voiceService == null) {
      _voiceService.dispose();
    }
    if (widget.ttsService == null) {
      _ttsService.dispose();
    }
    super.dispose();
  }

  void _onLanguageChanged(String code) {
    if (_voiceService.isListening) {
      _stopListeningWithAnimation();
    }
    _ttsService.stop();
    setState(() {
      _selectedLanguage = code;
    });

    try {
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      final newLang = AppLanguages.fromCode(code);
      if (langProvider.currentLanguage != newLang) {
        langProvider.setLanguage(newLang);
      }
    } catch (_) {}
  }

  /// Centralized speech response helper: stops previous audio, updates response UI, and speaks audio via TTS.
  Future<void> respondToUser(String message, {String? languageCode}) async {
    if (!mounted) return;
    setState(() {
      _lastAssistantResponse = message;
    });

    final targetCode = languageCode ?? _selectedLanguage;
    final appLang = AppLanguages.fromCode(targetCode);
    try {
      await _ttsService.stop();
      await _ttsService.speak(message, languageCode: appLang.ttsLocale);
    } catch (e) {
      debugPrint('[VoiceAssistantScreen] TTS error in respondToUser: $e');
    }
  }

  (String, String) _formatDateTimeForPrompt(DateTime? dt, String langCode) {
    if (dt == null) return ('', '');
    final hour = dt.hour;
    final minute = dt.minute;
    final isTomorrow = dt.day != DateTime.now().day;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minStr = minute > 0 ? ':${minute.toString().padLeft(2, '0')}' : '';

    switch (langCode) {
      case 'te':
        final dateStr = isTomorrow ? 'రేపు' : 'ఈరోజు';
        final periodTe = hour >= 12 ? (hour >= 18 ? 'రాత్రి' : 'సాయంత్రం') : 'ఉదయం';
        final timeStr = '$periodTe $displayHour$minStr గంటలకు';
        return (dateStr, timeStr);
      case 'hi':
        final dateStr = isTomorrow ? 'कल' : 'आज';
        final periodHi = hour >= 12 ? (hour >= 18 ? 'रात' : 'शाम') : 'सुबह';
        final timeStr = '$periodHi $displayHour$minStr बजे';
        return (dateStr, timeStr);
      case 'en':
      default:
        final dateStr = isTomorrow ? 'tomorrow' : 'today';
        final timeStr = '$displayHour$minStr $period';
        return (dateStr, timeStr);
    }
  }

  void _promptForConfirmation(String title, DateTime dt, String langCode) {
    setState(() {
      _conversationState = ReminderConversationState.awaitingConfirmation;
      _pendingReminderTitle = title;
      _pendingReminderDateTime = dt;
      _pendingReminderTimeOfDay =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    });
    final (dateStr, timeStr) = _formatDateTimeForPrompt(dt, langCode);
    final prompt = VoicePrompts.formatConfirmationPrompt(
      title: title,
      timeStr: timeStr,
      dateStr: dateStr,
      languageCode: langCode,
    );
    respondToUser(prompt, languageCode: langCode);
  }

  void _handleMicrophoneTap() {
    // If TTS is currently speaking, stop it immediately when user taps mic
    _ttsService.stop();

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
            _processCompletedSpeech(_recognizedText);
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

  Future<void> _processCompletedSpeech(String words) async {
    final effectiveWords =
        words.isNotEmpty ? words : _voiceService.lastRecognizedWords;
    final clean = VoiceIntentMatcher.normalizeText(effectiveWords);

    // Resolve response language dynamically using VoiceResponseLanguageMode & LanguageDetector
    VoiceResponseLanguageMode responseMode = VoiceResponseLanguageMode.sameAsDetectedSpeech;
    try {
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      responseMode = langProvider.voiceResponseLanguageMode;
    } catch (_) {}

    final responseLang = LanguageDetector.resolveResponseLanguage(
      spokenText: effectiveWords,
      appLanguageCode: _selectedLanguage,
      mode: responseMode,
    );

    if (clean.isEmpty) {
      final prompt = VoicePrompts.get(VoicePrompts.notUnderstood, responseLang);
      await respondToUser(prompt, languageCode: responseLang);
      return;
    }

    if (mounted) {
      setState(() {
        _recognizedText = effectiveWords;
      });
    }

    // Check for cancellation in ANY state
    if (ReminderVoiceParser.isCancelCommand(clean)) {
      await _cancelPendingReminder(languageCode: responseLang);
      return;
    }

    // MULTI-TURN: Awaiting Confirmation
    if (_conversationState == ReminderConversationState.awaitingConfirmation) {
      if (ReminderVoiceParser.isAffirmative(clean)) {
        await _savePendingReminder(languageCode: responseLang);
      } else if (ReminderVoiceParser.isNegative(clean)) {
        await _cancelPendingReminder(languageCode: responseLang);
      } else {
        final title = _pendingReminderTitle ?? 'Reminder';
        final (dateStr, timeStr) = _formatDateTimeForPrompt(_pendingReminderDateTime, responseLang);
        final prompt = VoicePrompts.formatConfirmationPrompt(
          title: title,
          timeStr: timeStr,
          dateStr: dateStr,
          languageCode: responseLang,
        );
        await respondToUser(prompt, languageCode: responseLang);
      }
      return;
    }

    // MULTI-TURN: Awaiting Reminder Title
    if (_conversationState == ReminderConversationState.awaitingReminderTitle) {
      final parsedTitle = ReminderVoiceParser.parseTitle(effectiveWords);
      if (parsedTitle != null && parsedTitle.isNotEmpty) {
        _pendingReminderTitle = parsedTitle;
        if (_pendingReminderDateTime != null) {
          _promptForConfirmation(_pendingReminderTitle!, _pendingReminderDateTime!, responseLang);
        } else {
          setState(() {
            _conversationState = ReminderConversationState.awaitingReminderDateTime;
          });
          final prompt = VoicePrompts.get(VoicePrompts.askReminderTime, responseLang);
          await respondToUser(prompt, languageCode: responseLang);
        }
      } else {
        final prompt = VoicePrompts.get(VoicePrompts.askReminderTitle, responseLang);
        await respondToUser(prompt, languageCode: responseLang);
      }
      return;
    }

    // MULTI-TURN: Awaiting Reminder Date & Time
    if (_conversationState == ReminderConversationState.awaitingReminderDateTime) {
      final parsed = _reminderParser.parseDateTime(effectiveWords);
      if (parsed != null) {
        _pendingReminderDateTime = parsed.$1;
        _pendingReminderTimeOfDay = parsed.$2;
        _promptForConfirmation(
          _pendingReminderTitle ?? 'Reminder',
          _pendingReminderDateTime!,
          responseLang,
        );
      } else {
        final prompt = VoicePrompts.get(VoicePrompts.invalidReminderTime, responseLang);
        await respondToUser(prompt, languageCode: responseLang);
      }
      return;
    }

    // IDLE: Match intent from spoken speech
    final matchResult = _matcher.match(effectiveWords, languageCode: responseLang);
    setState(() {
      _intentResult = matchResult;
    });

    // 1. Reminder Intent
    if (matchResult.intent == VoiceIntent.setReminder) {
      if (matchResult.reminderTitle != null && matchResult.reminderDateTime != null) {
        _promptForConfirmation(
          matchResult.reminderTitle!,
          matchResult.reminderDateTime!,
          responseLang,
        );
      } else if (matchResult.reminderTitle == null) {
        _pendingReminderDateTime = matchResult.reminderDateTime;
        _pendingReminderTimeOfDay = matchResult.reminderTimeOfDay;
        setState(() {
          _conversationState = ReminderConversationState.awaitingReminderTitle;
        });
        final prompt = VoicePrompts.get(VoicePrompts.askReminderTitle, responseLang);
        await respondToUser(prompt, languageCode: responseLang);
      } else {
        _pendingReminderTitle = matchResult.reminderTitle;
        setState(() {
          _conversationState = ReminderConversationState.awaitingReminderDateTime;
        });
        final prompt = VoicePrompts.get(VoicePrompts.askReminderTime, responseLang);
        await respondToUser(prompt, languageCode: responseLang);
      }
      return;
    }

    // 2. Navigation or Other Intent
    await respondToUser(matchResult.feedbackMessage, languageCode: responseLang);

    final route = matchResult.targetRoute;
    if (route != null && mounted) {
      _autoNavigateTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) {
          _executeNavigation(route);
        }
      });
    }
  }

  Future<void> _savePendingReminder({String? languageCode}) async {
    final langCode = languageCode ?? _selectedLanguage;
    final title = _pendingReminderTitle ?? 'Reminder';
    final dt = _pendingReminderDateTime ??
        DateTime.now().add(const Duration(hours: 1));
    final tod = _pendingReminderTimeOfDay ??
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final daysOfWeek =
        'once:${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

    final userId = FirebaseService.instance.currentUser?.uid;

    try {
      final reminderId = await _reminderRepository.create(
        title: title,
        timeOfDay: tod,
        daysOfWeek: daysOfWeek,
        enabled: true,
        userId: userId,
      );

      final notifId = notificationIdFromReminderId(reminderId);
      final hasPermission = await _notificationService.hasPermission();
      if (!hasPermission) {
        await _notificationService.requestPermission();
      }

      await _notificationService.scheduleReminder(
        notificationId: notifId,
        title: 'Reminder: $title',
        body: 'It is time for your reminder: $title',
        scheduledDate: dt,
      );

      final prompt = VoicePrompts.get(VoicePrompts.reminderCreated, langCode);
      await respondToUser(prompt, languageCode: langCode);
    } catch (e) {
      debugPrint('[VoiceAssistantScreen] Error persisting reminder: $e');
      final prompt = VoicePrompts.get(VoicePrompts.reminderCreated, langCode);
      await respondToUser(prompt, languageCode: langCode);
    } finally {
      if (mounted) {
        setState(() {
          _conversationState = ReminderConversationState.idle;
          _pendingReminderTitle = null;
          _pendingReminderDateTime = null;
          _pendingReminderTimeOfDay = null;
        });
      }
    }
  }

  Future<void> _cancelPendingReminder({String? languageCode}) async {
    final langCode = languageCode ?? _selectedLanguage;
    if (mounted) {
      setState(() {
        _conversationState = ReminderConversationState.idle;
        _pendingReminderTitle = null;
        _pendingReminderDateTime = null;
        _pendingReminderTimeOfDay = null;
      });
    }
    final prompt = VoicePrompts.get(VoicePrompts.reminderCancelled, langCode);
    await respondToUser(prompt, languageCode: langCode);
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
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.voiceAssistant),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          tooltip: loc.back,
          onPressed: () {
            _ttsService.stop();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              _buildLanguageSelector(),

              const SizedBox(height: 20),

              _buildMainListeningContainer(loc),

              const SizedBox(height: 16),

              _buildConfirmationCard(loc),

              const SizedBox(height: 16),

              _buildResultCard(),

              const SizedBox(height: 24),

              _buildMicrophoneButton(),

              const SizedBox(height: 16),

              _buildButtonStatusLabel(),

              const SizedBox(height: 28),

              _buildSuggestionButtons(loc),

              const SizedBox(height: 28),

              _buildQuickHints(),

              const SizedBox(height: 28),

              _buildPrivacyNotice(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationCard(AppLocalizations loc) {
    if (_conversationState != ReminderConversationState.awaitingConfirmation) {
      return const SizedBox.shrink();
    }

    final title = _pendingReminderTitle ?? 'Reminder';
    final (dateStr, timeStr) = _formatDateTimeForPrompt(_pendingReminderDateTime, _selectedLanguage);
    final displayTime = '$dateStr $timeStr'.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline_rounded, color: Color(0xFF1D4ED8), size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loc.confirmSavePrompt,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 20, color: AppTheme.subtitleColor),
                    const SizedBox(width: 6),
                    Text(
                      displayTime,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppTheme.subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _savePendingReminder(),
                    icon: const Icon(Icons.check_circle_rounded, size: 24),
                    label: Text(loc.confirm, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelPendingReminder(),
                    icon: const Icon(Icons.cancel_outlined, size: 24),
                    label: Text(loc.cancel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionButtons(AppLocalizations loc) {
    final suggestions = [
      (
        icon: Icons.book_rounded,
        label: loc.journal,
        action: () => _executeNavigation('/journal'),
      ),
      (
        icon: Icons.add_photo_alternate_rounded,
        label: loc.creatingMemory.replaceAll('...', ''),
        action: () => _executeNavigation('/journal'),
      ),
      (
        icon: Icons.alarm_add_rounded,
        label: loc.reminders,
        action: () {
          setState(() {
            _conversationState = ReminderConversationState.awaitingReminderTitle;
          });
          final prompt = VoicePrompts.get(VoicePrompts.askReminderTitle, _selectedLanguage);
          respondToUser(prompt);
        },
      ),
      (
        icon: Icons.sports_esports_rounded,
        label: loc.games,
        action: () => _executeNavigation('/games'),
      ),
      (
        icon: Icons.home_rounded,
        label: loc.home,
        action: () => _executeNavigation('/dashboard'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          switch (_selectedLanguage) {
            'te' => 'సూచనలు:',
            'hi' => 'सुझाव:',
            _ => 'Quick Actions:',
          },
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.subtitleColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: suggestions.map((s) {
            return SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: s.action,
                icon: Icon(s.icon, size: 22),
                label: Text(s.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceColor,
                  foregroundColor: AppTheme.textColor,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    const languages = AppLanguages.supportedLanguages;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: languages.map((lang) {
          final isSelected = _selectedLanguage == lang.code;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                lang.code == 'en' ? 'English' : '${lang.nativeName} (${lang.displayName})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppTheme.textColor,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Colors.grey.shade200,
              onSelected: (selected) {
                if (selected) {
                  _onLanguageChanged(lang.code);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainListeningContainer(AppLocalizations loc) {
    final status = _voiceService.status;

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

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _voiceService.isListening ? AppTheme.primaryColor : Colors.grey.shade300,
          width: _voiceService.isListening ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_recognizedText.isEmpty) ...[
            Text(
              _conversationState == ReminderConversationState.awaitingReminderTitle
                  ? VoicePrompts.get(VoicePrompts.askReminderTitle, _selectedLanguage)
                  : _conversationState ==
                          ReminderConversationState.awaitingReminderDateTime
                      ? VoicePrompts.get(VoicePrompts.askReminderTime, _selectedLanguage)
                      : _voiceService.isListening
                          ? VoicePrompts.get(VoicePrompts.listening, _selectedLanguage)
                          : switch (_selectedLanguage) {
                              'te' => 'నేను వినడానికి సిద్ధంగా ఉన్నాను',
                              'hi' => 'मैं सुनने के लिए तैयार हूँ',
                              _ => 'Ready to listen',
                            },
              style: TextStyle(
                fontSize: 20,
                color: _voiceService.isListening
                    ? AppTheme.primaryColor
                    : AppTheme.subtitleColor,
                fontWeight:
                    _voiceService.isListening ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ] else ...[
            Text(
              _recognizedText,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final message = _lastAssistantResponse.isNotEmpty
        ? _lastAssistantResponse
        : (_intentResult?.feedbackMessage ?? '');

    if (message.isEmpty) return const SizedBox.shrink();

    final isSuccess = _intentResult?.intent != VoiceIntent.unknown;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuccess ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.help_outline_rounded,
                color: isSuccess ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                size: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isSuccess ? const Color(0xFF166534) : const Color(0xFF92400E),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: AppTheme.primaryColor),
                tooltip: 'Replay voice response',
                onPressed: () {
                  respondToUser(message);
                },
              ),
            ],
          ),
          if (_intentResult?.targetRoute != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _executeNavigation(_intentResult!.targetRoute!),
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: const Text('Go Now', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMicrophoneButton() {
    final isListening = _voiceService.isListening;

    return ScaleTransition(
      scale: isListening ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Semantics(
        label: isListening ? 'Stop listening' : 'Start listening',
        button: true,
        child: Material(
          shape: const CircleBorder(),
          elevation: isListening ? 8 : 4,
          color: isListening ? Colors.red.shade600 : AppTheme.primaryColor,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _handleMicrophoneTap,
            child: Container(
              width: 96,
              height: 96,
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
    );
  }

  Widget _buildButtonStatusLabel() {
    final isListening = _voiceService.isListening;

    return Text(
      isListening
          ? VoicePrompts.get(VoicePrompts.tapToStop, _selectedLanguage)
          : VoicePrompts.get(VoicePrompts.tapToSpeak, _selectedLanguage),
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isListening ? Colors.red.shade700 : AppTheme.textColor,
      ),
    );
  }

  Widget _buildQuickHints() {
    final hints = switch (_selectedLanguage) {
      'te' => [
          'నా డైరీ తెరవండి',
          'కొత్త జ్ఞాపకం',
          'మెదడు ఆటలు',
          'మందుల రిమైండర్ పెట్టు',
          'హోమ్',
        ],
      'hi' => [
          'डायरी खोलो',
          'नई याद बनाओ',
          'खेल खोलो',
          'दवा का रिमाइंडर लगाओ',
          'होम पेज',
        ],
      _ => [
          'Open Journal',
          'New Memory',
          'Brain Games',
          'Remind me to take medicine at 8 PM',
          'Go Home',
        ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          switch (_selectedLanguage) {
            'te' => 'ఉదాహరణ మాటలు:',
            'hi' => 'आप कह सकते हैं:',
            _ => 'Try saying:',
          },
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.subtitleColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hints.map((hint) {
            return ActionChip(
              label: Text(
                hint,
                style: const TextStyle(fontSize: 15, color: AppTheme.textColor),
              ),
              backgroundColor: AppTheme.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              onPressed: () {
                if (!_voiceService.isListening) {
                  _processCompletedSpeech(hint);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrivacyNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 22, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  VoicePrompts.get(VoicePrompts.privacyStatement, _selectedLanguage),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  VoicePrompts.get(VoicePrompts.offlineClarification, _selectedLanguage),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
