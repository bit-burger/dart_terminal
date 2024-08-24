import 'dart:async';
import 'dart:io' as io;

import 'package:meta/meta.dart';

import '../terminal_input.dart';
import 'ansi_escape_codes.dart' as ansiCodes;

class ANSITerminalInput extends TerminalInput {
  final List<StreamSubscription> _subscriptions = [];
  Completer<(int, int)>? _cursorPositionCompleter;

  @override
  int get height => io.stdout.terminalLines;
  @override
  int get width => io.stdout.terminalColumns;

  @override
  Future<(int, int)> getCursorPosition() {
    io.stdout.write(ansiCodes.cursorPositionQuery);
    _cursorPositionCompleter = Completer<(int, int)>();
    return _cursorPositionCompleter!.future;
  }

  @override
  void startDirectListening() {
    _subscriptions.add(io.stdin.listen(stdinEvent));
    for (final signal in AllowedSignal.values) {
      _subscriptions.add(signal.processSignal().watch().listen((_) {
        for (final listener in listeners) {
          listener.signal(signal);
        }
      }));
    }
    _subscriptions.add(io.ProcessSignal.sigwinch.watch().listen((event) {
      for (final listener in listeners) {
        listener.screenResize(
            io.stdout.terminalLines, io.stdout.terminalColumns);
      }
    }));
    io.stdin.echoMode = false;
    io.stdin.lineMode = false;
  }

  @override
  void stopDirectListening() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    io.stdin.echoMode = true;
    io.stdin.lineMode = true;
    _cursorPositionCompleter?.complete((0, 0));
    _cursorPositionCompleter = null;
  }

  @protected
  void controlCharacter(ControlCharacter controlCharacter) {
    for (final listener in listeners) {
      listener.controlCharacter(controlCharacter);
    }
  }

  @protected
  bool tryToInterpretControlCharacter(List<int> input) {
    if (input[0] >= 0x01 && input[0] <= 0x1a) {
      // Ctrl+A thru Ctrl+Z are mapped to the 1st-26th entries in the
      // enum, so it's easy to convert them across
      controlCharacter(ControlCharacter.values[input[0] - 1]);
      return true;
    }
    if (input[0] == 127) {
      controlCharacter(ControlCharacter.wordBackspace);
      return true;
    }
    if (input[0] == 27 && input.length == 1) {
      controlCharacter(ControlCharacter.escape);
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
      if(semicolonIndex == -1) return false;
      final x =
          int.tryParse(String.fromCharCodes(input.sublist(0, semicolonIndex)));
      final y =
          int.tryParse(String.fromCharCodes(input.sublist(semicolonIndex + 1)));
      if(x == null || y == null) return false;
      _cursorPositionCompleter?.complete((x, y));
      return true;
    }
    switch (input[0]) {
      case 65:
        controlCharacter(ControlCharacter.arrowUp);
        break;
      case 66:
        controlCharacter(ControlCharacter.arrowDown);
        break;
      case 67:
        controlCharacter(ControlCharacter.arrowRight);
        break;
      case 68:
        controlCharacter(ControlCharacter.arrowLeft);
        break;
      case 72:
        controlCharacter(ControlCharacter.home);
        break;
      case 70:
        controlCharacter(ControlCharacter.end);
        break;
    }
    return false;
  }

  @protected
  void stdinEvent(List<int> input) {
    if (!tryToInterpretControlCharacter(input)) {
      for (final listener in listeners) {
        listener.input(String.fromCharCodes(input));
      }
    }
  }
}
