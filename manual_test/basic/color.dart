import 'dart:async';
import 'dart:io';

import 'package:dart_tui/ansi/ansi_terminal_window.dart';
import 'package:dart_tui/core/style.dart';
import 'package:dart_tui/core/terminal.dart';

class ColorListener extends DefaultTerminalListener {
  @override
  void controlCharacter(ControlCharacter c) async {
    if (c == ControlCharacter.ctrlZ) {
      await window.destroy();
      exit(0);
    }
  }

  @override
  void screenResize(Size size) {
    paint();
  }
}

final window = AnsiTerminalWindow.agnostic(listener: ColorListener());
int plus = 0;

void paint() {
  for (int j = 0; j < window.size.height; j++) {
    for (int i = 0; i < window.size.width; i++) {
      final color = XTermTerminalColor.raw((plus + i + j) % 256);
      window.drawPoint(position: Position(i, j), background: color);
    }
  }
  window.updateScreen();
}

void main() async {
  await window.attach();
  window.cursor = null;
  paint();
  Timer.periodic(Duration(milliseconds: 1000 ~/ 60), (_) {
    plus += 2;
    paint();
  });
}
