import 'dart:async';

import 'package:advanced_terminal/src/nterminal/platform.dart';
import 'package:advanced_terminal/src/style/style.dart';
import 'dart:io' as io;
import '../nterminal/codes.dart' as codes;

import '../nterminal/terminal.dart';

class TerminalCapabilityNotSupportedError extends Error {
  final String capability;

  TerminalCapabilityNotSupportedError(this.capability);

  @override
  String toString() {
    return 'Capability "$capability" not supported';
  }
}

abstract class TerminalWindowCapabilities {
  factory TerminalWindowCapabilities.getPlatformCapabilityProvider({
    Duration terminalSizePollRate = const Duration(milliseconds: 500),
    int maxBufferSize = 10000,
  }) {
    return AnsiTerminalWindowCapabilityProvider(
      terminalWriter: LimitedBufferedTerminalWriter(
        maxBufferSize: maxBufferSize,
      ),
      eventsGen: isUnix
          ? getUnixTerminalEventsStream
          : () => getWindowsTerminalEventsStream(
                terminalSizePollRate: terminalSizePollRate,
              ),
    );
  }

  TerminalWindowCapabilities();

  /// mandatory for the capability provider to work correctly
  Future<void> instantiateCapabilities() async {}

  int get rows;
  int get columns;

  Stream<TerminalEvent> get terminalInputEvents;

  /// clears what is currently visible
  void clearScreen() {
    throw TerminalCapabilityNotSupportedError("clear screen");
  }

  /// clears the whole core buffer
  void clearTerminal() {
    throw TerminalCapabilityNotSupportedError("clear core");
  }

  void transitionSGR({
    ForegroundStyle oldForeground = ForegroundStyle.defaultStyle,
    ForegroundStyle newForeground = ForegroundStyle.defaultStyle,
    TerminalColor oldBackground = const DefaultTerminalColor(),
    TerminalColor newBackground = const DefaultTerminalColor(),
  }) =>
      setSGR(newForeground: newForeground, newBackground: newBackground);

  void setSGR({
    ForegroundStyle newForeground = ForegroundStyle.defaultStyle,
    TerminalColor newBackground = const DefaultTerminalColor(),
  });

  void moveCursor(int x, [int y]);

  void getCursorPosition() {
    throw TerminalCapabilityNotSupportedError("get cursor position");
  }

  /// If to set the input mode to a manual mode,
  /// where all inputs are given as events in [terminalEvents]
  ///
  /// This also enables all cursor events, if there are any.
  ///
  /// As this plays around with the cursor and echoing,
  /// this should be turned off before the program exit.
  void setInputMode({required bool manual});

  /// writes a string with the last change in
  /// [changeForegroundStyle] and [changeBackgroundColor]
  void write(String s);

  /// same as [write] but with a single char code
  void writeChar(int charCode) {
    write(String.fromCharCode(charCode));
  }

  void bell() {
    throw TerminalCapabilityNotSupportedError("bell");
  }

  void setCursorVisibility({required bool show}) {
    throw TerminalCapabilityNotSupportedError("cursor visibility");
  }

  /// Set the alternate buffer
  void setScreenState({required bool alternative}) {
    throw TerminalCapabilityNotSupportedError("screen state");
  }

  void setWindowTitle({required String title}) {
    throw TerminalCapabilityNotSupportedError("set window title");
  }

  void resetWindowTitle() {
    setWindowTitle(title: "");
  }

  void flush();
}

class AnsiTerminalWindowCapabilityProvider extends TerminalWindowCapabilities {
  final TerminalWriter terminalWriter;
  final Stream<TerminalEvent> Function() eventsGen;
  StreamSubscription<TerminalEvent>? eventsSubscription;

  AnsiTerminalWindowCapabilityProvider({
    required this.terminalWriter,
    required this.eventsGen,
  });

  @override
  int get rows => io.stdout.terminalLines;

  @override
  int get columns {
    try {
      return io.stdout.terminalColumns;
    } catch (_) {
      return 25;
    }
  }

  @override
  Stream<TerminalEvent> get terminalInputEvents => _controller.stream;

  final _controller = StreamController<TerminalEvent>.broadcast();

  @override
  void setInputMode({required bool manual}) {
    io.stdin.echoMode = !manual;
    io.stdin.lineMode = !manual;
    if (manual) {
      io.stdin.echoNewlineMode = false;
      eventsSubscription ??= eventsGen().listen(_controller.add);
    } else {
      eventsSubscription?.cancel();
      eventsSubscription = null;
    }
  }

  @override
  void moveCursor(int x, [int y = -1]) {
    terminalWriter.write("${codes.CSI}$x");
    if (y == -1) {
      terminalWriter.write("G");
    } else {
      terminalWriter.write(";${y}H");
    }
  }

  @override
  void bell() => terminalWriter.write(codes.BEL);

  @override
  void flush() => terminalWriter.flush();

  @override
  void clearScreen() => terminalWriter.write(codes.clearScreen);

  @override
  void clearTerminal() => terminalWriter.write(codes.clearTerminal);

  @override
  void setCursorVisibility({required bool show}) =>
      terminalWriter.write(show ? codes.cursorShow : codes.cursorHide);

  @override
  void write(String s) => terminalWriter.write(s);

  @override
  void writeChar(int charCode) => terminalWriter.writeCharCode(charCode);

  @override
  void setWindowTitle({required String title}) {
    terminalWriter.write("${codes.changeWindowTitleBegin}$title${codes.BEL}");
  }

  @override
  void setScreenState({required bool alternative}) => terminalWriter.write(
      alternative ? codes.alternateBufferShow : codes.alternateBufferHide);

  @override
  void transitionSGR({
    ForegroundStyle oldForeground = ForegroundStyle.defaultStyle,
    ForegroundStyle newForeground = ForegroundStyle.defaultStyle,
    TerminalColor oldBackground = const DefaultTerminalColor(),
    TerminalColor newBackground = const DefaultTerminalColor(),
  }) {
    if (oldForeground.textDecorations != newForeground.textDecorations) {
      return setSGR(
        newForeground: newForeground,
        newBackground: newBackground,
      );
    }
    terminalWriter.write(codes.CSI);
    if (oldBackground != newBackground) {
      terminalWriter.write(newBackground.termRepBackground);
      if (oldForeground.color != newForeground.color) {
        terminalWriter.write(";${newForeground.color.termRepForeground}");
      }
    } else if (oldForeground.color != newForeground.color) {
      terminalWriter.write(newForeground.color.termRepForeground);
    }
    terminalWriter.write("m");
  }

  @override
  void setSGR({
    ForegroundStyle newForeground = ForegroundStyle.defaultStyle,
    TerminalColor newBackground = const DefaultTerminalColor(),
  }) {
    terminalWriter.write(
      "${codes.CSI}"
      "0"
      "${newForeground.color.rgbRep == -1 ? "" : ";${newForeground.color.termRepForeground}"}"
      "${newBackground.rgbRep == -1 ? "" : ";${newBackground.termRepBackground}"}",
    );
    for (final decoration in TextDecoration.values) {
      if (newForeground.textDecorations.contains(decoration)) {
        terminalWriter.write(";${decoration.onCode}");
      }
    }
  }
}
