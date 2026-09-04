import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
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
  String _storySource = 'ai';
  bool _isSaving = false;
  bool _isGeneratingStory = false;
  bool _isDictating = false;
  String _dictationLivePreview = '';

  final List<String> _reminiscencePrompts = [
    'Tell me about a happy memory (এটা সুখৰ স্মৃতি কওক)',
    'Tell me about this special day (এই বিশেষ দিনটোৰ কথা মনত আছেনে?)',
    'What do you remember about this place? (এই ঠাইখনৰ কি মনত পৰে?)',
    'A memory of family or friends (পৰিয়াল বা বন্ধুৰ সৈতে এটা স্মৃতি)',
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
    setState(() {
      _isDictating = true;
      _dictationLivePreview = '';
    });

    _voiceService.startListening(
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

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty && body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.secondaryColor,
          content: Text(
            'অনুগ্ৰহ কৰি কাহিনী তৈয়াৰ কৰাৰ আগতে অলপ স্মৃতি লিখক।\n(Please write a little memory before creating a story.)',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isGeneratingStory = true);

    try {
      final result = await _storyService.generateStory(
        title: title,
        content: body,
      );

      if (!mounted) return;

      if (result.success && result.story != null) {
        setState(() {
          _generatedStory = result.story;
          _storySource = result.source;
          _isGeneratingStory = false;
        });

        // If this entry is already saved in SQLite, persist the story immediately
        if (widget.existingEntry != null) {
          await _repository.saveGeneratedStory(
            id: widget.existingEntry!.id,
            story: result.story!,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF2E8B57), // Sea green
              content: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'আপোনাৰ সুন্দৰ কাহিনী প্ৰস্তুত হ\'ল!\n(Your story is ready!)',
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _isGeneratingStory = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.surfaceColor,
              content: Text(
                result.errorMessage ??
                    'আমি এই মুহূৰ্তত কাহিনী সৃষ্টি কৰিব নোৱাৰিলোঁ। আপোনাৰ স্মৃতি সুৰক্ষিত হৈ আছে।\n(We could not create a story right now. Your memory is safely saved.)',
                style: const TextStyle(fontSize: 16, color: AppTheme.textColor, fontWeight: FontWeight.w600),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingStory = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.surfaceColor,
            content: Text(
              'আমি এই মুহূৰ্তত কাহিনী সৃষ্টি কৰিব নোৱাৰিলোঁ। আপোনাৰ স্মৃতি সুৰক্ষিত হৈ আছে।\n(We could not create a story right now. Your memory is safely saved.)',
              style: TextStyle(fontSize: 16, color: AppTheme.textColor, fontWeight: FontWeight.w600),
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() {
          _photoPath = image.path;
        });
      }
    } catch (e) {
      debugPrint('[JournalEntryScreen] Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.primaryColor,
            content: Text(
              'ছবি যোগ কৰিব পৰা নগল (Could not attach photo. Please try again.)',
              style: TextStyle(fontSize: 16),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    // Validation: Require at least some title, body, or photo
    if (title.isEmpty && body.isEmpty && _photoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.secondaryColor,
          content: Text(
            'অনুগ্ৰহ কৰি সংৰক্ষণ কৰাৰ আগতে অলপ স্মৃতি যোগ কৰক।\n(Please add a little memory before saving.)',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final effectiveTitle = title.isNotEmpty
          ? title
          : (body.isNotEmpty
              ? (body.length > 30 ? '${body.substring(0, 30)}...' : body)
              : 'স্মৃতি (Memory)');

      if (widget.existingEntry != null) {
        // Update existing memory
        await _repository.update(
          id: widget.existingEntry!.id,
          title: effectiveTitle,
          body: body,
          photoPath: _photoPath,
          generatedStory: _generatedStory,
        );
      } else {
        // Create new memory
        await _repository.create(
          title: effectiveTitle,
          body: body,
          photoPath: _photoPath,
          generatedStory: _generatedStory,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF2E8B57), // Sea green
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'আপোনাৰ স্মৃতি সুৰক্ষিতভাৱে সাঁচি ৰখা হ\'ল।\n(Beautiful memory saved.)',
                    style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('[JournalEntryScreen] Error saving journal entry: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.primaryColor,
            content: Text(
              'বৰ্তমান এই স্মৃতি সাঁচিব পৰা নগল, অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।\n(We could not save this memory right now. Please try again.)',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingEntry != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'স্মৃতি সম্পাদনা (Edit Memory)' : 'নতুন স্মৃতি (New Memory)',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          tooltip: 'Back',
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
              const Text(
                'প্ৰেৰণাদায়ক প্ৰশ্ন (Inspiration Prompts):',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _reminiscencePrompts.map((prompt) {
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
                            _titleController.text = prompt.split('(').first.trim();
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
              const Text(
                'স্মৃতিৰ শিৰোনাম (Title):',
                style: TextStyle(
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
                  hintText: 'e.g., বাগিচাত পুৱাৰ চাহ (Morning tea in the garden)',
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
              const Text(
                'আপোনাৰ স্মৃতি লিখক (Your Memory):',
                style: TextStyle(
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
                  hintText: 'আপোনাৰ মনত থকা কথাখিনি ইয়াত লিখক...\n(Write what you remember about this time...)',
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
              const Text(
                'ছবি যোগ কৰক (Add Photo):',
                style: TextStyle(
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
                                        'ছবি প্ৰদৰ্শন কৰিব পৰা নগ\'ল (Could not display photo)',
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
                                      'ছবি উপলব্ধ নহয় (Photo not found on device)',
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
                        label: const Text(
                          'গেলেৰী (Gallery)',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                        label: const Text(
                          'কেমেৰা (Camera)',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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

              // 5. Voice Dictation ("Speak Your Memory" / "কণ্ঠৰে স্মৃতি কওক")
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
                              padding: const EdgeInsets.all(16), // Comfortable touch target
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
                                    ? 'শুনি থকা হৈছে... (Listening...)'
                                    : 'কণ্ঠৰে স্মৃতি কওক (Speak Your Memory)',
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
                                    ? 'থামিবলৈ বুটামটো টিপক (Tap button to stop)'
                                    : 'ক\'লে আপোনাৰ কথা তলৰ ডায়ৰীত যোগ হ\'ব (Dictate directly into memory)',
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
              const Text(
                'স্মৃতিৰ কাহিনী (AI Story):',
                style: TextStyle(
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
                              _storySource == 'fallback'
                                  ? '✨ স্মৃতিৰ এক শান্ত প্ৰতিফলন (A gentle reflection)'
                                  : '✨ আপোনাৰ কাহিনী (Your Story)',
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
                            _isGeneratingStory ? 'কাহিনী তৈয়াৰ কৰা হৈছে... (Creating...)' : 'নতুন গল্প বনাওক (Create a New Story)',
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
                          ? 'কাহিনী তৈয়াৰ কৰা হৈছে...\n(Creating your story...)'
                          : 'গল্প বনাওক\n(✨ Create a Story)',
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
                    _isSaving ? 'সাঁচি থকা হৈছে... (Saving...)' : 'স্মৃতি সাঁচি ৰাখক\n(Save Memory)',
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
