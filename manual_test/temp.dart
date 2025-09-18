import 'dart:io';

import 'package:dart_tui/ansi/ansi_terminal_window.dart';
import 'package:dart_tui/core/style.dart';
import 'package:dart_tui/core/terminal.dart';

class ExitListener extends DefaultTerminalListener {
  @override
  void controlCharacter(ControlCharacter controlCharacter) async {
    if (controlCharacter == ControlCharacter.ctrlZ) {
      await window.destroy();
      exit(0);
    }
  }
}

final window = AnsiTerminalWindow.agnostic(listener: ExitListener());

void main() async {
  await window.attach();
  final pos = Position(10, 10);

  if (true) {
    window.drawPoint(
      position: Position(20, 20),
      background: BasicTerminalColor.green,
      foreground: TerminalForeground(
        style: TerminalForegroundStyle(
          textDecorations: TextDecorationSet.underline,
          color: BasicTerminalColor.yellow,
        ),
        codePoint: 65,
      ),
    );
  } else {
    for (int i = -2; i <= 2; i++) {
      for (int j = -2; j <= 2; j++) {
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
            codePoint: 65,
          ),
        );
      }
    }
  }
  window.updateScreen();
}
