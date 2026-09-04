import 'package:flutter/material.dart';

/// Small dot shown in the top corner of the dashboard.
///
/// Colours:
/// - green: synced (no pending items)
/// - orange: pending items in outbox
/// - gray: offline / never synced
///
/// Tapping opens [SyncDebugScreen].
class SyncDebugIndicator extends StatelessWidget {
  final int pendingCount;
  final bool isOnline;
  final DateTime? lastSyncTime;

  const SyncDebugIndicator({
    super.key,
    required this.pendingCount,
    required this.isOnline,
    this.lastSyncTime,
  });

  Color get _dotColor {
    if (!isOnline) return Colors.grey;
    if (pendingCount > 0) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SyncDebugScreen(
              pendingCount: pendingCount,
              isOnline: isOnline,
              lastSyncTime: lastSyncTime,
            ),
          ),
        );
      },
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: _dotColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38, width: 1),
        ),
      ),
    );
  }
}

/// Debug screen shown when tapping the sync dot.
class SyncDebugScreen extends StatelessWidget {
  final int pendingCount;
  final bool isOnline;
  final DateTime? lastSyncTime;

  const SyncDebugScreen({
    super.key,
    required this.pendingCount,
    required this.isOnline,
    this.lastSyncTime,
  });

  String _formatTime(DateTime? t) {
    if (t == null) return 'Never';
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status'),
        backgroundColor: Colors.grey[900],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row('Status', isOnline ? 'Online' : 'Offline'),
          _row('Last sync', _formatTime(lastSyncTime)),
          _row('Pending items', '$pendingCount'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
