import 'dart:io';

import 'package:dart_tui/ansi/ansi_terminal_window.dart';
import 'package:dart_tui/core/style.dart';
import 'package:dart_tui/core/terminal.dart';

class ControlTerminalInputListener extends DefaultTerminalListener {
  @override
  void controlCharacter(ControlCharacter controlCharacter) async {
    if (controlCharacter == ControlCharacter.ctrlZ) {
      await window.destroy();
      exit(0);
    }
  }

  static bool isPressed = false;
  static int codePoint = 0;
  @override
  void mouseEvent(MouseEvent event) {
    Position? motionPos;
    switch (event) {
      case MouseScrollEvent(position: var pos, xScroll: var x, yScroll: var y):
        codePoint += x + y;
        for (int i = -10; i <= 10; i++) {
          for (int j = -10; j <= 10; j++) {
            window.drawPoint(
              position: Position(pos.x + i, pos.y + j),
              background: i != 0 || j != 0
                  ? BasicTerminalColor.green
                  : BrightTerminalColor.green,
              foreground: TerminalForeground(
                style: TerminalForegroundStyle(
                  textDecorations: TextDecorationSet.underline,
                  color: BasicTerminalColor.yellow,
                ),
                codePoint: (codePoint % 26) + 65,
              ),
            );
          }
        }
      case MouseButtonPressEvent(pressType: var t, position: var pos):
        motionPos = pos;
        if (t == MouseButtonPressEventType.release) {
          isPressed = false;
        } else {
          isPressed = true;
        }
      case MouseHoverMotionEvent(position: var pos):
        motionPos = pos;
    }
    if (motionPos != null) {
      window.drawPoint(
        position: motionPos,
        background: isPressed
            ? BasicTerminalColor.red
            : BrightTerminalColor.red,
      );
    }
    window.updateScreen();
  }
}

final window = AnsiTerminalWindow.agnostic(
  listener: ControlTerminalInputListener(),
);

void main() async {
  await window.attach();
}
