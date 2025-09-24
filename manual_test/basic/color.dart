import 'dart:async';
import 'dart:io';

import 'package:dart_tui/ansi.dart';

void main() async {
  int plus = 0;

  final terminalService = AnsiTerminalService.agnostic();
  void paint() {
    for (int j = 0; j < terminalService.viewport.size.height; j++) {
      for (int i = 0; i < terminalService.viewport.size.width; i++) {
        final color = XTermTerminalColor.raw((plus + i + j) % 256);
        terminalService.viewport.drawPoint(
          position: Position(i, j),
          background: color,
        );
      }
    }
    terminalService.viewport.updateScreen();
  }

  terminalService.listener = TerminalListener(
    onControlCharacter: (c) async {
      if ([ControlCharacter.ctrlC, ControlCharacter.ctrlZ].contains(c)) {
        await terminalService.detach();
        exit(0);
      }
    },
    onScreenResize: (_) {
      paint();
    },
  );
  await terminalService.attach();
  terminalService.viewPortMode();

  paint();
  Timer.periodic(Duration(milliseconds: 1000 ~/ 60), (_) {
    plus += 2;
    paint();
  });
}
