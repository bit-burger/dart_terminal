import 'dart:io';

import 'package:dart_console/src/ffi/termlib.dart';
import 'ansi_escape_codes.dart' as ansi_codes;

class AnsiTerminalController {
  final TermLib _termLib = TermLib();
  AnsiTerminalController();

  void setCursorPosition(int x, int y) {
    stdout.write(ansi_codes.cursorTo(x, y));
  }

  void queryCursorPosition() {
    stdout.write(ansi_codes.cursorPositionQuery);
  }

  void changeCursorVisibility({required bool hiding}) {
    if (hiding) {
      stdout.write(ansi_codes.hideCursor);
    } else {
      stdout.write(ansi_codes.showCursor);
    }
  }

  void changeScreenMode({required bool alternateBuffer}) {
    if (alternateBuffer) {
      stdout.write(ansi_codes.enableAlternativeBuffer);
    } else {
      stdout.write(ansi_codes.disableAlternativeBuffer);
    }
  }

  void bell() => stdout.write(ansi_codes.bell);

  void saveCursorPosition() => stdout.write(ansi_codes.saveCursorPositionDEC);

  void restoreCursorPosition() =>
      stdout.write(ansi_codes.restoreCursorPositionDEC);

  void changeSize(int width, int height) {
    _termLib
      ..setWindowWidth(width)
      ..setWindowHeight(height);
  }

  void changeTerminalTitle(String title) {
    stdout.write(ansi_codes.changeTerminalTitle(title));
  }

  void setInputMode(bool raw) {
    if (raw) {
      _termLib.enableRawMode();
    } else {
      _termLib.disableRawMode();
    }
  }

  void changeFocusTrackingMode({required bool enable}) {
    if (enable) {
      stdout.write(ansi_codes.enableFocusTracking);
    } else {
      stdout.write(ansi_codes.disableFocusTracking);
    }
  }

  void changeMouseTrackingMode({required bool enable}) {
    if (enable) {
      stdout.write(ansi_codes.enableMouseEvents);
    } else {
      stdout.write(ansi_codes.disableMouseEvents);
    }
  }

  void changeLineWrappingMode({required bool enable}) {
    if (enable) {
      stdout.write(ansi_codes.enableLineWrapping);
    } else {
      stdout.write(ansi_codes.disableLineWrapping);
    }
  }
}
