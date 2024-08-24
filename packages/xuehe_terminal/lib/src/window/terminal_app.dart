import 'dart:async';

import 'package:advanced_terminal/src/window/window_capabilites.dart';

bool _isRunningApp = false;

Future<void> runApp(
  TerminalApp app, {
  TerminalWindowCapabilities? capabilities,
}) async {
  if (_isRunningApp) {
    throw StateError("Only one app can run at the time");
  }
  _isRunningApp = true;
  capabilities ??= TerminalWindowCapabilities.getPlatformCapabilityProvider();
  await capabilities.instantiateCapabilities();
  await app.run(capabilities);
  _isRunningApp = false;
}

void runAppSync(
  TerminalApp app,
  TerminalWindowCapabilities capabilities,
) {
  if (_isRunningApp) {
    throw StateError("Only one app can run at the time");
  }
  final result = app.run(capabilities);
  if(result.runtimeType == Future) {
    throw ArgumentError.value(app, "app", "app is not sync");
  }
}

abstract class TerminalApp {
  FutureOr<void> run(TerminalWindowCapabilities capabilities);
}
