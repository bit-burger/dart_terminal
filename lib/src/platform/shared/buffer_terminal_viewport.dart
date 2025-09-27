// Project imports:
import 'package:dart_terminal/ansi.dart';

const int _leftBorderMask = 1 << 63;
const int _topBorderMask = 1 << 62;
const int _rightBorderMask = 1 << 61;
const int _bottomBorderMask = 1 << 60;
const int _borderDrawIdMask = ~(0xF << 60);

class TerminalCell {
  bool changed = false;
  Foreground fg = Foreground();
  Color bg = Color.normal();
  Foreground? newFg;
  Color? newBg;
  int borderState = 0;

  static List<TerminalCell> rowGen(int length) =>
      List.generate(length, (_) => TerminalCell());

  void draw(Foreground? fg, Color? bg) {
    assert(fg != null || bg != null);

    if (fg != null) {
      newFg = fg;
    }
    if (bg != null) {
      newBg = bg;
    }
    changed = true;
  }

  bool calculateDifference() {
    assert(changed);
    bool diff = false;
    if (newFg != null) {
      if (newFg != fg) {
        diff = true;
        fg = newFg!;
      }
      newFg = null;
    }
    if (newBg != null) {
      if (newBg != bg) {
        diff = true;
        bg = newBg!;
      }
      newBg = null;
    }
    return diff;
  }

  void reset(Foreground foreground, Color background) {
    fg = foreground;
    bg = background;
    newFg = newBg = null;
    changed = false;
    // borderState does not need to be reset as the
    // BorderIdentifier should not be reused between resets
    // and there fore because they are unique
    // one will never find the same BorderIdentifier (of the borderState)
    // across resets
  }

  void drawBorder(
    bool left,
    bool top,
    bool right,
    bool bottom,
    BorderCharSet charSet,
    Color foregroundColor,
    BorderDrawIdentifier borderIdentifier,
  ) {
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

    changed = true;
    newFg = Foreground(
      style: ForegroundStyle(color: foregroundColor),
      codePoint: charSet.getCorrectGlyph(left, top, right, bottom),
    );
  }
}

abstract class BufferTerminalViewport extends TerminalViewport {
  final List<List<TerminalCell>> _data = [];
  final List<bool> _changeList = [];
  Size _dataSize = Size(0, 0);

  bool checkRowChanged(int row) {
    final changed = _changeList[row];
    _changeList[row] = false;
    return changed;
  }

  List<TerminalCell> getRow(int row) => _data[row];

  void resizeBuffer() {
    if (_dataSize.height < size.height) {
      _changeList.addAll(
        List.generate(size.height - _dataSize.height, (_) => false),
      );
    }
    if (_dataSize.width < size.width) {
      for (final row in _data) {
        row.addAll(TerminalCell.rowGen(size.width - _dataSize.width));
      }
      _dataSize = Size(size.width, _dataSize.height);
    }
    if (_dataSize.height < size.height) {
      _data.addAll(
        List.generate(
          size.height - _dataSize.height,
          (_) => TerminalCell.rowGen(_dataSize.width),
        ),
      );
      _dataSize = Size(_dataSize.width, size.height);
    }
    assert(
      _dataSize.height == _data.length &&
          _data
              .map((r) => r.length == _dataSize.width)
              .reduce((a, b) => a && b),
    );
  }

  void resetBuffer({
    Foreground foreground = const Foreground(),
    Color background = const Color.normal(),
  }) {
    for (int j = 0; j < size.height; j++) {
      _changeList[j] = false;
      for (int i = 0; i < size.width; i++) {
        _data[j][i].reset(foreground, background);
      }
    }
  }

  @override
  void drawColor({
    Color color = const Color.normal(),
    bool optimizeByClear = true,
  }) {
    drawRect(
      background: color,
      foreground: Foreground(),
      rect: Position.topLeft & size,
    );
  }

  @override
  void drawBorderBox({
    required Rect rect,
    required BorderCharSet style,
    Color color = const Color.normal(),
    BorderDrawIdentifier? drawId,
  }) {
    super.drawBorderBox(rect: rect, color: color, drawId: drawId, style: style);
    drawId ??= BorderDrawIdentifier();

    line(Position f, Position t, BorderDrawIdentifier id) =>
        drawBorderLine(from: f, to: t, style: style, color: color, drawId: id);

    line(rect.topLeft, rect.topRight, drawId);
    line(rect.topRight, rect.bottomRight, drawId);
    line(rect.bottomLeft, rect.bottomRight, drawId);
    line(rect.topLeft, rect.bottomLeft, drawId);
  }

  @override
  void drawBorderLine({
    required Position from,
    required Position to,
    required BorderCharSet style,
    Color color = const Color.normal(),
    BorderDrawIdentifier? drawId,
  }) {
    drawId ??= BorderDrawIdentifier();
    if (from.x == to.x) {
      for (int y = from.y; y <= to.y; y++) {
        _changeList[y] = true;
        final cell = _data[y][from.x];
        cell.drawBorder(
          false,
          y != from.y,
          false,
          y != to.y,
          style,
          color,
          drawId,
        );
      }
    } else {
      _changeList[from.y] = true;
      for (int x = from.x; x <= to.x; x++) {
        final cell = _data[from.y][x];
        cell.drawBorder(
          x != from.x,
          false,
          x != to.x,
          false,
          style,
          color,
          drawId,
        );
      }
    }
  }

  @override
  void drawImage({
    required Position position,
    required NativeTerminalImage image,
  }) {
    final clip = (Position.topLeft & size).clip(position & image.size);
    for (int y = clip.y1; y <= clip.y2; y++) {
      _changeList[y] = true;
      for (int x = clip.x1; x <= clip.x2; x++) {
        final color = image[Position(x - position.x, y - position.y)];
        if (color != null) _data[y][x].draw(null, color);
      }
    }
  }

  @override
  void drawPoint({
    required Position position,
    Color? background,
    Foreground? foreground,
  }) {
    if (!(Position.topLeft & size).contains(position)) return;
    _changeList[position.y] = true;
    _data[position.y][position.x].draw(foreground, background);
  }

  @override
  void drawRect({
    required Rect rect,
    Color? background,
    Foreground? foreground,
  }) {
    rect = rect.clip(Position.topLeft & size);
    for (int y = rect.y1; y <= rect.y2; y++) {
      _changeList[y] = true;
      for (int x = rect.x1; x <= rect.x2; x++) {
        _data[y][x].draw(foreground, background);
      }
    }
  }

  @override
  void drawText({
    required String text,
    required Position position,
    TextStyle style = const TextStyle(),
  }) {
    _changeList[position.y] = true;
    for (int i = 0; i < text.length; i++) {
      int codepoint = text.codeUnitAt(i);
      final charPosition = Position(position.x + i, position.y);
      final foreground = Foreground(style: style.fgStyle, codePoint: codepoint);

      if (!(Position.topLeft & size).contains(charPosition)) continue;
      if (codepoint < 32 || codepoint == 127) continue;

      _data[charPosition.y][charPosition.x].draw(
        foreground,
        style.backgroundColor,
      );
    }
  }

  @override
  void drawUnicodeText({
    required String text,
    required Position position,
    TextStyle style = const TextStyle(),
  }) {}
}
