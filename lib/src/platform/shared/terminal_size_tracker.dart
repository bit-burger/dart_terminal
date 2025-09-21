import 'dart:async';
import 'dart:io';

import 'package:dart_tui/core.dart';

abstract interface class TerminalSizeTracker {
  Size get currentSize;

  void Function()? listener;

  void startTracking();
  void stopTracking();

  TerminalSizeTracker();

  factory TerminalSizeTracker.agnostic({required Duration pollingInterval}) =>
      Platform.isWindows
      ? PollingTerminalSizeTracker()
      : PosixTerminalSizeTracker();
}

// ------------------------------
// POSIX implementation
// ------------------------------
class PosixTerminalSizeTracker extends TerminalSizeTracker {
  late Size _currentSize;

  @override
  Size get currentSize => _currentSize;

  StreamSubscription<dynamic>? _sigwinchSub;

  @override
  void startTracking() {
    _currentSize = Size(stdout.terminalColumns, stdout.terminalLines);
    if (!Platform.isLinux &&
        !Platform.isMacOS &&
        Platform.operatingSystem.toLowerCase() != 'solaris') {
      throw UnsupportedError('POSIX tracking only supported on Unix-like OS');
    }

    // Listen for SIGWINCH (terminal resize)
    _sigwinchSub = ProcessSignal.sigwinch.watch().listen((_) {
      _currentSize = Size(stdout.terminalColumns, stdout.terminalLines);
      listener?.call();
    });
  }

  @override
  void stopTracking() {
    _sigwinchSub?.cancel();
    _sigwinchSub = null;
  }
}

// ------------------------------
// Polling implementation
// ------------------------------
class PollingTerminalSizeTracker extends TerminalSizeTracker {
  final Duration interval;
  Timer? _timer;
  late Size _currentSize;

  PollingTerminalSizeTracker({
    this.interval = const Duration(milliseconds: 200),
  });

  @override
  Size get currentSize => _currentSize;

  @override
  void startTracking() {
    _currentSize = Size(stdout.terminalColumns, stdout.terminalLines);
    _timer ??= Timer.periodic(interval, (_) {
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
