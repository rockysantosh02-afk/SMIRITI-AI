import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/database/repositories/reminder_repository.dart';
import '../../core/localization/app_localizations.dart';
import '../voice/screens/voice_assistant_screen.dart';
import 'reminder_entry_screen.dart';
import 'services/notification_service.dart';
import 'widgets/reminder_card.dart';

/// Elderly-friendly Reminders screen displaying TODAY, UPCOMING, and COMPLETED
/// sections with large touch targets, high contrast, and full offline-first reactivity.
class RemindersScreen extends StatefulWidget {
  final ReminderRepository? repository;
  final NotificationService? notificationService;

  const RemindersScreen({
    super.key,
    this.repository,
    this.notificationService,
  });

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late final ReminderRepository _repository;
  late final NotificationService _notificationService;
  late final Stream<List<Reminder>> _remindersStream;
  bool _hasNotificationPermission = true;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? ReminderRepository(DatabaseProvider.instance);
    _notificationService =
        widget.notificationService ?? LocalNotificationService();
    _remindersStream = _repository.watchAll();

    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await _notificationService.hasPermission();
    if (mounted) {
      setState(() {
        _hasNotificationPermission = granted;
      });
    }
  }

  Future<void> _handleComplete(Reminder reminder) async {
    await _repository.markComplete(reminder.id);
    await _notificationService
        .cancelReminder(notificationIdFromReminderId(reminder.id));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Completed "${reminder.title}"',
            style: const TextStyle(fontSize: 16),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  Future<void> _handleDelete(Reminder reminder) async {
    await _repository.delete(reminder.id);
    await _notificationService
        .cancelReminder(notificationIdFromReminderId(reminder.id));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Deleted "${reminder.title}"',
            style: const TextStyle(fontSize: 16),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    }
  }

  void _navigateToCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReminderEntryScreen(
          repository: _repository,
          notificationService: _notificationService,
        ),
      ),
    );
  }

  void _navigateToVoiceReminder() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoiceAssistantScreen(
          reminderFocus: true,
          reminderRepository: _repository,
          notificationService: _notificationService,
        ),
      ),
    );
  }

  void _navigateToEdit(Reminder reminder) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReminderEntryScreen(
          initialReminder: reminder,
          repository: _repository,
          notificationService: _notificationService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          loc.remindersTitle,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          tooltip: loc.back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        backgroundColor: const Color(0xFF006699),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 28),
        label: Text(
          loc.addReminder,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Two Large Accessible Entry Buttons: TYPE REMINDER & SPEAK REMINDER
            _buildTopActionButtons(loc),

            // Permission Warning Banner (if notifications are disabled)
            if (!_hasNotificationPermission)
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF3E0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_off_rounded,
                        color: Color(0xFFE65100), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.notificationsDisabledWarning,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Main Content
            Expanded(
              child: StreamBuilder<List<Reminder>>(
                stream: _remindersStream,
                initialData: const <Reminder>[],
                builder: (context, snapshot) {
                  final reminders = snapshot.data ?? [];
                  return reminders.isEmpty
                      ? _buildEmptyState(loc)
                      : _buildRemindersList(reminders, loc);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopActionButtons(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 64,
              child: ElevatedButton.icon(
                onPressed: _navigateToCreate,
                icon: const Icon(Icons.keyboard_alt_rounded, size: 26),
                label: Text(
                  '⌨ ${loc.typeReminder.toUpperCase()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006699),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 64,
              child: ElevatedButton.icon(
                onPressed: _navigateToVoiceReminder,
                icon: const Icon(Icons.mic_rounded, size: 26),
                label: Text(
                  '🎤 ${loc.speakReminder.toUpperCase()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFE1F5FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.alarm_on_rounded,
                size: 72,
                color: Color(0xFF006699),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.noReminders,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.noRemindersDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006699),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _navigateToCreate,
                icon: const Icon(Icons.add_rounded, size: 26),
                label: Text(
                  loc.addReminder,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersList(List<Reminder> reminders, AppLocalizations loc) {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final todayList = <Reminder>[];
    final upcomingList = <Reminder>[];
    final completedList = <Reminder>[];

    for (final reminder in reminders) {
      if (ReminderRepository.isCompleted(reminder)) {
        completedList.add(reminder);
      } else if (ReminderRepository.isDaily(reminder)) {
        todayList.add(reminder);
      } else {
        // One-time reminder
        final scheduled = ReminderRepository.parseScheduledDateTime(reminder);
        if (scheduled != null) {
          final reminderDateStr =
              '${scheduled.year}-${scheduled.month.toString().padLeft(2, '0')}-${scheduled.day.toString().padLeft(2, '0')}';
          if (reminderDateStr == todayStr) {
            todayList.add(reminder);
          } else {
            upcomingList.add(reminder);
          }
        } else {
          todayList.add(reminder);
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 88),
      children: [
        // TODAY Section
        if (todayList.isNotEmpty) ...[
          _buildSectionHeader(loc.today.toUpperCase(), Icons.today_rounded, const Color(0xFFE65100)),
          ...todayList.map((r) => ReminderCard(
                reminder: r,
                onComplete: () => _handleComplete(r),
                onEdit: () => _navigateToEdit(r),
                onDelete: () => _handleDelete(r),
              )),
          const SizedBox(height: 16),
        ],

        // UPCOMING Section
        if (upcomingList.isNotEmpty) ...[
          _buildSectionHeader(
              loc.upcoming.toUpperCase(), Icons.upcoming_rounded, const Color(0xFF0277BD)),
          ...upcomingList.map((r) => ReminderCard(
                reminder: r,
                onComplete: () => _handleComplete(r),
                onEdit: () => _navigateToEdit(r),
                onDelete: () => _handleDelete(r),
              )),
          const SizedBox(height: 16),
        ],

        // COMPLETED Section
        if (completedList.isNotEmpty) ...[
          _buildSectionHeader(
              loc.completed.toUpperCase(), Icons.task_alt_rounded, const Color(0xFF2E7D32)),
          ...completedList.map((r) => ReminderCard(
                reminder: r,
                onComplete: () {},
                onEdit: () => _navigateToEdit(r),
                onDelete: () => _handleDelete(r),
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
