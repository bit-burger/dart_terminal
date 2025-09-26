// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dart_terminal/core.dart';
import 'package:dart_terminal/src/platform/flutter/flutter_terminal_viewport.dart';
import 'flutter_terminal_service.dart';

void main() async {
  final viewport = FlutterTerminalViewport();
  final lambda = TerminalListener(onInput: (a) => print(a));
  runApp(
    MaterialApp(
      home: TerminalView(
        terminalViewport: viewport,
        terminalListener: lambda,
        autofocus: true,
      ),
    ),
  );
  await Future.delayed(Duration(seconds: 3));
  print("miaow");
  viewport.drawingBuffer[5].setCodePoint(5, "a".codeUnitAt(0));
  viewport.drawingBuffer[5].setCodePoint(2, "c".codeUnitAt(0));
  viewport.updateScreen();
  for (int i = 0; i < 1000000; i++) {
    await Future.delayed(Duration(seconds: 1));
    viewport.drawingBuffer[5].setCodePoint(i, "a".codeUnitAt(0));
    viewport.updateScreen();
  }
}
