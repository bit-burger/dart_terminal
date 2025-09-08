import 'dart:io';

import 'package:dart_console/src/ffi/termlib.dart';
import 'package:dart_tui/ansi/ansi_terminal_window.dart';

import 'ansi/ansi_terminal_controller.dart';
import 'core/terminal.dart';


class ControlTerminalInputListener extends TerminalInputListener {
  @override
  void controlCharacter(ControlCharacter controlCharacter) async {
    stdout.write("$controlCharacter;");
    if (controlCharacter == ControlCharacter.ctrlZ) {
      await window.destroy();
      exit(0);
    }
  }

  @override
  void input(String s) {
    stdout.write("input: '$s'");
  }

  @override
  void screenResize(Size size) {
    stdout.write("resize to ${size.width} ${size.height};");
  }

  @override
  void signal(AllowedSignal signal) {
    stdout.write("signal: $signal;");
  }

  @override
  void focusChange(bool isFocused) {
    stdout.write("focuschange: $isFocused;");
  }

  @override
  void mouseEvent(MouseButton button, MouseEventType type, Position position) {
    stdout.write("mouseEvent: $button, $type, $position;");
  }
}

final window = AnsiTerminalWindow(terminalController: AnsiTerminalController(useTermLib: true));

void main() async {
  window..addListener(ControlTerminalInputListener())..attach();
  stdout.write("start;");
  await Future.delayed(Duration(seconds: 3));
}

void amain() async {
  final lib = TermLib();
  stdout.write("as");
  lib.enableRawMode();

  await Future.delayed(Duration(seconds: 3));

  lib.disableRawMode();
  stdout.write("as");

  await Future.delayed(Duration(seconds: 3));
}
