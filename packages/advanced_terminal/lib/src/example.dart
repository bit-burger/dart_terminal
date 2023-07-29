import 'dart:math';

import 'package:advanced_terminal/src/canvas/canvas_drawer.dart';
import 'package:advanced_terminal/src/style/style.dart';
import 'package:advanced_terminal/src/terminal/codes.dart';

import 'terminal/terminal.dart';
import 'canvas/canvas.dart';

void main() async {
  final window = TerminalWindow();
  final canvas = ManualRefreshTerminalCanvas(window.columns, window.rows);
  final drawer = CanvasDrawer(canvas);
  drawer.drawBackground(
    32,
    TerminalStyle(
      backgroundColor: XTermTerminalColor(color: 52),
    ),
  );
  drawer.drawRectangle(Point(1, 0), Point(10, 10), 32, TerminalStyle(backgroundColor: XTermTerminalColor(color: 32)));
  canvas.writeToTerminal(window);
  await Future.delayed(Duration(milliseconds: 1000));
  window.directEscapeCodeWriter.moveCursor(1, 1);
  window.directTerminalWriter.write(CSI + "0" + "m");
  window.directTerminalWriter.write("sasdfasdfasdfasdfasdf");
  for(var i = 0; i < 100000000000000000; i++) {

  }
}
