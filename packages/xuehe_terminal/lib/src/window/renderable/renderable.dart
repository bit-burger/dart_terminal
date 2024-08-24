import 'package:advanced_terminal/src/style/style.dart';
import 'package:advanced_terminal/src/window/window_capabilites.dart';

import '../terminal_app.dart';

class RenderApp extends TerminalApp {
  final int height;
  final Graphics graphics;
  final bool newLineBeforeCanvas;
  final bool newLineAfterCanvas;

  RenderApp({
    required this.height,
    required this.graphics,
    this.newLineBeforeCanvas = true,
    this.newLineAfterCanvas = true,
  });

  @override
  Future<void> run(TerminalWindowCapabilities capabilities) async {
    if (newLineBeforeCanvas) {
      capabilities.write("\n");
    }
    final width = capabilities.columns;
    var lastPixel = (
      const DefaultTerminalColor(),
      (0, ForegroundStyle.defaultStyle),
    );
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final newPixel = Graphics.fillNulls(
          graphics.getPixel(x, y, width, height),
        );
        final (oldBackground, (_, oldForeground)) = lastPixel;
        final (newBackground, (char, newForeground)) = newPixel;
        capabilities.transitionSGR(
          oldBackground: oldBackground,
          oldForeground: oldForeground,
          newForeground: newForeground,
          newBackground: newBackground,
        );
        capabilities.writeChar(char);
      }
    }
    capabilities.setSGR();
    if (newLineAfterCanvas) {
      capabilities.write("\n");
    }
    capabilities.flush();
  }
}

abstract class Graphics {
  const Graphics();

  (TerminalColor?, (int, ForegroundStyle)?) getPixel(
    int x,
    int y,
    int width,
    int height,
  );

  static (TerminalColor, (int, ForegroundStyle)) fillNulls(
    (
      TerminalColor?,
      (int, ForegroundStyle)?,
    ) pixel,
  ) {
    var (background, foreground) = pixel;
    foreground ??= (32, ForegroundStyle.defaultStyle);
    background ??= const DefaultTerminalColor();
    return (background, foreground);
  }

  static bool noNulls(
      (
        TerminalColor?,
        (int, ForegroundStyle)?,
      ) pixel) {
    return pixel.$1 != null && pixel.$2 != null;
  }

  static (
    TerminalColor?,
    (int, ForegroundStyle)?,
  ) imposeOn(
      (
        TerminalColor?,
        (int, ForegroundStyle)?,
      ) lowerPixel,
      (
        TerminalColor?,
        (int, ForegroundStyle)?,
      ) upperPixel) {
    return (upperPixel.$1 ?? lowerPixel.$1, upperPixel.$2 ?? lowerPixel.$2);
  }
}

class EdgeInsets {
  final int left, top, right, bottom;

  const EdgeInsets.only({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });

  const EdgeInsets.fromLTRB(this.left, this.top, this.right, this.bottom);

  const EdgeInsets.symmetrical({int horizontal = 0, int vertical = 0})
      : this.fromLTRB(
          horizontal,
          vertical,
          horizontal,
          vertical,
        );

  const EdgeInsets.all(int inset) : this.fromLTRB(inset, inset, inset, inset);
}

class Padding extends Graphics {
  final EdgeInsets padding;
  final Graphics child;

  const Padding({
    required this.child,
    required this.padding,
  });

  @override
  (TerminalColor?, (int, ForegroundStyle)?) getPixel(
    int x,
    int y,
    int width,
    int height,
  ) {
    width -= padding.left + padding.right;
    height -= padding.top + padding.bottom;
    x -= padding.left;
    y -= padding.top;
    if (width - x <= 0 || x < 0 || height - y <= 0 || y < 0) return (null, null);
    return child.getPixel(x, y, width, height);
  }
}

class FractionalEdgeInsets {
  final double left, top, right, bottom;

  const FractionalEdgeInsets.only({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  })  : assert(left + right <= 1),
        assert(top + bottom <= 1);
}

class FractionalPadding extends Graphics {
  final FractionalEdgeInsets padding;
  final Graphics child;

  const FractionalPadding({
    required this.child,
    required this.padding,
  });

  @override
  (TerminalColor?, (int, ForegroundStyle)?) getPixel(
    int x,
    int y,
    int width,
    int height,
  ) {
    final left = (width * padding.left).round();
    final right = (width * padding.right).round();
    final top = (width * padding.top).round();
    final bottom = (width * padding.bottom).round();

    width -= left - right;
    height -= top - bottom;
    if (width - x <= 0 || height - y <= 0) return (null, null);
    x += left;
    y += top;
    return child.getPixel(x, y, width, height);
  }
}

class Stack extends Graphics {
  final List<Graphics> children;

  Stack({required this.children}) : assert(children.isNotEmpty);

  @override
  (TerminalColor?, (int, ForegroundStyle)?) getPixel(
    int x,
    int y,
    int width,
    int height,
  ) {
    var pixel = children.last.getPixel(x, y, width, height);
    for (int i = children.length - 2; i >= 0; i++) {
      pixel = Graphics.imposeOn(
        children[i].getPixel(x, y, width, height),
        pixel,
      );
      if (Graphics.noNulls(pixel)) {
        return pixel;
      }
    }
    return pixel;
  }
}

class ColoredBox extends Graphics {
  final TerminalColor backgroundColor;
  final Graphics? child;

  const ColoredBox({this.child, required this.backgroundColor});

  @override
  (TerminalColor?, (int, ForegroundStyle)?) getPixel(
    int x,
    int y,
    int width,
    int height,
  ) {
    final childPixel = child?.getPixel(x, y, width, height);
    return (childPixel?.$1 ?? backgroundColor, childPixel?.$2);
  }
}

enum Alignment {
  topLeft(-1, -1),
  topCenter(0, -1),
  topRight(1, -1),
  left(-1, 0),
  center(0, 0),
  right(1, 0),
  bottomLeft(-1, 1),
  bottomCenter(0, 1),
  bottomRight(1, 1);

  final int dx, dy;
  const Alignment(this.dx, this.dy);
}

class Text extends Graphics {
  final List<String> lines;
  final ForegroundStyle style;
  final Alignment alignment;

  Text(
    String text, {
    this.style = ForegroundStyle.defaultStyle,
    this.alignment = Alignment.center,
  }) : lines = text.split("\n");

  @override
  (TerminalColor?, (int, ForegroundStyle)?) getPixel(
    int x,
    int y,
    int width,
    int height,
  ) {
    int lineIndex;
    if (alignment.dy == -1 || lines.length >= height) {
      lineIndex = y;
    } else if (alignment.dy == 1) {
      lineIndex = y - (height - lines.length);
    } else {
      final restLines = height - lines.length;
      lineIndex = y - restLines ~/ 2;
    }
    if (lineIndex < 0 || lineIndex >= lines.length) {
      return (null, null);
    }
    String line = lines[lineIndex];
    int charIndex;
    if (alignment.dx == -1 || line.length >= width) {
      charIndex = x;
    } else if (alignment.dx == 1) {
      charIndex = x - (width - line.length);
    } else {
      final restLines = width - line.length;
      charIndex = x - restLines ~/ 2;
    }
    if (charIndex < 0 || charIndex >= line.length) {
      return (null, null);
    }
    return (null, (line.codeUnitAt(charIndex), style));
  }
}
