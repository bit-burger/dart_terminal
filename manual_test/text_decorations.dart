import 'dart:io';

import 'package:dart_tui/ansi/ansi_terminal_window.dart';
import 'package:dart_tui/core/style.dart';
import 'package:dart_tui/core/terminal.dart';

class TextDecorationsListener extends DefaultTerminalListener {
  @override
  void controlCharacter(ControlCharacter c) async {
    if (c == ControlCharacter.ctrlZ) {
      await window.destroy();
      exit(0);
    }
    if (c == ControlCharacter.ctrlA) {
      style += 1;
      paint();
    }
    if (c == ControlCharacter.ctrlB) {
      style += 32;
      paint();
    }
    if (c == ControlCharacter.ctrlS) {
      style -= 1;
      paint();
    }
  }

  @override
  void screenResize(Size size) {
    paint();
  }
}

final window = AnsiTerminalWindow.agnostic(listener: TextDecorationsListener());
int style = 0;
TextDecorationSet s(int style) => TextDecorationSet(
  intense: style & 1 != 0,
  faint: style & 2 != 0,
  italic: style & 4 != 0,
  crossedOut: style & 8 != 0,
  doubleUnderline: style & 16 != 0,
  fastBlink: style & 32 != 0,
  slowBlink: style & 64 != 0,
  underline: style & 128 != 0,
);

void paint() {
  window.drawText(
    text: "Press ctrl-A",
    style: TerminalForegroundStyle(
      textDecorations: s(style),
      color: BasicTerminalColor.red,
    ),
    position: Position(0, 0),
  );
  window.drawText(
    text: " or ctrl-S",
    style: TerminalForegroundStyle(
      textDecorations: s(~style),
      color: BasicTerminalColor.red,
    ),
    position: Position(12, 0),
  );
  window.updateScreen();
}

void main() async {
  await window.attach();
  paint();
}
