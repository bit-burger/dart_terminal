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
  window.drawBackground(color: BasicTerminalColor.red);
  window.drawText(text: "Resize to wipe everything.", position: Position(10, 10));
  window.updateScreen();
}
