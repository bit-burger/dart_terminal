import 'dart:io';

import 'package:dart_tui/ansi/ansi_terminal_window.dart';
import 'package:dart_tui/core/terminal.dart';



class ControlTerminalInputListener implements TerminalListener {
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

final window = AnsiTerminalWindow.agnostic(listener: ControlTerminalInputListener());

void main() async {
  await window.attach();
  stdout.write("start;");
}
