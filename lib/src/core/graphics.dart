import 'geometry.dart';
import 'style.dart';

/// Terminal factory should create image instances
abstract class TerminalImage {
  Size get size;

  TerminalColor? operator [](Position position);
  void operator []=(Position position, TerminalColor? color);
}

extension type const BorderDrawIdentifier._(int id) {
  static int _currentId = 0;
  BorderDrawIdentifier() : id = _currentId++;

  int get value => id;
}

abstract class TerminalCanvas {
  Size get size;

  void drawText({
    required String text,
    required Position position,
    TerminalForegroundStyle? style,
  });

  void drawRect({
    required Rect rect,
    TerminalColor? background,
    TerminalForeground? foreground,
  });

  void drawPoint({
    required Position position,
    TerminalColor? background,
    TerminalForeground? foreground,
  });

  void drawBorderBox({
    required Rect rect,
    required BorderCharSet borderStyle,
    TerminalColor foregroundColor,
    BorderDrawIdentifier drawIdentifier,
  });

  void drawBorderLine({
    required Position from,
    required Position to,
    required BorderCharSet borderStyle,
    TerminalColor foregroundColor,
    BorderDrawIdentifier drawIdentifier,
  });

  void drawImage({
    required Position position,
    required covariant TerminalImage image,
  });
}
