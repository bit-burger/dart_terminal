// Dart imports:
import 'dart:io' as io;

// Project imports:
import 'package:dart_terminal/core.dart';
import '../../core/style.dart';
import '../shared/buffer_terminal_viewport.dart';
import '../shared/size_tracker.dart';
import 'escape_codes.dart' as ansi_codes;
import 'terminal_controller.dart';

class AnsiTerminalViewport extends BufferTerminalViewport {
  AnsiTerminalController _controller;
  TerminalSizeTracker _sizeTracker;

  Color? _backgroundFill;

  AnsiTerminalViewport(this._controller, this._sizeTracker);

  @override
  Size get size => _sizeTracker.currentSize;

  bool _initialActivation = true;
  void activate() {
    if (_initialActivation) {
      _initialActivation = false;
      _controller.setCursorPosition(1, 1);
    }
    io.stdout.write(ansi_codes.resetAllFormats);
    currentFg = const ForegroundStyle();
    currentBg = const Color.normal();
    resize();
  }

  void resize() {
    resizeBuffer();
    clearScreen();
    _constrainCursorPosition();
  }

  void clearScreen() {
    _backgroundFill = null;
    _transition(ForegroundStyle(), const Color.normal());
    _redrawBuff.write(ansi_codes.eraseEntireScreen);
    io.stdout.write(_redrawBuff);
    _redrawBuff.clear();
    resetBuffer();
  }

  @override
  CursorState? get cursor => _cursorPosition == null
      ? null
      : CursorState(position: _cursorPosition!, blinking: _cursorBlinking);
  bool _cursorBlinking = true;
  Position? _cursorPosition = Position.topLeft;

  @override
  set cursor(CursorState? cursor) {
    if (cursor != null) {
      if (cursor.blinking != _cursorBlinking) {
        _controller.changeCursorBlinking(blinking: cursor.blinking);
        _cursorBlinking = cursor.blinking;
      }
      if (cursor.position != _cursorPosition) {
        if (_cursorPosition == null) {
          _controller.changeCursorVisibility(hiding: false);
        }
        _controller.setCursorPosition(
          cursor.position.x + 1,
          cursor.position.y + 1,
        );
        _cursorPosition = cursor.position;
      }
      _constrainCursorPosition();
    } else if (_cursorPosition != null) {
      _controller.changeCursorVisibility(hiding: true);
      _cursorPosition = null;
    }
  }

  void _constrainCursorPosition() {
    if (_cursorPosition != null) {
      _cursorPosition = _cursorPosition!.clamp(Position.topLeft & size);
    }
  }

  @override
  void drawColor({
    Color color = const Color.normal(),
    bool optimizeByClear = true,
  }) {
    if (optimizeByClear) {
      _backgroundFill = color;
      resetBuffer(background: color);
    } else {
      super.drawColor(color: color);
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
      if (!checkRowChanged(j)) continue;
      bool lastWritten = false;
      final row = getRow(j);
      for (int i = 0; i < size.width; i++) {
        final cell = row[i];
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
