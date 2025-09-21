import 'dart:io' show stdout;

import 'package:dart_tui/ansi/native_terminal_image.dart';
import 'package:dart_tui/core/style.dart';
import 'package:dart_tui/core/terminal.dart';

import 'ansi_escape_codes.dart' as ansi_codes;

const int _leftBorderMask = 1 << 63;
const int _topBorderMask = 1 << 62;
const int _rightBorderMask = 1 << 61;
const int _bottomBorderMask = 1 << 60;
const int _borderDrawIdMask = ~(0xF << 60);

class _TerminalCell {
  bool changed = false;
  TerminalForeground fg = TerminalForeground();
  TerminalColor bg = DefaultTerminalColor();
  TerminalForeground? newFg;
  TerminalColor? newBg;
  int borderState = 0;

  void draw(TerminalForeground? fg, TerminalColor? bg) {
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
    if(newFg != null) {
      if(newFg != fg) {
        diff = true;
        fg = newFg!;
      }
      newFg = null;
    }
    if(newBg != null) {
      if(newBg != bg) {
        diff = true;
        bg = newBg!;
      }
      newBg = null;
    }
    return diff;
  }

  void reset(TerminalColor background) {
    fg = TerminalForeground();
    bg = background;
    newFg = newBg = null;
    changed = false;
  }

  void drawBorder(
    bool left,
    bool top,
    bool right,
    bool bottom,
    BorderCharSet charSet,
    TerminalColor foregroundColor,
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
    newFg = TerminalForeground(
      style: TerminalForegroundStyle(color: foregroundColor),
      codePoint: charSet.getCorrectGlyph(left, top, right, bottom),
    );
  }
}

List<_TerminalCell> _rowGen(int length) =>
    List.generate(length, (_) => _TerminalCell());

class AnsiTerminalScreen {
  final List<List<_TerminalCell>> _screenBuffer;
  final List<bool> _changeList;
  TerminalColor? _backgroundFill;

  AnsiTerminalScreen(Size size)
    : _size = size,
      _dataSize = size,
      _screenBuffer = List.generate(size.height, (_) => _rowGen(size.width)),
      _changeList = List.filled(size.height, false, growable: true);
  Size _size;
  Size _dataSize;

  Size get size => _size;

  void resize(Size size) {
    if (_size.height < size.height) {
      _changeList.addAll(
        List.generate(size.height - _size.height, (_) => false),
      );
    } else {
      _changeList.length = size.height;
    }
    if (_dataSize.width < size.width) {
      for (final row in _screenBuffer) {
        row.addAll(_rowGen(size.width - _dataSize.width));
      }
      _dataSize = Size(size.width, _dataSize.height);
    }
    if (_dataSize.height < size.height) {
      _screenBuffer.addAll(
        List.generate(
          size.height - _dataSize.height,
          (_) => _rowGen(_dataSize.width),
        ),
      );
      _dataSize = Size(_dataSize.width, size.height);
    }
    assert(
      _dataSize.height == _screenBuffer.length &&
          _screenBuffer
              .map((r) => r.length == _dataSize.width)
              .reduce((a, b) => a && b),
    );
    _size = size;
  }

  void fillBackground([TerminalColor color = const DefaultTerminalColor()]) {
    _backgroundFill = color;
    for (int j = 0; j < size.height; j++) {
      _changeList[j] = false;
      for (int i = 0; i < size.width; i++) {
        _screenBuffer[j][i].reset(color);
      }
    }
  }

  void drawPoint(
    Position position,
    TerminalColor? backgroundColor,
    TerminalForeground? foreground,
  ) {
    if (!(Position.zero & _size).contains(position)) return;
    _changeList[position.y] = true;
    _screenBuffer[position.y][position.x].draw(foreground, backgroundColor);
  }

  void drawRect(
    Rect rect,
    TerminalColor? backgroundColor,
    TerminalForeground? foreground,
  ) {
    rect = rect.clip(Position.zero & _size);
    for (int y = rect.y1; y <= rect.y2; y++) {
      _changeList[y] = true;
      for (int x = rect.x1; x <= rect.x2; x++) {
        _screenBuffer[y][x].draw(foreground, backgroundColor);
      }
    }
  }

  void drawText(
    String text,
    TerminalForegroundStyle? style,
    Position position,
  ) {
    _changeList[position.y] = true;
    for (int i = 0; i < text.length; i++) {
      int codepoint = text.codeUnitAt(i);
      final charPosition = Position(position.x + i, position.y);
      final foreground = TerminalForeground(
        style: style ?? TerminalForegroundStyle(),
        codePoint: codepoint,
      );

      if (!(Position.zero & size).contains(charPosition)) continue;
      if (codepoint < 32 || codepoint == 127) continue;

      _screenBuffer[charPosition.y][charPosition.x].draw(foreground, null);
    }
  }

  void drawBorderBox(
    Rect rect,
    BorderCharSet style,
    TerminalColor color,
    BorderDrawIdentifier drawId,
  ) {
    drawBorderLine(rect.topLeft, rect.topRight, style, color, drawId);
    drawBorderLine(rect.topRight, rect.bottomRight, style, color, drawId);
    drawBorderLine(rect.bottomLeft, rect.bottomRight, style, color, drawId);
    drawBorderLine(rect.topLeft, rect.bottomLeft, style, color, drawId);
  }

