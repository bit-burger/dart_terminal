import 'dart:io';
import 'dart:math';

import 'package:advanced_terminal/src/canvas/canvas.dart';
import 'package:advanced_terminal/src/canvas/canvas_drawer.dart';
import 'package:advanced_terminal/src/performance_terst.dart';
import 'package:advanced_terminal/src/style/style.dart';

import 'canvas/picture.dart';
import 'terminal_writer/terminal_escape_code_writer.dart';

const s = TerminalStyle(backgroundColor: XTermTerminalColor(color: 50));

const s2 = TerminalStyle(backgroundColor: XTermTerminalColor(color: 60));

void main() async {
  final window = TerminalWindow.simple;
  final canvas = ManualRefreshTerminalCanvas(window.columns, window.rows);
  final canvasShapeDrawer = CanvasDrawer(canvas);
  // canvasShapeDrawer.drawRectangle(
  //   Point(10, 10),
  //   Point(31, 20),
  //   32,
  //   TerminalStyle(
  //     backgroundColor: XTermTerminalColor(color: 50),
  //   ),
  // );
  // canvasShapeDrawer.drawCircle(Point(30, 30), 10, 32, s2);
  // canvas.draw(0, 0, 32, s);
  // canvas.draw(0, 1, 32, s);

  final triangle = Triangle(Point(0.5, 0), Point(0, 1), Point(1, 1));
  // final picture = const Stack(
  //   children: [
  //     Padding(
  //       edgeInsets: EdgeInsets.all(0.1),
  //       child: Filled(
  //         style: TerminalStyle(
  //           backgroundColor: XTermTerminalColor(color: 3),
  //         ),
  //       ),
  //     ),
  //     Padding(
  //       edgeInsets: EdgeInsets.only(top: 0.05, left: 0.05),
  //       child: Padding(
  //           edgeInsets: EdgeInsets.all(0.02),
  //           child: Mask(
  //             shape: Circle(),
  //             child: Filled(
  //               style: TerminalStyle(
  //                 backgroundColor: XTermTerminalColor(color: 9),
  //               ),
  //             ),
  //           )),
  //     ),
  //     Padding(
  //       edgeInsets: EdgeInsets.only(bottom: 0.05, right: 0.05),
  //       child: Mask(
  //         shape: Circle(),
  //         child: Filled(
  //           style: TerminalStyle(
  //             backgroundColor: XTermTerminalColor(color: 51),
  //           ),
  //         ),
  //       ),
  //     ),
  //   ],
  // );
  final picture = Clip.reverse(shape: triangle, child: Filled(style: s));
  canvasShapeDrawer.drawPicture(Point(10, 10), Point(90, 50), picture);
  // canvas.writeToTerminal(window);

  stdin.lineMode = false;
  stdin.echoMode = false;
  // stdout.write(ESC + "14t");

  await for (final a in stdin) {
    // print(a);
  }

  await Future.delayed(Duration(milliseconds: 100000000));
}
