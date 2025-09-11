import 'dart:io';

import 'package:dart_console/src/ffi/termlib.dart';
import 'package:dart_tui/ansi/ansi_escape_codes.dart';
import 'package:dart_tui/ansi/ansi_terminal_window.dart';
import 'package:dart_tui/core/style.dart';

import 'ansi/ansi_terminal_controller.dart';
import 'core/terminal.dart';

class ControlTerminalInputListener extends TerminalInputListener {
  @override
  void controlCharacter(ControlCharacter controlCharacter) async {
    stdout.write("$controlCharacter;");
    if (controlCharacter == ControlCharacter.ctrlZ) {
      await window.destroy();
      stdout.write("\u001B[?1003l"); // enable mouse events
      stdout.write("\u001B[?1006l");
      exit(0);
    }
  }

  @override
  void input(String s) {
    stdout.write("input('$s')");
  }

  @override
  void screenResize(Size size) {
    stdout.write("resize(width:${size.width},height:${size.height});");
  }

  @override
  void signal(AllowedSignal signal) {
    stdout.write("signal($signal);");
  }

  @override
  void focusChange(bool isFocused) {
    stdout.write("focuschange($isFocused);");
  }

  @override
  void mouseEvent(MouseEvent event) {
    switch (event) {
      case MouseButtonPressEvent(pressType: var t, button: var b):
        stdout.write("press($t,$b)");
      case MouseScrollEvent(xScroll: var x, yScroll: var y):
        stdout.write("scroll(x:$x,y:$y);");
      case MouseHoverMotionEvent(position: var pos):
        stdout.write("motion(x:${pos.x},y:${pos.y})");
    }
  }
}

final window = AnsiTerminalWindow.agnostic();

void main() async {
  window.addListener(ControlTerminalInputListener());
  await window.attach();
  stdout.write("start;");
  window.screen.optimizeForFullDraw();
  window.drawRect(
    rect: Rect(3, 20, 3, 20),
    background: BrightTerminalColor.red,
  );
  window.writeToScreen();

  // Flush stdout to make sure it appears immediately
  stdout.flush();
  await Future.delayed(Duration(seconds: 3));
}

void amain() async {
  print(Platform.environment["miaowmiaowmiaoasdfasd"]);
  final lib = TermLib();
  stdout.write("as");
  lib.enableRawMode();
  AnsiTerminalController().changeScreenMode(alternateBuffer: true);
  stdout.write(disableLineWrapping);
  stdout.write(cursorTo(1, 50));
  stdout.write("a");

  await Future.delayed(Duration(seconds: 3));

  await Future.delayed(Duration(seconds: 3));
  lib.disableRawMode();
  stdout.write("as");
  AnsiTerminalController().changeScreenMode(alternateBuffer: false);
}
