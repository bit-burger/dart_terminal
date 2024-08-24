import 'dart:math';

import 'package:advanced_terminal/src/canvas/picture.dart';

import '../style/style.dart';
import 'canvas.dart';

class CanvasDrawer {
  final TerminalCanvas canvas;

  CanvasDrawer(this.canvas);

  void drawPicture(Point<int> a, Point<int> b, Graphic picture) {
    final maxX = max(a.x, b.x);
    final minX = min(a.x, b.x);
    final charWidth = 1 / (maxX - minX + 1);

    final maxY = max(a.y, b.y);
    final minY = min(a.y, b.y);
    final charHeight = 1 / (maxY - minY + 1);

    for (int x = minX; x <= maxX; x++) {
      double relativeX = (x - minX + 0.5) * charWidth;
      for (int y = minY; y <= maxY; y++) {
        double relativeY = (y - minY + 0.5) * charHeight;
        final style = picture.drawStyle(relativeX, relativeY);
        if (style != null) {
          canvas.draw(x, y, 32, style);
        }
      }
    }
  }

  void drawRectangle(
      Point<int> a, Point<int> b, int char, TerminalStyle style) {
    final maxX = max(a.x, b.x);
    final minX = min(a.x, b.x);
    final maxY = max(a.y, b.y);
    final minY = min(a.y, b.y);
    for (var x = minX; x <= maxX; x++) {
      for (var y = minY; y <= maxY; y++) {
        canvas.draw(x, y, char, style);
      }
    }
  }

  void drawCircle(
      Point<int> center, int radius, int char, TerminalStyle style) {
    for (var x = center.x - radius; x <= center.x + radius; x++) {
      for (var y = center.y - radius; y <= center.y + radius; y++) {
        final distance = sqrt(pow(center.x - x, 2) + pow(center.y - y, 2));
        if (distance + 0.1 <= radius) {
          canvas.draw(x, y, char, style);
        }
      }
    }
  }

  void drawBackground(int char, TerminalStyle style) {
    for (var x = 0; x < canvas.columns; x++) {
      for (var y = 0; y < canvas.rows; y++) {
        canvas.draw(x, y, char, style);
      }
    }
  }
}
