// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dart_terminal/core.dart';
import 'package:dart_terminal/src/platform/flutter/flutter_terminal_viewport.dart';
import 'terminal_view.dart';

void main() async {
  final viewport = FlutterTerminalViewport();
  final lambda = TerminalListener(onInput: (a) => print(a));
  runApp(
    MaterialApp(
      home: SizedBox.expand(
        child: TerminalView(
          terminalViewport: viewport,
          terminalListener: lambda,
          autofocus: true,
        ),
      ),
    ),
  );
  await Future.delayed(Duration(milliseconds: 500));
  int plus = 0;

  while (true) {
    await Future.delayed(Duration(milliseconds: 1000 ~/ 60));
    for (int j = 0; j < viewport.size.height; j++) {
      for (int i = 0; i < viewport.size.width; i++) {
        final color = Color.optimizedExtended((plus + i + j) % 256);
        viewport.drawPoint(position: Position(i, j), background: color);
      }
    }
    viewport.updateScreen();
    plus++;
  }
  // for (int i = 0; i < 1000000; i++) {
  //   await Future.delayed(Duration(seconds: 1));
  //   viewport.drawingBuffer[5].setCodePoint(i, "a".codeUnitAt(0));
  //   viewport.updateScreen();
  // }
}
