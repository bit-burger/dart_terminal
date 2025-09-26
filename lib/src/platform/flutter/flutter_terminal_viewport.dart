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

  CursorState? _cursor = CursorState(position: Position.topLeft);
  @override
  CursorState? get cursor => _cursor;
  set cursor(CursorState? cursor) {
    _cursor = cursor;
    onChanged();
  }

  @override
  void drawColor({
    Color color = const Color.normal(),
    bool optimizeByClear = true,
  }) {
    for (final line in drawingBuffer) {
      for (int i = 0; i < size.height; i++) {
        line.setCell(i, bg: color);
      }
    }
  }

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
    if (!(Position.topLeft & size).contains(position)) return;
    drawingBuffer[position.y].setCell(
      position.x,
      fg: foreground,
      bg: background,
    );
  }

  @override
  void drawRect({
    required Rect rect,
    Color? background,
    Foreground? foreground,
  }) {
    rect = rect.clip(Position.topLeft & size);
    for (int y = rect.y1; y <= rect.y2; y++) {
      for (int x = rect.x1; x <= rect.x2; x++) {
        drawingBuffer[y].setCell(x, fg: foreground, bg: background);
      }
    }
  }

  @override
  void drawText({
    required String text,
    required Position position,
    ForegroundStyle? style,
  }) {
    for (int i = 0; i < text.length; i++) {
      int codepoint = text.codeUnitAt(i);
      final charPosition = Position(position.x + i, position.y);
      final foreground = Foreground(
        style: style ?? ForegroundStyle(),
        codePoint: codepoint,
      );

      if (!(Position.topLeft & size).contains(charPosition)) continue;
      if (codepoint < 32 || codepoint == 127) continue;

      drawingBuffer[charPosition.y].setCell(
        charPosition.x,
        fg: foreground,
        bg: null,
      );
    }
  }

  @override
  void updateScreen() {
    final newDrawingBuffer = visibleBuffer;
    for (int i = 0; i < size.height; i++) {
      newDrawingBuffer[i].copyFrom(drawingBuffer[i]);
    }
    visibleBuffer = drawingBuffer;
    drawingBuffer = newDrawingBuffer;
    onChanged();
  }

  static const int _leftBorderMask = 1 << 63;
  static const int _topBorderMask = 1 << 62;
  static const int _rightBorderMask = 1 << 61;
  static const int _bottomBorderMask = 1 << 60;
  static const int _borderDrawIdMask = ~(0xF << 60);

  late Map<Position, int> borderStates;

  void drawBorder(
    Position position,
    bool left,
    bool top,
    bool right,
    bool bottom,
    BorderCharSet charSet,
    Color foregroundColor,
    BorderDrawIdentifier borderIdentifier,
  ) {
    var borderState = borderStates[position] ?? 0;
    if (borderIdentifier.value != (_borderDrawIdMask & borderState)) {
      borderState = borderIdentifier.value;
    }
    left = left || (borderState & _leftBorderMask != 0);
    top = top || (borderState & _topBorderMask != 0);
    right = right || (borderState & _rightBorderMask != 0);
    bottom = bottom || (borderState & _bottomBorderMask != 0);
    if (left) borderState = borderState | _leftBorderMask;
    if (top) borderState = borderState | _topBorderMask;
    if (right) borderState = borderState | _rightBorderMask;
    if (bottom) borderState = borderState | _bottomBorderMask;

    borderStates[position] = borderState;

    final fg = Foreground(
      style: ForegroundStyle(color: foregroundColor),
      codePoint: charSet.getCorrectGlyph(left, top, right, bottom),
    );
    drawingBuffer[position.y].setCell(position.x, fg: fg);
  }
}
