import 'dart:async';
import 'dart:io' as io;

import '../core/style.dart';
import '../core/terminal.dart';
import 'ansi_escape_codes.dart' as ansi_codes;
import 'ansi_terminal_controller.dart';

class AnsiTerminalWindowFactory extends TerminalWindowFactory {
  final TerminalController terminalWriter;

  AnsiTerminalWindowFactory({this.terminalWriter = const AnsiTerminalController()});

  @override
  TerminalWindow createWindow() => AnsiTerminalWindow();
}

extension on AllowedSignal {
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

class AnsiTerminalWindow extends TerminalWindow {
  final TerminalController terminalController;
  final List<StreamSubscription> _subscriptions = [];
  Completer<Position>? _cursorPositionCompleter;

  @override
  Position get cursorPosition => _cursorPosition;
  late Position _cursorPosition;

  @override
  Size get size =>
      (width: io.stdout.terminalColumns, height: io.stdout.terminalLines);

  AnsiTerminalWindow({this.terminalController = const AnsiTerminalController()});

  Future<Position> _getCursorPosition() {
    io.stdout.write(ansi_codes.cursorPositionQuery);
    _cursorPositionCompleter = Completer<Position>();
    return _cursorPositionCompleter!.future;
  }

  @override
  Future<void> attach() async {
    terminalController.saveCursorPosition();
    terminalController.changeScreenMode(alternateBuffer: true);
    _subscriptions.add(io.stdin.listen(_stdinEvent));
    for (final signal in AllowedSignal.values) {
      _subscriptions.add(signal.processSignal().watch().listen((_) {
        for (final listener in listeners) {
          listener.signal(signal);
        }
      }));
    }
    _subscriptions.add(io.ProcessSignal.sigwinch.watch().listen((event) {
      for (final listener in listeners) {
        listener.screenResize(size);
      }
    }));
    terminalController.setInputMode(true);
    _cursorPosition = await _getCursorPosition();
  }

  @override
  Future<void> destroy() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    terminalController.setInputMode(false);
    terminalController.changeScreenMode(alternateBuffer: false);
    terminalController.restoreCursorPosition();
    _cursorPositionCompleter?.complete((x: 0, y: 0));
    _cursorPositionCompleter = null;
  }

  void _controlCharacter(ControlCharacter controlCharacter) {
    for (final listener in listeners) {
      listener.controlCharacter(controlCharacter);
    }
  }

  // TODO: mouse events
  bool _tryToInterpretControlCharacter(List<int> input) {
    if (input[0] >= 0x01 && input[0] <= 0x1a) {
      // Ctrl+A thru Ctrl+Z are mapped to the 1st-26th entries in the
      // enum, so it's easy to convert them across
      _controlCharacter(ControlCharacter.values[input[0] - 1]);
      return true;
    }
    if (input[0] == 127) {
      _controlCharacter(ControlCharacter.wordBackspace);
      return true;
    }
    if (input[0] == 27 && input.length == 1) {
      _controlCharacter(ControlCharacter.escape);
      return true;
    }
    if (input[0] == 27 && input[1] == 91) {
      input = input.sublist(2);
    } else if (input[0] == 0x9b) {
      input = input.sublist(1);
    } else {
      return false;
    }
    if (input.last == 82) {
      int semicolonIndex = input.indexOf(59);
      if (semicolonIndex == -1) return false;
      final x =
          int.tryParse(String.fromCharCodes(input.sublist(0, semicolonIndex)));
      final y =
          int.tryParse(String.fromCharCodes(input.sublist(semicolonIndex + 1, input.length - 1)));
      if (x == null || y == null) return false;
      _cursorPositionCompleter?.complete((x: x - 1, y: y - 1));
      return true;
    }
    switch (input[0]) {
      case 65:
        _controlCharacter(ControlCharacter.arrowUp);
        break;
      case 66:
        _controlCharacter(ControlCharacter.arrowDown);
        break;
      case 67:
        _controlCharacter(ControlCharacter.arrowRight);
        break;
      case 68:
        _controlCharacter(ControlCharacter.arrowLeft);
        break;
      case 72:
        _controlCharacter(ControlCharacter.home);
        break;
      case 70:
        _controlCharacter(ControlCharacter.end);
        break;
    }
    return false;
  }

  void _stdinEvent(List<int> input) {
    if (!_tryToInterpretControlCharacter(input)) {
      for (final listener in listeners) {
        listener.input(String.fromCharCodes(input));
      }
    }
  }

  @override
  void bell() => terminalController.bell();

  @override
  void changeCursorVisibility({required bool hiding}) =>
      terminalController.changeCursorVisibility(hiding: hiding);

  @override
  void changeTerminalSize(Size size) =>
      terminalController.changeSize(size.width, size.height);

  @override
  void changeTerminalTitle(String title) =>
      terminalController.changeTerminalTitle(title);

  @override
  void drawPoint(
      {required Position position,
      TerminalColor? background,
      TerminalForeground? foreground}) {}

  @override
  void drawRect(
      {required Rect rect,
      TerminalColor? background,
      TerminalForegroundStyle? foreground}) {}

  @override
  void drawString({required String text, required Position position}) {}

  @override
  void changeCursorPosition(Position position) {
    _cursorPosition = position;
    terminalController.setCursorPosition(position.x, position.y);
  }

  @override
  void writeToScreen() {}
}
