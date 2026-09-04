import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../core/database/app_database.dart';
import '../../core/database/repositories/journal_repository.dart';

/// Screen for writing or editing a personal memory journal entry.
///
/// Strictly single-user and offline-first:
/// - Allows entering title, memory narrative, and picking/capturing a local photo.
/// - Prompts with warm reminiscence suggestions.
/// - Saves immediately to Drift SQLite and enqueues Outbox sync mutation.
class JournalEntryScreen extends StatefulWidget {
  final JournalRepository? repository;
  final JournalEntry? existingEntry;
  final ImagePicker? imagePicker;

  const JournalEntryScreen({
    super.key,
    this.repository,
    this.existingEntry,
    this.imagePicker,
  });

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  late final JournalRepository _repository;
  late final ImagePicker _picker;

  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  String? _photoPath;
  bool _isSaving = false;

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

    _titleController = TextEditingController(text: widget.existingEntry?.title ?? '');
    _bodyController = TextEditingController(text: widget.existingEntry?.body ?? '');
    _photoPath = widget.existingEntry?.photoPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
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
        );
      } else {
        // Create new memory
        await _repository.create(
          title: effectiveTitle,
          body: body,
          photoPath: _photoPath,
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

              // 5. Voice Note Preparation (Clean Option B architecture)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic_none_rounded,
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'কণ্ঠ বাৰ্তা (Voice Note)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Voice note recording will connect in Voice Assistant phase (Phase 3.3).',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 6. Save Button (Min 80dp tall)
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