  void drawBorderLine(
    Position from,
    Position to,
    BorderCharSet style,
    TerminalColor color,
    BorderDrawIdentifier drawId,
  ) {
    if (from.x == to.x) {
      for (int y = from.y; y <= to.y; y++) {
        _changeList[y] = true;
        final cell = _screenBuffer[y][from.x];
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
        final cell = _screenBuffer[from.y][x];
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

  void drawImage(Position position, NativeTerminalImage image) {
    final clip = (Position.zero & size).clip(position & image.size);
    for (int y = clip.y1; y <= clip.y2; y++) {
      _changeList[y] = true;
      for (int x = clip.x1; x <= clip.x2; x++) {
        final color = image[Position(x - position.x, y - position.y)];
        if (color != null) _screenBuffer[y][x].draw(null, color);
      }
    }
  }

  final StringBuffer _redrawBuff = StringBuffer();
  late TerminalForegroundStyle currentFg;
  late TerminalColor currentBg;

  void initScreen() {
    _redrawBuff.write(ansi_codes.resetAllFormats);
    _redrawBuff.write(ansi_codes.eraseEntireScreen);
    currentFg = TerminalForegroundStyle();
    currentBg = DefaultTerminalColor();
  }

  /// returns if cursor has been moved
  // more optimizations possible
  // (e.g. only write x coordinate if moving horizontally)
  bool updateScreen() {
    if (_backgroundFill != null) {
      _transition(currentFg, _backgroundFill!);
      _redrawBuff.write(ansi_codes.eraseEntireScreen);
      _backgroundFill = null;
    }
    bool cursorMoved = false;
    for (int j = 0; j < size.height; j++) {
      if (!_changeList[j]) continue;
      _changeList[j] = false;
      bool lastWritten = false;
      for (int i = 0; i < size.width; i++) {
        final cell = _screenBuffer[j][i];
        if (cell.changed && cell.calculateDifference()) {
          if (!lastWritten) {
            _redrawBuff.write(ansi_codes.cursorTo(j + 1, i + 1));
          }
          _transition(cell.fg.style, cell.bg);
          _redrawBuff.writeCharCode(cell.fg.codePoint);
          lastWritten = true;
          cell.changed = false;
          cursorMoved = true;
        } else {
          lastWritten = false;
        }
      }
    }
    stdout.write(_redrawBuff.toString());
    _redrawBuff.clear();
    return cursorMoved;
  }

  bool _firstParameter = true;

  void _writeParameter(String s) {
    if (!_firstParameter) {
      _redrawBuff.writeCharCode(59);
    }
    _redrawBuff.write(s);
    _firstParameter = false;
  }

  void _transition(TerminalForegroundStyle fg, TerminalColor bg) {
    final fromBitfield = currentFg.textDecorations.bitField;
    final toBitfield = fg.textDecorations.bitField;
    final textDecorationsDiff = fromBitfield != toBitfield;
    final foregroundColorDiff =
        fg.color.comparisonCode != currentFg.color.comparisonCode;
    final backgroundColorDiff = bg.comparisonCode != currentBg.comparisonCode;
    if (!textDecorationsDiff) {
      if (foregroundColorDiff && backgroundColorDiff) {
        _redrawBuff.write(
          "${ansi_codes.CSI}${fg.color.termRepForeground};"
          "${bg.termRepBackground}m",
        );
        currentFg = fg;
        currentBg = bg;
      } else if (foregroundColorDiff) {
        _redrawBuff.write("${ansi_codes.CSI}${fg.color.termRepForeground}m");
        currentFg = fg;
      } else if (backgroundColorDiff) {
        _redrawBuff.write("${ansi_codes.CSI}${bg.termRepBackground}m");
        currentBg = bg;
      }
    } else if (toBitfield == 0) {
      _firstParameter = true;
      _redrawBuff.write(ansi_codes.CSI);
      _writeParameter("0");
      if (fg.color != const DefaultTerminalColor()) {
        _writeParameter(fg.color.termRepForeground);
      }
      if (bg != const DefaultTerminalColor()) {
        _writeParameter(bg.termRepBackground);
      }
      _redrawBuff.writeCharCode(109);
      currentFg = fg;
      currentBg = bg;
    } else {
      _firstParameter = true;
      _redrawBuff.write(ansi_codes.CSI);
      currentFg = fg;
      if (foregroundColorDiff) {
        _writeParameter(fg.color.termRepForeground);
      }
      if (backgroundColorDiff) {
        _writeParameter(bg.termRepBackground);
        currentBg = bg;
      }
      final changedBitfield = fromBitfield ^ toBitfield;
      final addedBitField = toBitfield & changedBitfield;
      for (var i = 0; i <= TextDecoration.highestBitFlag; i++) {
        final flag = 1 << i;
        if (flag & changedBitfield != 0) {
          final decoration = TextDecoration.values[i];
          if (flag & addedBitField != 0) {
            _writeParameter(decoration.onCode);
          } else {
            _writeParameter(decoration.offCode);
          }
        }
      }
      // TODO: optimization to use reset like \e[0;...;...m
      _redrawBuff.writeCharCode(109);
    }
  }
}
