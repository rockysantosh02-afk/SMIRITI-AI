import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/repositories/reminder_repository.dart';

/// Elderly-friendly card widget representing a single reminder with high-contrast
/// typography, clear visual status chips, and accessible, large touch-target buttons.
class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = ReminderRepository.isCompleted(reminder);
    final isDaily = ReminderRepository.isDaily(reminder);
    final scheduledDate = ReminderRepository.parseScheduledDateTime(reminder);

    // Format time for display (e.g., 8:30 AM)
    String timeDisplay = reminder.timeOfDay;
    if (scheduledDate != null) {
      timeDisplay = DateFormat('h:mm a').format(scheduledDate);
    }

    // Format date for display
    String dateDisplay = 'Every day';
    if (!isDaily && scheduledDate != null) {
      final now = DateTime.now();
      if (scheduledDate.year == now.year &&
          scheduledDate.month == now.month &&
          scheduledDate.day == now.day) {
        dateDisplay = 'Today';
      } else if (scheduledDate.year == now.year &&
          scheduledDate.month == now.month &&
          scheduledDate.day == now.day + 1) {
        dateDisplay = 'Tomorrow';
      } else {
        dateDisplay = DateFormat('EEE, MMM d, y').format(scheduledDate);
      }
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDone
              ? Colors.grey.shade400
              : theme.colorScheme.primary.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      color: isDone ? const Color(0xFFF5F5F5) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Type Chips Row
            Row(
              children: [
                _buildStatusChip(isDone, isDaily, dateDisplay),
                const Spacer(),
                if (isDaily)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE7F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.repeat_rounded,
                            size: 16, color: Color(0xFF5E35B1)),
                        SizedBox(width: 4),
                        Text(
                          'Daily',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5E35B1),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Reminder Title (Large 20sp, High Contrast)
            Text(
              reminder.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDone ? Colors.grey.shade700 : const Color(0xFF1A1A1A),
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 8),

            // Date & Time Row
            Row(
              children: [
                Icon(
                  Icons.access_time_filled_rounded,
                  size: 22,
                  color: isDone
                      ? Colors.grey.shade600
                      : const Color(0xFF006699),
                ),
                const SizedBox(width: 8),
                Text(
                  timeDisplay,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDone
                        ? Colors.grey.shade700
                        : const Color(0xFF006699),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  dateDisplay,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Visible Action Buttons Row (large touch targets >= 48dp)
            Row(
              children: [
                // Complete Button (only if not completed)
                if (!isDone) ...[
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 22),
                        label: const Text(
                          'Complete',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: onComplete,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Edit Button
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF006699),
                        side: const BorderSide(
                            color: Color(0xFF006699), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      label: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: onEdit,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Delete Button
                SizedBox(
                  height: 48,
                  width: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC62828),
                      side: const BorderSide(
                          color: Color(0xFFC62828), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => _confirmDelete(context),
                    child: const Icon(Icons.delete_forever_rounded, size: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isDone, bool isDaily, String dateDisplay) {
    if (isDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF2E7D32)),
            SizedBox(width: 4),
            Text(
              'Completed',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      );
    }

    final isToday = dateDisplay == 'Today' || isDaily;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFFFFF3E0) : const Color(0xFFE1F5FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isToday ? Icons.notifications_active_rounded : Icons.event_rounded,
            size: 16,
            color: isToday ? const Color(0xFFE65100) : const Color(0xFF0277BD),
          ),
          const SizedBox(width: 4),
          Text(
            isToday ? 'Today' : 'Upcoming',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isToday ? const Color(0xFFE65100) : const Color(0xFF0277BD),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFC62828), size: 28),
            SizedBox(width: 8),
            Text(
              'Delete Reminder?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${reminder.title}"?',
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              onDelete();
            },
            child: const Text(
              'Delete',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
