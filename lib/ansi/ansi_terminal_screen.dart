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
    changed = true;
  }

  bool calculateDifference() {
    if (newFg == null) {
      if (newFg == const TerminalForeground()) {
        if (bg != newBg) {
          bg = newBg!;
          return true;
        }
      } else {
        fg = const TerminalForeground();
        bg = newBg!;
        return true;
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
    newFg = newBg = null;
    changed = false;
  }
}

List<_TerminalCell> _rowGen(int length) =>
    List.generate(length, (_) => _TerminalCell());

class AnsiTerminalScreen {
  final List<List<_TerminalCell>> _screenBuffer;
  final List<bool> _changeList;

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
    _size = size;
  }

  void reset() {
    for (int j = 0; j < size.height; j++) {
      _changeList[j] = false;
      for (int i = 0; i < size.width; i++) {
        _screenBuffer[j][i].reset();
      }
    }
  }

  void drawPoint({
    required Position position,
    TerminalColor? backgroundColor,
    TerminalForeground? foreground,
  }) {
    if (!(Position.zero & _size).contains(position)) return;
    _changeList[position.y] = true;
    _screenBuffer[position.y][position.x].draw(foreground, backgroundColor);
  }

  void drawRect({
    required Rect rect,
    TerminalColor? backgroundColor,
    TerminalForeground? foreground,
  }) {
    rect = rect.clip(Position.zero & _size);
    for (int y = rect.y1; y <= rect.y2; y++) {
      _changeList[y] = true;
      for (int x = rect.x1; x <= rect.x2; x++) {
        _screenBuffer[y][x].draw(foreground, backgroundColor);
      }
    }
  }

  void drawText({
    required String text,
    required TerminalForegroundStyle? style,
    required Position position,
  }) {
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

  StringBuffer redrawBuff = StringBuffer();
  late TerminalForegroundStyle currentFg;
  late TerminalColor currentBg;

  // more optimizations possible (only write x coordinate)
  void drawChanges() {
    redrawBuff.clear();
    redrawBuff.write(ansi_codes.resetAllFormats);
    currentFg = TerminalForegroundStyle();
    currentBg = DefaultTerminalColor();
    for (int j = 0; j < size.height; j++) {
      if (!_changeList[j]) continue;
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
