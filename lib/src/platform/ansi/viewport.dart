// Dart imports:
import 'dart:io' as io;

// Project imports:
import 'package:dart_terminal/core.dart';
import 'package:flutter/animation.dart';
import '../../core/style.dart';
import '../shared/buffer_viewport.dart';
import '../shared/size_tracker.dart';
import 'escape_codes.dart' as ansi_codes;
import 'controller.dart';

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
      _cursorPosition = Position.topLeft;
      _controller.setCursorPosition(_cursorPosition);
      // should also be set explicitly by controller?
      _cursorHidden = false;
      _cursorBlinking = true;
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
  CursorState? get cursor => _cursorHidden
      ? null
      : CursorState(position: _cursorPosition!, blinking: _cursorBlinking);
  late bool _cursorBlinking;
  late bool _cursorHidden;
  late Position _cursorPosition;

  @override
  set cursor(CursorState? cursor) {
    if (cursor != null) {
      if (cursor.blinking != _cursorBlinking) {
        _controller.changeCursorBlinking(blinking: cursor.blinking);
        _cursorBlinking = cursor.blinking;
      }
      if (cursor.position != _cursorPosition) {
        _controller.setCursorPositionRelative(_cursorPosition, cursor.position);
        _cursorPosition = cursor.position;
      }
      if (_cursorHidden) {
        _controller.changeCursorVisibility(hiding: false);
        _cursorHidden = false;
      }
      _constrainCursorPosition();
    } else if (!_cursorHidden) {
      _controller.changeCursorVisibility(hiding: true);
      _cursorHidden = true;
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
    Position oldCursorPosition = _cursorPosition;
    for (int y = 0; y < size.height; y++) {
      if (!checkRowChanged(y)) continue;
      final row = getRow(y);
      for (int x = 0; x < size.width; x++) {
        final cell = row[x];
        final cellPos = Position(x, y);
        if (cell.changed) {
          if (cell.extension != null && _tryRenderExtension(cell, cellPos)) {
            continue;
          }
          if (cell.calculateDifference()) {
            if (cellPos != _cursorPosition) {
              _redrawBuff.write(ansi_codes.cursorTo(y + 1, x + 1));
            }
            _transition(cell.fg.style, cell.bg);
            _redrawBuff.writeCharCode(cell.fg.codeUnit);
            cell.changed = false;
          }
        }
      }
    }
    io.stdout.write(_redrawBuff.toString());
    _redrawBuff.clear();
    // cursor position should remain unchanged if cursor visible
    if (oldCursorPosition != _cursorPosition && !_cursorHidden) {
      _controller.setCursorPositionRelative(_cursorPosition, oldCursorPosition);
      _cursorPosition = oldCursorPosition;
    }
  }

  /// try to render an extension and if it succeeds return true
  bool _tryRenderExtension(TerminalCell renderCell, Position cellPos) {
    return true;
    final extension = renderCell.extension!;
    for (int y = cellPos.y; y < extension.size.height + cellPos.y; y++) {
      final row = getRow(y);
      for (int x = cellPos.x; x < extension.size.width + cellPos.x; x++) {
        final cell = row[x];
        if ((cell.changed || cell.isDifferent()) || cell.extension != null) {
          // extension is invalid as something has been drawn on top of it
          return false;
        }
      }
    }
    for (int y = cellPos.y; y < extension.size.height + cellPos.y; y++) {
      final row = getRow(y);
      for (int x = cellPos.x; x < extension.size.width + cellPos.x; x++) {
        if (row[x].fg != null) {
          // extension is invalid as something has been drawn on top of it
        }
      }
    }
    if (extension is CharacterCellExtension) {
      _redrawBuff.write(extension.grapheme);
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
