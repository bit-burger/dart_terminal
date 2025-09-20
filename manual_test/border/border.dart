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
  final id = BorderDrawIdentifier();
  final style = BorderCharSet.rounded();
  window.drawBorderBox(
    rect: Position(5, 5) & Size(10, 10),
    borderStyle: style,
    drawIdentifier: id,
  );
  window.drawBorderBox(
    rect: Position(8, 8) & Size(10, 10),
    borderStyle: style,
    drawIdentifier: id,
  );
  window.drawBorderLine(
    from: Position(8, 10),
    to: Position(17, 10),
    borderStyle: style,
    drawIdentifier: id,
  );
  window.updateScreen();
}
