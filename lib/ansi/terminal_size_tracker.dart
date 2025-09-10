import 'dart:async';
import 'dart:io';

import 'package:dart_tui/core/terminal.dart';

abstract interface class TerminalSizeTracker {
  Size get terminalSize;
  void addListener(TerminalSizeListener listener);
  void removeListener(TerminalSizeListener listener);
  void startTracking();
  void stopTracking();

  TerminalSizeTracker();

  factory TerminalSizeTracker.agnostic({required Duration pollingInterval}) =>
      Platform.isWindows
      ? PollingTerminalSizeTracker()
      : PosixTerminalSizeTracker();
}

abstract class TerminalSizeListener {
  void resizeEvent();
}

// ------------------------------
// POSIX implementation
// ------------------------------
class PosixTerminalSizeTracker extends TerminalSizeTracker {
  final List<TerminalSizeListener> _listeners = [];
  late Size _currentSize;

  @override
  Size get terminalSize => _currentSize;

  @override
  void addListener(TerminalSizeListener listener) => _listeners.add(listener);

  @override
  void removeListener(TerminalSizeListener listener) =>
      _listeners.remove(listener);

  StreamSubscription? _sigwinchSub;

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
      for (final l in _listeners) {
        l.resizeEvent();
      }
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
  final List<TerminalSizeListener> _listeners = [];
  final Duration interval;
  Timer? _timer;
  late Size _currentSize;

  PollingTerminalSizeTracker({
    this.interval = const Duration(milliseconds: 200),
  });

  @override
  Size get terminalSize => _currentSize;

  @override
  void addListener(TerminalSizeListener listener) => _listeners.add(listener);

  @override
  void removeListener(TerminalSizeListener listener) =>
      _listeners.remove(listener);

  @override
  void startTracking() {
    _currentSize = Size(stdout.terminalColumns, stdout.terminalLines);
    _timer ??= Timer.periodic(interval, (_) {
      final newSize = Size(stdout.terminalColumns, stdout.terminalLines);
      if (newSize.width != _currentSize.width ||
          newSize.height != _currentSize.height) {
        _currentSize = newSize;
        for (final l in _listeners) {
          l.resizeEvent();
        }
      }
    });
  }

  @override
  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }
}
