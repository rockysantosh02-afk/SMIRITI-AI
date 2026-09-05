import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
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

  Future<void> _confirmDelete(JournalEntry entry, AppLocalizations loc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.deleteMemoryConfirmTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        content: Text(
          entry.title.isNotEmpty
              ? '${loc.deleteMemoryConfirmMessage}\n\n"${entry.title}"'
              : loc.deleteMemoryConfirmMessage,
          style: const TextStyle(fontSize: 18, color: AppTheme.subtitleColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(minimumSize: const Size(100, 56)),
            child: Text(
              loc.cancel,
              style: const TextStyle(fontSize: 18, color: AppTheme.primaryColor),
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
            child: Text(
              loc.delete,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _repository.softDelete(entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primaryColor,
            content: Text(
              loc.deleteEntry,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          loc.journal,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          tooltip: loc.back,
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
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: AppTheme.primaryColor,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc.journalPrivacyNotice,
                      style: const TextStyle(
                        fontSize: 15,
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
                    return _buildEmptyState(loc);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _buildMemoryCard(entry, loc);
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
            label: Text(
              loc.newEntry,
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
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
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
            Text(
              loc.noMemoriesYet,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.emptyJournalDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
                label: Text(
                  loc.writeFirstMemory,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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

  Widget _buildMemoryCard(JournalEntry entry, AppLocalizations loc) {
    final dateFormat = DateFormat('d MMMM yyyy, h:mm a');
    final formattedDate = dateFormat.format(entry.createdAt);
    final hasPhotoPath = entry.photoPath != null && entry.photoPath!.isNotEmpty;
    final photoExists = hasPhotoPath && File(entry.photoPath!).existsSync();

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
              // Photo Thumbnail (or graceful fallback if file missing)
              if (hasPhotoPath) ...[
                if (photoExists)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(entry.photoPath!),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPhotoFallback(),
                    ),
                  )
                else
                  _buildPhotoFallback(),
                const SizedBox(height: 14),
              ],

              // Header Row: Title & Delete Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      entry.title.isNotEmpty ? entry.title : loc.memoryTitle,
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
                    tooltip: loc.deleteEntry,
                    onPressed: () => _confirmDelete(entry, loc),
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

              // AI Generated Story Section (Phase 3.2)
              if (entry.generatedStory != null && entry.generatedStory!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
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
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            loc.storyReflection,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.generatedStory!,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.45,
                          color: AppTheme.textColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Tap hint
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    loc.editEntry,
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

  Widget _buildPhotoFallback() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.subtitleColor.withValues(alpha: 0.2),
        ),
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_rounded,
              size: 28,
              color: AppTheme.subtitleColor,
            ),
            SizedBox(width: 10),
            Text(
              'Photo not found on device',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
