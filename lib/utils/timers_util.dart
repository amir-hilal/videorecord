// lib/utils/timer_utils.dart

import 'dart:async';

class TimerUtils {
  Timer? recordingTimer;
  Timer? storageCheckTimer;

  /// Starts the timers with the specified intervals.
  /// `onRecordingTick` is called every second to update the recording time.
  /// `onStorageCheck` is called every 3 seconds to check storage during recording.
  void startTimers({
    required Function onRecordingTick,
    required Future<void> Function() onStorageCheck,
  }) {
    stopTimers(); // Ensure any existing timers are cancelled before starting new ones

    recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      onRecordingTick();
    });

    storageCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await onStorageCheck();
    });
  }

  /// Stops and disposes of both timers.
  void stopTimers() {
    recordingTimer?.cancel();
    recordingTimer = null;
    storageCheckTimer?.cancel();
    storageCheckTimer = null;
  }
}
