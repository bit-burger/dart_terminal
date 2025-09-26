part of 'ansi_terminal_service.dart';

const int _leftBorderMask = 1 << 63;
const int _topBorderMask = 1 << 62;
const int _rightBorderMask = 1 << 61;
const int _bottomBorderMask = 1 << 60;
const int _borderDrawIdMask = ~(0xF << 60);

class _TerminalCell {
  bool changed = false;
  Foreground fg = Foreground();
  Color bg = Color.normal();
  Foreground? newFg;
  Color? newBg;
  int borderState = 0;

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

  void reset(Color background) {
    fg = Foreground();
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

List<_TerminalCell> _rowGen(int length) =>
    List.generate(length, (_) => _TerminalCell());

class _AnsiTerminalViewport extends TerminalViewport {
  final AnsiTerminalService _service;
  AnsiTerminalController get _controller => _service._controller;

  final List<List<_TerminalCell>> _screenBuffer = [];
  final List<bool> _changeList = [];
  Size _dataSize = Size(0, 0);
  Color? _backgroundFill;

  _AnsiTerminalViewport._(this._service);

  @override
  Size get size => _service._sizeTracker.currentSize;

  bool _initialActivation = true;
  void _onActivationEvent() {
    if (_initialActivation) {
      _initialActivation = false;
      _controller.setCursorPosition(1, 1);
    }
    io.stdout.write(ansi_codes.resetAllFormats);
    currentFg = ForegroundStyle();
    currentBg = Color.normal();
    _onResizeEvent();
  }

  void _onResizeEvent() {
    _resizeBuffer();
    drawColor(optimizeByClear: true);
    updateScreen();
    _constrainCursorPositionBySize();
  }

  void _resizeBuffer() {
    if (_dataSize.height < size.height) {
      _changeList.addAll(
        List.generate(size.height - _dataSize.height, (_) => false),
      );
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
  }

  @override
  CursorState? get cursor => _cursorPosition == null
      ? null
      : CursorState(position: _cursorPosition!, blinking: _cursorBlinking);
  bool _cursorBlinking = true;
  Position? _cursorPosition = Position.zero;

  @override
  set cursor(CursorState? cursor) {
    if (cursor != null) {
      if (cursor.blinking != _cursorBlinking) {
        _service._controller.changeCursorBlinking(blinking: cursor.blinking);
        _cursorBlinking = cursor.blinking;
      }
      if (cursor.position != _cursorPosition) {
        if (_cursorPosition == null) {
          _service._controller.changeCursorVisibility(hiding: false);
        }
        _controller.setCursorPosition(
          cursor.position.x + 1,
          cursor.position.y + 1,
        );
        _cursorPosition = cursor.position;
      }
      _constrainCursorPositionBySize();
    } else if (_cursorPosition != null) {
      _controller.changeCursorVisibility(hiding: true);
      _cursorPosition = null;
    }
  }

  void _constrainCursorPositionBySize() {
    if (_cursorPosition != null) {
      _cursorPosition = _cursorPosition!.clamp(Position.zero & size);
    }
  }

  @override
  void drawColor({
    Color color = const Color.normal(),
    bool optimizeByClear = true,
  }) {
    if (optimizeByClear) {
      _fillBackgroundOptimizedByClear(color);
    } else {
      drawRect(
        background: color,
        foreground: Foreground(),
        rect: Position.zero & size,
      );
    }
  }

  void _fillBackgroundOptimizedByClear(Color color) {
    _backgroundFill = color;
    for (int j = 0; j < size.height; j++) {
      _changeList[j] = false;
      for (int i = 0; i < size.width; i++) {
        _screenBuffer[j][i].reset(color);
      }
    }
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

  @override
  void drawImage({
    required Position position,
    required NativeTerminalImage image,
  }) {
    final clip = (Position.zero & size).clip(position & image.size);
    for (int y = clip.y1; y <= clip.y2; y++) {
      _changeList[y] = true;
      for (int x = clip.x1; x <= clip.x2; x++) {
        final color = image[Position(x - position.x, y - position.y)];
        if (color != null) _screenBuffer[y][x].draw(null, color);
      }
    }
  }

  @override
  void drawPoint({
    required Position position,
    Color? background,
    Foreground? foreground,
  }) {
    if (!(Position.zero & size).contains(position)) return;
    _changeList[position.y] = true;
    _screenBuffer[position.y][position.x].draw(foreground, background);
  }

  @override
  void drawRect({
    required Rect rect,
    Color? background,
    Foreground? foreground,
  }) {
    rect = rect.clip(Position.zero & size);
    for (int y = rect.y1; y <= rect.y2; y++) {
      _changeList[y] = true;
      for (int x = rect.x1; x <= rect.x2; x++) {
        _screenBuffer[y][x].draw(foreground, background);
      }
    }
  }

  @override
  void drawText({
    required String text,
    required Position position,
    ForegroundStyle? style,
  }) {
    _changeList[position.y] = true;
    for (int i = 0; i < text.length; i++) {
      int codepoint = text.codeUnitAt(i);
      final charPosition = Position(position.x + i, position.y);
      final foreground = Foreground(
        style: style ?? ForegroundStyle(),
        codePoint: codepoint,
      );

      if (!(Position.zero & size).contains(charPosition)) continue;
      if (codepoint < 32 || codepoint == 127) continue;

      _screenBuffer[charPosition.y][charPosition.x].draw(foreground, null);
    }
  }

  final StringBuffer _redrawBuff = StringBuffer();
  late ForegroundStyle currentFg;
  late Color currentBg;

  /// returns if cursor has been moved
  // more optimizations possible
  // (e.g. only write x coordinate if moving horizontally)
  @override
  void updateScreen() {
    if (_backgroundFill != null) {
      _transition(ForegroundStyle(), _backgroundFill!);
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
    io.stdout.write(_redrawBuff.toString());
    _redrawBuff.clear();
    if (cursorMoved && _cursorPosition != null) {
      _controller.setCursorPosition(
        _cursorPosition!.x + 1,
        _cursorPosition!.y + 1,
      );
    }
  }

  bool _firstParameter = true;

  void _writeParameter(String s) {
    if (!_firstParameter) {
      _redrawBuff.writeCharCode(59);
    }
    _redrawBuff.write(s);
    _firstParameter = false;
  }

  void _transition(ForegroundStyle fg, Color bg) {
    final fromEffects = currentFg.effects;
    final toEffects = fg.effects;
    final textEffectsDiff = fromEffects != toEffects;
    final foregroundColorDiff = !equalsColor(fg.color, currentFg.color);
    final backgroundColorDiff = !equalsColor(bg, currentBg);
    if (!textEffectsDiff) {
      if (foregroundColorDiff && backgroundColorDiff) {
        _redrawBuff.write(
          "${ansi_codes.CSI}${fgSgr(fg.color)};"
          "${bgSgr(bg)}m",
        );
        currentFg = fg;
        currentBg = bg;
      } else if (foregroundColorDiff) {
        _redrawBuff.write("${ansi_codes.CSI}${fgSgr(fg.color)}m");
        currentFg = fg;
      } else if (backgroundColorDiff) {
        _redrawBuff.write("${ansi_codes.CSI}${bgSgr(bg)}m");
        currentBg = bg;
      }
    } else if (toEffects.isEmpty) {
      _firstParameter = true;
      _redrawBuff.write(ansi_codes.CSI);
      _writeParameter("0");
      if (fg.color != const Color.normal()) {
        _writeParameter(fgSgr(fg.color));
      }
      if (bg != const Color.normal()) {
        _writeParameter(bgSgr(bg));
      }
      _redrawBuff.writeCharCode(109);
      currentFg = fg;
      currentBg = bg;
    } else {
      _firstParameter = true;
      _redrawBuff.write(ansi_codes.CSI);
      currentFg = fg;
      if (foregroundColorDiff) {
        _writeParameter(fgSgr(fg.color));
      }
      if (backgroundColorDiff) {
        _writeParameter(bgSgr(bg));
        currentBg = bg;
      }
      final changedEffects = fromEffects ^ toEffects;
      final addedEffects = toEffects & changedEffects;
      // instead iterate TextDecoration.values
      for (final effect in TextEffect.values) {
        if (effect.containedIn(changedEffects)) {
          if (effect.containedIn(addedEffects)) {
            _writeParameter(effect.onCode);
          } else {
            _writeParameter(effect.offCode);
          }
        }
      }

      // TODO: optimization to use reset like \e[0;...;...m
      _redrawBuff.writeCharCode(109);
    }
  }
}
