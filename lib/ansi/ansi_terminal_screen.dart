import 'dart:io' show stdout;

import 'package:dart_tui/core/style.dart';
import 'package:dart_tui/core/terminal.dart';

import 'ansi_escape_codes.dart' as ansi_codes;

class _TerminalCell {
  bool changed = false;
  TerminalForeground fg = TerminalForeground();
  TerminalColor bg = DefaultTerminalColor();
  TerminalForeground? newFg;
  TerminalColor? newBg;

  void draw(TerminalForeground? fg, TerminalColor? bg) {
    assert(fg != null || bg != null);

    newFg = fg;
    if (bg != null) {
      newBg = bg;
    }
  }

  bool calculateDifference() {
    if (newFg == null) {
      if (newFg == const TerminalForeground()) {
        if (bg != newBg) {
          bg = newBg!;
          return true;
        }
      } else {
        changed = true;
        fg = const TerminalForeground();
        bg = newBg!;
      }
    } else {
      if (fg == newFg) {
        if (newBg != null && bg != newBg) {
          bg = newBg!;
          return true;
        }
      } else {
        fg = newFg!;
        if (newBg != null) bg = newBg!;
        return true;
      }
    }
    return false;
  }

  void reset() {
    fg = TerminalForeground();
    bg = DefaultTerminalColor();
    changed = false;
  }
}

List<_TerminalCell> _rowGen(int length) =>
    List.generate(length, (_) => _TerminalCell());

class _ScreenBufferChangeList {
  final List<Position> _data;
  int _length = 0;
  int get length => _length;
  int get maxLength => _data.length;

  _ScreenBufferChangeList(int maxLength)
    : _data = List.filled(maxLength, Position(0, 0), growable: false);

  void addPosition(Position position) {
    _data[_length] = position;
    _length++;
  }

  void clear() {
    _length = 0;
  }

  operator [](int i) {
    assert(i < length);
    return _data[i];
  }
}

class AnsiTerminalScreen {
  final List<List<_TerminalCell>> _screenBuffer;
  final _ScreenBufferChangeList _changeList;
  bool _usingChangeListForNextFlush = true;
  AnsiTerminalScreen(Size size, int maxChangeListLength)
    : _size = size,
      _dataSize = size,
      _screenBuffer = List.generate(size.height, (_) => _rowGen(size.width)),
      _changeList = _ScreenBufferChangeList(maxChangeListLength);
  Size _size;
  Size _dataSize;

  Size get size => _size;

  void resize(Size size) {
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
    _size = size;
  }

  void reset() {
    _changeList.clear();
    for (int i = 0; i < size.width; i++) {
      for (int j = 0; j < size.height; j++) {
        _screenBuffer[j][i].reset();
      }
    }
  }

  void optimizeForFullDraw() {
    _usingChangeListForNextFlush = false;
  }

  bool _checkCanUseChangeList(int additions) {
    if (!_usingChangeListForNextFlush) return false;
    if (_changeList.length + additions > _changeList.maxLength) {
      _usingChangeListForNextFlush = false;
      return false;
    }
    return true;
  }

  void drawPoint({
    required Position position,
    TerminalColor? backgroundColor,
    TerminalForeground? foreground,
  }) {
    if (!(Position.zero & _size).contains(position)) return;
    _screenBuffer[position.y][position.x].draw(foreground, backgroundColor);
    if (_checkCanUseChangeList(1)) {
      _changeList.addPosition(position);
    }
  }

  void drawRect({
    required Rect rect,
    TerminalColor? backgroundColor,
    TerminalForeground? foreground,
  }) {
    rect = rect.clip(Position.zero & _size);
    if (_checkCanUseChangeList(rect.height)) {
      for (int y = rect.y1; y <= rect.y2; y++) {
        _changeList.addPosition(Position(y, rect.x1));
        for (int x = rect.x1; x <= rect.x2; x++) {
          _screenBuffer[y][x].draw(foreground, backgroundColor);
        }
      }
    } else {
      for (int y = rect.y1; y <= rect.y2; y++) {
        for (int x = rect.x1; x <= rect.x2; x++) {
          _screenBuffer[y][x].draw(foreground, backgroundColor);
        }
      }
    }
  }

  void drawString({
    required String text,
    required TerminalForegroundStyle? style,
    required Position position,
  }) {
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

  StringBuffer redrawBuff = StringBuffer();
  late TerminalForegroundStyle currentFg;
  late TerminalColor currentBg;

  void drawChanges() {
    if (_usingChangeListForNextFlush && _changeList.maxLength == 0) return;
    redrawBuff.clear();
    redrawBuff.write(ansi_codes.resetAllFormats);
    currentFg = TerminalForegroundStyle();
    currentBg = DefaultTerminalColor();
    if (_usingChangeListForNextFlush) {
      cl:
      for (int i = 0; i < _changeList.maxLength; i++) {
        Position pos = _changeList[i];
        _TerminalCell cell = _screenBuffer[pos.y][pos.x];
        if (!cell.changed || !(Position.zero & size).contains(pos)) continue cl;
        redrawBuff.write(ansi_codes.cursorTo(pos.x + 1, pos.y + 1));
        do {
          cell.changed = false;
          _transition(cell.fg.style, cell.bg);
          redrawBuff.writeCharCode(cell.fg.codePoint);
          pos = Position(pos.x + 1, pos.y);
          cell = _screenBuffer[pos.y][pos.x];
        } while ((Position.zero & size).contains(pos) && cell.changed);
      }
    } else {
      for (int j = 0; j < size.height; j++) {
        // more optimizations possible (only write x coordinate)
        bool lastWritten = false;
        for (int i = 0; i < size.width; i++) {
          final cell = _screenBuffer[j][i];
          if (cell.changed && cell.calculateDifference()) {
            if (!lastWritten) {
              redrawBuff.write(ansi_codes.cursorTo(j + 1, i + 1));
            }
            _transition(cell.fg.style, cell.bg);
            redrawBuff.writeCharCode(cell.fg.codePoint);
            lastWritten = true;
            cell.changed = false;
          } else {
            lastWritten = false;
          }
        }
      }
    }
    _usingChangeListForNextFlush = true;
    _transition(TerminalForegroundStyle(), DefaultTerminalColor());
    stdout.write(redrawBuff.toString());
  }

  bool _firstParameter = true;

  void _writeParameter(String s) {
    if (!_firstParameter) {
      redrawBuff.writeCharCode(59);
    }
    redrawBuff.write(s);
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
        redrawBuff.write(
          "${ansi_codes.CSI}${fg.color.termRepForeground};"
          "${bg.termRepBackground}m",
        );
        currentFg = fg;
        currentBg = bg;
      } else if (foregroundColorDiff) {
        redrawBuff.write("${ansi_codes.CSI}${fg.color.termRepForeground}m");
        currentFg = fg;
      } else if (backgroundColorDiff) {
        redrawBuff.write("${ansi_codes.CSI}${bg.termRepBackground}m");
        currentBg = bg;
      }
    } else if (toBitfield == 0) {
      redrawBuff.write(
        "${ansi_codes.CSI}0;${fg.color.termRepForeground};"
        "${bg.termRepBackground}m",
      );
      currentFg = fg;
      currentBg = bg;
    } else {
      _firstParameter = true;
      redrawBuff.write(ansi_codes.CSI);
      currentFg = fg;
      if (foregroundColorDiff) {
        _writeParameter(fg.color.termRepForeground);
      } else if (backgroundColorDiff) {
        _writeParameter(fg.color.termRepBackground);
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
      redrawBuff.writeCharCode(109);
    }
  }
}
