// Project imports:
import 'package:dart_terminal/core.dart';

import 'buffer.dart';

class FlutterTerminalViewport extends TerminalViewport {
  bool hasSize = false;
  late List<BufferLine> visibleBuffer;
  late List<BufferLine> drawingBuffer;
  late Size _size;
  Size get size => _size;
  late void Function() onChanged;

  void updateSize(Size size) {
    hasSize = true;
    _size = size;
    visibleBuffer = createBuffer(size);
    drawingBuffer = createBuffer(size);
  }

  @override
  CursorState? cursor;

  @override
  void drawColor({
    Color color = const Color.normal(),
    bool optimizeByClear = true,
  }) {}

  @override
  void drawImage({
    required covariant TerminalImage image,
    required Position position,
  }) {
    // TODO: implement drawImage
  }

  @override
  void drawPoint({
    required Position position,
    Color? background,
    Foreground? foreground,
  }) {
    // TODO: implement drawPoint
  }

  @override
  void drawRect({
    required Rect rect,
    Color? background,
    Foreground? foreground,
  }) {
    // TODO: implement drawRect
  }

  @override
  void drawText({
    required String text,
    required Position position,
    ForegroundStyle? style,
  }) {
    // TODO: implement drawText
  }

  @override
  void updateScreen() {
    final newDrawingBuffer = visibleBuffer;
    for (int i = 0; i < size.height; i++) {
      newDrawingBuffer[i].copyCompleteFrom(drawingBuffer[i]);
    }
    visibleBuffer = drawingBuffer;
    drawingBuffer = newDrawingBuffer;
    onChanged();
  }
}
