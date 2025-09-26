import 'dart:io';

import 'package:dart_terminal/ansi.dart';

class ControlTerminalInputListener extends DefaultTerminalListener {
  @override
  void controlCharacter(ControlCharacter controlCharacter) async {
    if (controlCharacter == ControlCharacter.ctrlZ) {
      await service.detach();
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
            viewport.drawPoint(
              position: Position(pos.x + i, pos.y + j),
              foreground: Foreground(
                style: ForegroundStyle(
                  effects: TextEffects.underline,
                  color: i != 0 || j != 0 ? Colors.green : Colors.yellow,
                ),
                codePoint: (codePoint % 26) + 65,
              ),
            );
          }
        }
      case MousePressEvent(buttonState: var t, position: var pos):
        motionPos = pos;
        if (t == MouseButtonState.up) {
          isPressed = false;
        } else {
          isPressed = true;
        }
      case MouseHoverEvent(position: var pos):
        motionPos = pos;
    }
    if (motionPos != null) {
      viewport.drawPoint(
        position: motionPos,
        background: isPressed ? Colors.red : Colors.brightRed,
      );
    }
    viewport.updateScreen();
  }
}

final service = AnsiTerminalService.agnostic()
  ..listener = ControlTerminalInputListener();
final viewport = service.viewport;

void main() async {
  await service.attach();
  service.viewPortMode();
}
