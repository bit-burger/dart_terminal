import 'package:dart_tui/core/style.dart';
import 'package:dart_tui/core/terminal.dart';
import 'package:image/image.dart' as img;

/// Terminal factory should create image instances

abstract class TerminalImage {
  Size get size;

  TerminalColor? operator [](Position position);
  void operator []=(Position position, TerminalColor? color);
}

class ScaledGraphics {}
