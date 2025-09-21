import 'dart:io' as io;

import 'package:dart_tui/core.dart';

/// Extension to convert [AllowedSignal] to [io.ProcessSignal].
extension AllowedSignalsToProcessSignals on AllowedSignal {
  /// Converts an [AllowedSignal] to its corresponding [io.ProcessSignal].
  io.ProcessSignal processSignal() {
    switch (this) {
      case AllowedSignal.sighup:
        return io.ProcessSignal.sighup;
      case AllowedSignal.sigint:
        return io.ProcessSignal.sigint;
      case AllowedSignal.sigterm:
        return io.ProcessSignal.sigterm;
      case AllowedSignal.sigusr1:
        return io.ProcessSignal.sigusr1;
      case AllowedSignal.sigusr2:
        return io.ProcessSignal.sigusr2;
    }
  }
}
