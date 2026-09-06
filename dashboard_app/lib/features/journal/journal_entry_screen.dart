import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/localization/app_languages.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_provider.dart';
import '../../core/database/app_database.dart';
import '../../core/database/repositories/journal_repository.dart';
import 'journal_story_service.dart';
import '../voice/services/voice_service.dart';

/// Screen for creating or editing a private Personal Memory Journal entry.
///
/// Strictly single-user and offline-first:
/// - Immediate local SQLite persistence via JournalRepository.
/// - Outbox synchronization enqueued without cloud delay.
/// - Optional AI Story Generator powered by JournalStoryService.
/// - 80dp touch targets, high contrast, warm guidance.
/// - Push-to-talk Voice Dictation for hands-free memory authoring.
class JournalEntryScreen extends StatefulWidget {
  final JournalRepository? repository;
  final ImagePicker? imagePicker;
  final JournalStoryService? storyService;
  final IVoiceService? voiceService;
  final JournalEntry? existingEntry;

  const JournalEntryScreen({
    super.key,
    this.repository,
    this.imagePicker,
    this.storyService,
    this.voiceService,
    this.existingEntry,
  });

  /// Safely append dictated text to existing text.
  /// - If existing text is empty, returns clean dictated text.
  /// - If existing text is non-empty, returns "$cleanExisting\n$cleanDictated".
  /// - If dictated text is empty, returns existing text unchanged.
  static String appendDictatedText(String existing, String dictated) {
    final cleanDictated = dictated.trim();
    if (cleanDictated.isEmpty) return existing;
    final cleanExisting = existing.trim();
    if (cleanExisting.isEmpty) return cleanDictated;
    return '$cleanExisting\n$cleanDictated';
  }

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  late final JournalRepository _repository;
  late final ImagePicker _picker;
  late final JournalStoryService _storyService;
  late final IVoiceService _voiceService;

  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  String? _photoPath;
  String? _generatedStory;
  bool _isSaving = false;
  bool _isGeneratingStory = false;
  bool _isDictating = false;
  String _dictationLivePreview = '';

  List<String> _getReminiscencePrompts(AppLocalizations loc) => [
        loc.memoryPrompt1,
        loc.memoryPrompt2,
        loc.memoryPrompt3,
        loc.memoryPrompt4,
      ];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? JournalRepository(DatabaseProvider.instance);
    _picker = widget.imagePicker ?? ImagePicker();
    _storyService = widget.storyService ?? JournalStoryService();
    _voiceService = widget.voiceService ?? VoiceService();

