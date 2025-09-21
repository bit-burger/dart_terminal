import 'dart:io' as io;

import 'package:dart_tui/core.dart';

extension AllowedSignalsToProcessSignals on AllowedSignal {
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
