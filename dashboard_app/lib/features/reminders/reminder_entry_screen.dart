import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/database/repositories/reminder_repository.dart';
import 'services/notification_service.dart';

/// Screen to create or edit a reminder with elderly-friendly accessibility controls,
/// clear 12-hour AM/PM time pickers, and duplicate-save protection.
class ReminderEntryScreen extends StatefulWidget {
  final Reminder? initialReminder;
  final ReminderRepository? repository;
  final NotificationService? notificationService;

  const ReminderEntryScreen({
    super.key,
    this.initialReminder,
    this.repository,
    this.notificationService,
  });

  @override
  State<ReminderEntryScreen> createState() => _ReminderEntryScreenState();
}

class _ReminderEntryScreenState extends State<ReminderEntryScreen> {
  late final TextEditingController _titleController;
  late final ReminderRepository _repository;
  late final NotificationService _notificationService;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late bool _isDaily;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? ReminderRepository(DatabaseProvider.instance);
    _notificationService =
        widget.notificationService ?? LocalNotificationService();

    final initial = widget.initialReminder;
    if (initial != null) {
      _titleController = TextEditingController(text: initial.title);
      _isDaily = ReminderRepository.isDaily(initial);

      final scheduled = ReminderRepository.parseScheduledDateTime(initial);
      if (scheduled != null) {
        _selectedDate =
            DateTime(scheduled.year, scheduled.month, scheduled.day);
        _selectedTime =
            TimeOfDay(hour: scheduled.hour, minute: scheduled.minute);
      } else {
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
      }
    } else {
      _titleController = TextEditingController();
      final now = DateTime.now();
      final defaultTime = now.add(const Duration(hours: 1));
      _selectedDate =
          DateTime(defaultTime.year, defaultTime.month, defaultTime.day);
      _selectedTime =
          TimeOfDay(hour: defaultTime.hour, minute: defaultTime.minute);
      _isDaily = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      helpText: 'Select Reminder Date',
      confirmText: 'Confirm',
      cancelText: 'Cancel',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Select Reminder Time',
      confirmText: 'Confirm',
      cancelText: 'Cancel',
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _errorMessage = null;
      });
    }
  }

  Future<void> _saveReminder() async {
    // Re-entrancy guard against rapid taps
    if (_isSaving) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter what you would like to be reminded about.';
      });
      return;
    }

    var scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // If one-time reminder was selected for today but time already passed,
    // advance date to tomorrow for elderly convenience and valid scheduling.
    if (!_isDaily && scheduledDateTime.isBefore(DateTime.now())) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      _selectedDate = DateTime(
        scheduledDateTime.year,
        scheduledDateTime.month,
        scheduledDateTime.day,
      );
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final timeOfDayStr =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      final daysOfWeekStr = _isDaily
          ? '1,2,3,4,5,6,7'
          : 'once:${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      String reminderId;
      if (widget.initialReminder != null) {
        reminderId = widget.initialReminder!.id;
        await _repository.update(
          id: reminderId,
          title: title,
          timeOfDay: timeOfDayStr,
          daysOfWeek: daysOfWeekStr,
          enabled: true,
        );
      } else {
        reminderId = await _repository.create(
          title: title,
          timeOfDay: timeOfDayStr,
          daysOfWeek: daysOfWeekStr,
          enabled: true,
        );
      }

      // Schedule local notification (Isolated in try-catch so failure does NOT block SQLite save)
      try {
        final notificationId = notificationIdFromReminderId(reminderId);
        final hasPermission = await _notificationService.hasPermission();

        if (!hasPermission) {
          await _notificationService.requestPermission();
        }

        final scheduleSuccess = await _notificationService.scheduleReminder(
          notificationId: notificationId,
          title: 'Reminder: $title',
          body: 'It is time for your reminder: $title',
          scheduledDate: scheduledDateTime,
          isDaily: _isDaily,
        );

        if (mounted) {
          if (!scheduleSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Your reminder was saved. Notifications are currently turned off.',
                  style: TextStyle(fontSize: 16),
                ),
                duration: Duration(seconds: 4),
                backgroundColor: Color(0xFFE65100),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Reminder saved successfully!',
                  style: TextStyle(fontSize: 16),
                ),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF2E7D32),
              ),
            );
          }
        }
      } catch (notifErr) {
        debugPrint(
            '[ReminderEntryScreen] Notification scheduling warning: $notifErr');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Reminder saved locally.',
                style: TextStyle(fontSize: 16),
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      debugPrint('[ReminderEntryScreen] Save error: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not save reminder. Please try again.';
        });
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
    final isEditing = widget.initialReminder != null;
    final formattedDate =
        DateFormat('EEEE, MMMM d, y').format(_selectedDate);
    final formattedTime = DateFormat('h:mm a').format(DateTime(
      2026,
      1,
      1,
      _selectedTime.hour,
      _selectedTime.minute,
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Reminder' : 'New Reminder',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error Banner (if any)
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC62828), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Color(0xFFC62828), size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC62828),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Reminder Title Section
              const Text(
                'What is this reminder for?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('reminder_title_field'),
                controller: _titleController,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'e.g., Take morning medicine',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: const Icon(Icons.notifications_active_rounded,
                      size: 26, color: Color(0xFF006699)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),

              // Time Picker Card (Accessible, large touch target)
              // Time Picker Card (Clean, Simple, Large for elderly users)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF006699),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time_filled_rounded,
                          size: 26,
                          color: Color(0xFF006699),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Reminder Time',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006699),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const Key('change_time_button'),
                        onPressed: _pickTime,
                        icon: const Icon(Icons.edit_calendar_rounded, size: 22),
                        label: const Text(
                          'Change Time',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF006699),
                          side: const BorderSide(color: Color(0xFF006699), width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Daily Switch Tile
              Material(
                color: const Color(0xFFF9F9F9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Repeat every day',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _isDaily
                        ? 'This reminder will sound daily at $formattedTime.'
                        : 'This reminder is for a specific date.',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade700),
                  ),
                  value: _isDaily,
                  activeThumbColor: const Color(0xFF006699),
                  onChanged: (val) {
                    setState(() {
                      _isDaily = val;
                      _errorMessage = null;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Date Picker Card (Visible only when not daily)
              if (!_isDaily) ...[
                const Text(
                  'Reminder Date',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            size: 30, color: Color(0xFF333333)),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.edit_calendar_rounded,
                            color: Colors.grey, size: 26),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 12),

              // Save Button (Large 54dp min height, High Contrast)
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006699),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  onPressed: _isSaving ? null : _saveReminder,
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          isEditing ? 'Save Changes' : 'Create Reminder',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel Button
              SizedBox(
                height: 50,
                child: TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
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