    _titleController = TextEditingController(text: widget.existingEntry?.title ?? '');
    _bodyController = TextEditingController(text: widget.existingEntry?.body ?? '');
    _photoPath = widget.existingEntry?.photoPath;
    _generatedStory = widget.existingEntry?.generatedStory;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    if (widget.voiceService == null) {
      _voiceService.dispose();
    }
    super.dispose();
  }

  void _handleVoiceDictation() {
    if (_isDictating) {
      _stopDictation();
    } else {
      _startDictation();
    }
  }

  void _startDictation() {
    String? langCode;
    try {
      langCode = Provider.of<LanguageProvider>(context, listen: false).languageCode;
    } catch (_) {}
    final effectiveLang = langCode ?? 'en';

    if (_voiceService.availableLocales.isNotEmpty &&
        !_voiceService.isLanguageSupported(effectiveLang)) {
      final loc = AppLocalizations.of(context);
      final warning = effectiveLang == 'te'
          ? 'ఈ పరికరంలో తెలుగు వాయిస్ గుర్తింపు అందుబాటులో లేదు. దయచేసి Android సెట్టింగ్స్‌లో ఎనేబుల్ చేయండి.'
          : (effectiveLang == 'hi'
              ? 'इस डिवाइस पर हिन्दी आवाज़ पहचान उपलब्ध नहीं है. कृपया Android सेटिंग्स में सक्षम करें.'
              : loc.speechUnavailableForLanguage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(warning, style: const TextStyle(fontSize: 16)),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isDictating = true;
      _dictationLivePreview = '';
    });

    _voiceService.startListening(
      languageCode: effectiveLang,
      onResult: (words) {
        if (mounted) {
          setState(() {
            _dictationLivePreview = words;
          });
        }
      },
      onComplete: () {
        if (mounted) {
          _finalizeDictation(_dictationLivePreview);
        }
      },
    );
  }

  void _stopDictation() {
    _voiceService.stopListening();
    _finalizeDictation(_dictationLivePreview);
  }

  void _finalizeDictation(String text) {
    if (!_isDictating) return;

    final updated = JournalEntryScreen.appendDictatedText(_bodyController.text, text);
    if (mounted) {
      setState(() {
        _isDictating = false;
        _dictationLivePreview = '';
        _bodyController.text = updated;
        _bodyController.selection = TextSelection.collapsed(offset: updated.length);
      });
    }
  }

  Future<void> _handleGenerateStory() async {
    if (_isGeneratingStory) return;

    final memoryText = _bodyController.text.trim();
    if (memoryText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.secondaryColor,
            content: Text(
              'Please write a little memory before creating a story.',
              style: TextStyle(fontSize: 16, color: AppTheme.textColor),
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _isGeneratingStory = true;
    });

    String languageName = 'English';
    try {
      final lang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      languageName = lang.displayName;
    } catch (_) {}

    try {
      final storyResult = await _storyService.generateStory(
        title: _titleController.text.trim(),
        content: memoryText,
        language: languageName,
      );

      if (storyResult.success && storyResult.story != null) {
        if (mounted) {
          setState(() {
            _generatedStory = storyResult.story;
          });
        }

        // If this entry is already saved in SQLite, persist the story immediately
        if (widget.existingEntry != null) {
          await _repository.saveGeneratedStory(
            id: widget.existingEntry!.id,
            story: storyResult.story!,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.primaryColor,
              content: Text(
                'Your story is ready!',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.primaryColor,
              content: Text(
                storyResult.errorMessage ??
                    'Your memory is safely saved. We can create a story when you are connected.',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[JournalEntryScreen] Story generation exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.primaryColor,
            content: Text(
              'Your memory is safely saved. We can create a story when you are connected.',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingStory = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (picked != null && mounted) {
        setState(() {
          _photoPath = picked.path;
        });
      }
    } catch (e) {
      debugPrint('[JournalEntryScreen] Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.errorColor,
            content: Text(
              'Could not attach photo. Please try again.',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;

    final bodyText = _bodyController.text.trim();
    final titleText = _titleController.text.trim();

    if (bodyText.isEmpty && titleText.isEmpty && _photoPath == null) {
      final validationMsg = Localizations.localeOf(context).languageCode == 'te'
          ? 'దయచేసి మీ జ్ఞాపకాన్ని నమోదు చేయండి. అవసరమైన వివరాలను పూరించండి.'
          : (Localizations.localeOf(context).languageCode == 'hi'
              ? 'कृपया अपनी याद दर्ज करें. आवश्यक विवरण भरें.'
              : 'Please add a little memory before saving. Please fill in the required details.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.secondaryColor,
          content: Text(
            validationMsg,
            style: const TextStyle(fontSize: 16, color: AppTheme.textColor),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final loc = AppLocalizations.of(context);
    final effectiveTitle = titleText.isNotEmpty
        ? titleText
        : (bodyText.isNotEmpty
            ? (bodyText.length > 30 ? '${bodyText.substring(0, 30)}...' : bodyText)
            : loc.newEntry);

    String preferredLanguage = 'English';
    try {
      final lang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      preferredLanguage = lang.displayName;
    } catch (_) {}

    try {
      // 1. ALWAYS SAVE TO SQLITE FIRST
      String savedId;
      if (widget.existingEntry != null) {
        savedId = widget.existingEntry!.id;
        await _repository.update(
          id: savedId,
          title: effectiveTitle,
          body: bodyText,
          photoPath: _photoPath,
          generatedStory: _generatedStory,
        );
      } else {
        savedId = await _repository.create(
          title: effectiveTitle,
          body: bodyText,
          photoPath: _photoPath,
          generatedStory: _generatedStory,
        );
      }

      // 2. ATTEMPT STORY GENERATION IF NOT ALREADY GENERATED
      if (_generatedStory == null && bodyText.isNotEmpty) {
        try {
          final storyResult = await _storyService.generateStory(
            title: effectiveTitle,
            content: bodyText,
            language: preferredLanguage,
          );
          if (storyResult.success && storyResult.story != null) {
            _generatedStory = storyResult.story;
            await _repository.saveGeneratedStory(
              id: savedId,
              story: storyResult.story!,
            );
          }
        } catch (storyErr) {
          debugPrint('[JournalEntryScreen] Story generation skipped/failed: $storyErr');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primaryColor,
            content: Text(
              loc.memorySavedSuccess,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('[JournalEntryScreen] Error saving entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.errorColor,
            content: Text(
              loc.memorySaveError,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isEditing = widget.existingEntry != null;
    final prompts = _getReminiscencePrompts(loc);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? loc.editEntry : loc.newEntry,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          tooltip: loc.back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Reminiscence inspiration prompts
              Text(
                loc.inspirationPrompts,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: prompts.map((prompt) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ActionChip(
                        backgroundColor: AppTheme.surfaceColor,
                        side: BorderSide(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        avatar: const Icon(Icons.lightbulb_outline_rounded,
                            size: 20, color: AppTheme.secondaryColor),
                        label: Text(
                          prompt,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                        onPressed: () {
                          if (_titleController.text.isEmpty) {
                            _titleController.text = prompt;
                          } else if (_bodyController.text.isEmpty) {
                            _bodyController.text = prompt;
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // 2. Title Input
              Text(
                loc.memoryTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('journal_title_input'),
                controller: _titleController,
                style: const TextStyle(fontSize: 20, color: AppTheme.textColor),
                decoration: InputDecoration(
                  hintText: loc.memoryTitleHint,
                  hintStyle: TextStyle(fontSize: 17, color: Colors.grey[500]),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(18),
                ),
              ),

              const SizedBox(height: 20),

              // 3. Memory Content / Story Input
              Text(
                loc.yourMemory,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('journal_body_input'),
                controller: _bodyController,
                maxLines: 6,
                style: const TextStyle(fontSize: 20, height: 1.4, color: AppTheme.textColor),
                decoration: InputDecoration(
                  hintText: loc.yourMemoryHint,
                  hintStyle: TextStyle(fontSize: 17, color: Colors.grey[500]),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(18),
                ),
              ),

              const SizedBox(height: 24),

              // 4. Photo Section
              Text(
                loc.addPhoto,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 10),

              if (_photoPath != null) ...[
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: File(_photoPath!).existsSync()
                          ? Image.file(
                              File(_photoPath!),
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image_rounded, size: 28, color: AppTheme.subtitleColor),
                                      SizedBox(width: 8),
                                      Text(
                                        'Could not display photo',
                                        style: TextStyle(fontSize: 15, color: AppTheme.subtitleColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.subtitleColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_rounded, size: 28, color: AppTheme.subtitleColor),
                                    SizedBox(width: 8),
                                    Text(
                                      'Photo not found on device',
                                      style: TextStyle(fontSize: 15, color: AppTheme.subtitleColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        tooltip: 'Remove photo',
                        onPressed: () => setState(() => _photoPath = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: OutlinedButton.icon(
                        key: const Key('pick_gallery_button'),
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded, size: 28),
                        label: Text(
                          loc.gallery,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: OutlinedButton.icon(
                        key: const Key('pick_camera_button'),
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded, size: 28),
                        label: Text(
                          loc.camera,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 5. Voice Dictation ("Speak Your Memory")
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isDictating
                      ? AppTheme.primaryColor.withValues(alpha: 0.08)
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isDictating
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withValues(alpha: 0.2),
                    width: _isDictating ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Material(
                          color: _isDictating ? Colors.red.shade600 : AppTheme.primaryColor,
                          shape: const CircleBorder(),
                          elevation: _isDictating ? 4 : 2,
                          child: InkWell(
                            key: const Key('voice_dictation_button'),
                            customBorder: const CircleBorder(),
                            onTap: _handleVoiceDictation,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Icon(
                                _isDictating ? Icons.stop_rounded : Icons.mic_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isDictating
                                    ? loc.listeningDictation
                                    : loc.speakYourMemory,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _isDictating
                                      ? Colors.red.shade700
                                      : AppTheme.textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isDictating
                                    ? loc.stopDictation
                                    : loc.dictateHint,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_dictationLivePreview.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '$_dictationLivePreview...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 6. AI Story Generator Section (Phase 3.2)
              Text(
                loc.aiStory,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 10),

              if (_generatedStory != null && _generatedStory!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppTheme.primaryColor,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              loc.storyReflection,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _generatedStory!,
                        key: const Key('generated_story_text'),
                        style: const TextStyle(
                          fontSize: 19,
                          height: 1.45,
                          color: AppTheme.textColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          key: const Key('regenerate_story_button'),
                          onPressed: _isGeneratingStory ? null : _handleGenerateStory,
                          icon: _isGeneratingStory
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                                )
                              : const Icon(Icons.refresh_rounded, size: 22, color: AppTheme.primaryColor),
                          label: Text(
                            _isGeneratingStory ? loc.creatingStory : loc.createAiStory,
                            style: const TextStyle(fontSize: 16, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                SizedBox(
                  height: 70,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('generate_story_button'),
                    onPressed: _isGeneratingStory ? null : _handleGenerateStory,
                    icon: _isGeneratingStory
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 30),
                    label: Text(
                      _isGeneratingStory
                          ? loc.creatingStory
                          : loc.createAiStory,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              // 7. Save Button (Min 80dp tall)
              SizedBox(
                height: 80,
                child: ElevatedButton.icon(
                  key: const Key('save_memory_button'),
                  onPressed: _isSaving ? null : _saveEntry,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 36),
                  label: Text(
                    _isSaving ? loc.savingEntry : loc.saveEntry,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.onPrimaryColor,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
