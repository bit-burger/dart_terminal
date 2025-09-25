// Dart imports:
import 'dart:async';
import 'dart:io';

// Project imports:
import 'package:dart_terminal/core.dart';

// TODO: support intellij console

/// System for tracking and responding to terminal window size changes.
///
/// This module provides platform-specific implementations for monitoring
/// terminal dimensions, enabling responsive UI updates when the terminal
/// is resized.
abstract interface class TerminalSizeTracker {
  /// Current dimensions of the terminal window
  Size get currentSize;

  /// Callback triggered when terminal size changes
  void Function()? listener;

  /// Begins monitoring terminal size changes
  void startTracking();

  /// Stops monitoring terminal size changes
  void stopTracking();

  TerminalSizeTracker();

  /// Creates a platform-appropriate size tracker.
  ///
  /// Returns either a polling-based tracker (Windows) or a signal-based
  /// tracker (POSIX systems) depending on the platform.
  ///
  /// [pollingInterval] specifies how often to check for size changes
  /// on platforms that require polling.
  factory TerminalSizeTracker.agnostic({required Duration pollingInterval}) =>
      Platform.isWindows
      ? PollingTerminalSizeTracker()
      : PosixTerminalSizeTracker();
}

/// POSIX-specific implementation of terminal size tracking.
///
/// Uses the SIGWINCH signal to detect terminal window resizes on
/// Unix-like operating systems (Linux, macOS, etc).
class PosixTerminalSizeTracker extends TerminalSizeTracker {
  /// Cached terminal dimensions
  late Size _currentSize;

  @override
  Size get currentSize => _currentSize;

  /// Subscription to the SIGWINCH signal
  StreamSubscription<dynamic>? _sigwinchSub;

  @override
  void startTracking() {
    // Initialize with current terminal size
    _currentSize = Size(stdout.terminalColumns, stdout.terminalLines);

    // Ensure we're on a supported platform
    if (!Platform.isLinux &&
        !Platform.isMacOS &&
        Platform.operatingSystem.toLowerCase() != 'solaris') {
      throw UnsupportedError('POSIX tracking only supported on Unix-like OS');
    }

    // Set up SIGWINCH handler for terminal resize events
    _sigwinchSub = ProcessSignal.sigwinch.watch().listen((_) {
      _currentSize = Size(stdout.terminalColumns, stdout.terminalLines);
      listener?.call();
    });
  }

  @override
  void stopTracking() {
    _sigwinchSub?.cancel();
  }
}

// ------------------------------
// Polling implementation
// ------------------------------
/// Windows-specific implementation of terminal size tracking.
class PollingTerminalSizeTracker extends TerminalSizeTracker {
  final Duration _interval;
  Timer? _timer;
  late Size _currentSize;

  /// Creates a polling-based terminal size tracker.
  PollingTerminalSizeTracker({
    Duration interval = const Duration(milliseconds: 200),
  }) : _interval = interval;

  @override
  Size get currentSize => _currentSize;

  @override
  void startTracking() {
    _currentSize = Size(stdout.terminalColumns, stdout.terminalLines);
    _timer ??= Timer.periodic(_interval, (_) {
      final newSize = Size(stdout.terminalColumns, stdout.terminalLines);
      if (newSize.width != _currentSize.width ||
          newSize.height != _currentSize.height) {
        _currentSize = newSize;
        listener?.call();
      }
    });
  }

  @override
  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }
}
