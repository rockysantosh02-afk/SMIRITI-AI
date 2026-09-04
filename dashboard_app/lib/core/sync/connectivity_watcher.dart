import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Watches network connectivity and triggers a sync callback
/// when connectivity is restored, debounced by [debounceDuration].
class ConnectivityWatcher {
  final Stream<ConnectivityResult> _connectivity;
  final Future<void> Function() _onSync;

  Timer? _debounceTimer;
  bool _wasOffline = false;
  StreamSubscription<ConnectivityResult>? _subscription;

  /// [onSync] is called when connectivity is restored after being offline.
  /// It is debounced by [debounceDuration] to avoid triggering multiple syncs.
  ConnectivityWatcher({
    Stream<ConnectivityResult>? connectivity,
    required Future<void> Function() onSync,
    this.debounceDuration = const Duration(seconds: 5),
  })  : _connectivity = connectivity ?? Connectivity().onConnectivityChanged,
        _onSync = onSync;

  final Duration debounceDuration;

  /// Starts watching connectivity. Call from initState or at app start.
  void start() {
    _subscription?.cancel();
    _subscription = _connectivity.listen(_handleConnectivityChange);
  }

  /// Stops watching. Call from dispose.
  void stop() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    final isOnline = result != ConnectivityResult.none;

    if (isOnline && _wasOffline) {
      // Connectivity restored after being offline — debounce sync.
      _debounceTimer?.cancel();
      _debounceTimer = Timer(debounceDuration, () {
        _runSync();
      });
    }

    _wasOffline = !isOnline;
  }

  Future<void> _runSync() async {
    try {
      await _onSync();
    } catch (e) {
      debugPrint('[ConnectivityWatcher] sync failed: $e');
    }
  }

  void dispose() {
    stop();
  }
}
