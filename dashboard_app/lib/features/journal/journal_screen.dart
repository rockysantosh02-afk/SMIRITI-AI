import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/database/app_database.dart';
import '../../core/database/repositories/journal_repository.dart';
import 'journal_entry_screen.dart';

/// Screen for displaying the user's private Personal Memory Journal.
///
/// Strictly single-user, offline-first:
/// - Reads reactively from Drift SQLite via JournalRepository.watchAll()
/// - Displays memories in reverse chronological order (newest first)
/// - Large accessible cards with >=80dp interactive buttons and high contrast
class JournalScreen extends StatefulWidget {
  final JournalRepository? repository;

  const JournalScreen({super.key, this.repository});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late final JournalRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? JournalRepository(DatabaseProvider.instance);
  }

  void _openNewEntryScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JournalEntryScreen(repository: _repository),
      ),
    );
  }

  void _openEditEntryScreen(JournalEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JournalEntryScreen(
          repository: _repository,
          existingEntry: entry,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'স্মৃতি আঁতৰাবনে? (Remove Memory?)',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        content: Text(
          'আপুনি "${entry.title.isNotEmpty ? entry.title : 'এই স্মৃতি'}" আঁতৰাব বিচাৰিছেনে? (Are you sure you want to remove this memory?)',
          style: const TextStyle(fontSize: 18, color: AppTheme.subtitleColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(minimumSize: const Size(100, 56)),
            child: const Text(
              'থাকক (Keep)',
              style: TextStyle(fontSize: 18, color: AppTheme.primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(110, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'আঁতৰাওক (Remove)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _repository.softDelete(entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.primaryColor,
            content: Text(
              'স্মৃতি আঁতৰোৱা হ\'ল (Memory removed)',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'মোৰ দিনলিপি (My Journal)',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          tooltip: 'Back to Dashboard',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top encouragement & Privacy reassurance banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: AppTheme.primaryColor,
                    size: 26,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'আপোনাৰ দিনলিপি সম্পূৰ্ণ নিজা আৰু সুৰক্ষিত। (Your memory journal is completely private to you.)',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Memories list stream
            Expanded(
              child: StreamBuilder<List<JournalEntry>>(
                stream: _repository.watchAll(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    );
                  }

                  final entries = snapshot.data ?? [];

                  if (entries.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _buildMemoryCard(entry);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          height: 80,
          child: ElevatedButton.icon(
            key: const Key('add_memory_button'),
            onPressed: _openNewEntryScreen,
            icon: const Icon(Icons.add_rounded, size: 36),
            label: const Text(
              'নতুন স্মৃতি যোগ কৰক\n(+ Add Memory)',
              textAlign: TextAlign.center,
              style: TextStyle(
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'আপোনাৰ স্মৃতিবোৰ ইয়াত সংৰক্ষিত থাকিব\n(Your memories will appear here)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'প্ৰতিটো স্মৃতিয়েই বিশেষ আৰু আনন্দদায়ক।\n(Every memory is special and treasured.)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.subtitleColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 80,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openNewEntryScreen,
                icon: const Icon(Icons.edit_note_rounded, size: 36),
                label: const Text(
                  'প্ৰথম স্মৃতি যোগ কৰক\n(Add Your First Memory)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: AppTheme.textColor,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryCard(JournalEntry entry) {
    final dateFormat = DateFormat('d MMMM yyyy, h:mm a');
    final formattedDate = dateFormat.format(entry.createdAt);
    final hasPhoto = entry.photoPath != null &&
        entry.photoPath!.isNotEmpty &&
        File(entry.photoPath!).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppTheme.primaryColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      color: AppTheme.surfaceColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openEditEntryScreen(entry),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Thumbnail (if attached)
              if (hasPhoto) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(entry.photoPath!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Header Row: Title & Delete Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      entry.title.isNotEmpty ? entry.title : 'স্মৃতি (Memory)',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                        height: 1.25,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 28),
                    color: Colors.grey[600],
                    tooltip: 'Remove Memory',
                    onPressed: () => _confirmDelete(entry),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Date chip
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: AppTheme.subtitleColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              if (entry.body.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  entry.body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppTheme.textColor,
                    height: 1.4,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Tap hint
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'চাবলৈ বা সলাবলৈ স্পৰ্শ কৰক (Tap to view / edit)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
