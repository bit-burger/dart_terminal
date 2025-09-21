import 'dart:io' as io;

import 'package:dart_console/src/ffi/termlib.dart' as console;

import 'ansi_escape_codes.dart' as ansi_codes;

class AnsiTerminalController {
  final console.TermLib _termLib = console.TermLib();
  AnsiTerminalController();

  void setCursorPosition(int x, int y) {
    io.stdout.write(ansi_codes.cursorTo(x, y));
  }

  void changeCursorBlinking({required bool blinking}) {
    if(blinking) {
      io.stdout.write(ansi_codes.enableCursorBlink);
    } else {
      io.stdout.write(ansi_codes.disableCursorBlink);
    }
  }

  void queryCursorPosition() {
    io.stdout.write(ansi_codes.cursorPositionQuery);
  }

  void changeCursorVisibility({required bool hiding}) {
    if (hiding) {
      io.stdout.write(ansi_codes.hideCursor);
    } else {
      io.stdout.write(ansi_codes.showCursor);
    }
  }

  void changeScreenMode({required bool alternateBuffer}) {
    if (alternateBuffer) {
      io.stdout.write(ansi_codes.enableAlternativeBuffer);
    } else {
      io.stdout.write(ansi_codes.disableAlternativeBuffer);
    }
  }

  void bell() => io.stdout.write(ansi_codes.bell);

  void saveCursorPosition() => io.stdout.write(ansi_codes.saveCursorPositionDEC);

  void restoreCursorPosition() =>
      io.stdout.write(ansi_codes.restoreCursorPositionDEC);

  void changeSize(int width, int height) {
    _termLib
      ..setWindowWidth(width)
      ..setWindowHeight(height);
  }

  void changeTerminalTitle(String title) {
    io.stdout.write(ansi_codes.changeTerminalTitle(title));
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
      io.stdout.write(ansi_codes.enableFocusTracking);
    } else {
      io.stdout.write(ansi_codes.disableFocusTracking);
    }
  }

  void changeMouseTrackingMode({required bool enable}) {
    if (enable) {
      io.stdout.write(ansi_codes.enableMouseEvents);
    } else {
      io.stdout.write(ansi_codes.disableMouseEvents);
    }
  }

  void changeLineWrappingMode({required bool enable}) {
    if (enable) {
      io.stdout.write(ansi_codes.enableLineWrapping);
    } else {
      io.stdout.write(ansi_codes.disableLineWrapping);
    }
  }
}
