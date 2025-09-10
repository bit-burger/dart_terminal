import 'dart:collection';

import 'package:dart_tui/core/style.dart';
import 'package:dart_tui/core/terminal.dart';

class _TerminalCell {
  bool changed = false;
  TerminalForeground foreground = TerminalForeground();
  TerminalColor backgroundColor = DefaultTerminalColor();

  void draw(TerminalForeground? foreground, TerminalColor? backgroundColor) {
    if (foreground == null) {
      if (foreground == TerminalForeground()) {
        if (this.backgroundColor != backgroundColor) {
          changed = true;
          this.backgroundColor = backgroundColor!;
        }
      } else {
        changed = true;
        this.foreground = TerminalForeground();
        this.backgroundColor = backgroundColor!;
      }
    } else {
      if (this.foreground == foreground) {
        if (backgroundColor != null &&
            this.backgroundColor != backgroundColor) {
          changed = true;
          this.backgroundColor = backgroundColor;
        }
      } else {
        changed = true;
        if (backgroundColor != null) this.backgroundColor = backgroundColor;
      }
    }
  }

  void reset() {
    foreground = TerminalForeground();
    backgroundColor = DefaultTerminalColor();
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
  set size(Size size) {
    if (_dataSize.width < size.width) {
      for (final row in _screenBuffer) {
        row.addAll(_rowGen(size.width - _dataSize.width));
      }
      _dataSize = Size(size.width, _dataSize.height);
    } else if (_size.width > size.width) {
      for (int j = 0; j < _size.height; j++) {
        for (int i = size.width; i < _size.width; i++) {
          _screenBuffer[j][i].reset();
        }
      }
    }
    if (_dataSize.height < size.height) {
      _screenBuffer.addAll(
        List.generate(
          size.height - _dataSize.height,
          (_) => _rowGen(_dataSize.width),
        ),
      );
      _dataSize = Size(_dataSize.width, size.height);
    } else if (_dataSize.height > size.height) {
      for (int j = size.height; j < _size.height; j++) {
        for (int i = 0; i < size.width; i++) {
          _screenBuffer[j][i].reset();
        }
      }
    }
    _size = size;
  }

  void optimizeNextFlushForFullUpdate() {
    _usingChangeListForNextFlush = false;
  }

  void _checkCanUseChangeList(int additions) {
    if (_changeList.length + additions > _changeList.maxLength) {
      _usingChangeListForNextFlush = false;
    }
  }

  void _rawDraw(
    int x,
    int y,
    TerminalColor? background,
    TerminalForeground? foreground,
  ) {
    final buff = _screenBuffer[x][y];
  }

  void drawPoint({
    required Position position,
    TerminalColor? backgroundColor,
    TerminalForeground? foreground,
  }) {
    if (!(Position.zero & _size).contains(position)) return;
    _screenBuffer[position.x][position.y].draw(foreground, backgroundColor);
    if (_usingChangeListForNextFlush) {
      _changeList.addPosition(position);
    }
  }

  void drawRect({
    required Rect rect,
    TerminalColor? backgroundColor,
    TerminalForeground? foreground,
  }) {
    rect = rect.clip(Position.zero & _size);
    for (int y = rect.y1; y <= rect.y2; y++) {
      if (_usingChangeListForNextFlush) {
        _changeList.addPosition(Position(y, rect.x1));
      }
      for (int x = rect.x1; x <= rect.x2; x++) {
        _screenBuffer[x][y].draw(foreground, backgroundColor);
      }
    }
  }

  void drawString({
    required String text,
    required TerminalForeground? foreground,
    required Position position,
  }) {
  }

  void flush() {
    if(_usingChangeListForNextFlush) {

    } else {

    }
    _usingChangeListForNextFlush = true;
  }
}
