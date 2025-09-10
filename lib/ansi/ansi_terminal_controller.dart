import 'dart:io';

import 'package:dart_console/src/ffi/termlib.dart';
import 'ansi_escape_codes.dart' as ansi_codes;

abstract class TerminalController {
  const TerminalController();

  void changeCursorVisibility({required bool hiding});
  void changeSize(int width, int height);
  void changeTerminalTitle(String title);
  void setCursorPosition(int x, int y);
  void bell();

  void changeScreenMode({required bool alternateBuffer});
  void saveCursorPosition();
  void restoreCursorPosition();
  void setInputMode(bool raw);
  void changeMouseTrackingMode({required bool enable});
  void changeFocusTrackingMode({required bool enable});
  void changeLineWrappingMode({required bool enable});
}

class AnsiTerminalController extends TerminalController {
  // TODO: might disable controlc etc.
  final bool useTermLib;

  const AnsiTerminalController({this.useTermLib = true});

  @override
  void setCursorPosition(int x, int y) {
    stdout.write(ansi_codes.cursorTo(x, y));
  }

  @override
  void changeCursorVisibility({required bool hiding}) {
    if (hiding) {
      stdout.write(ansi_codes.hideCursor);
    } else {
      stdout.write(ansi_codes.showCursor);
    }
  }

  @override
  void changeScreenMode({required bool alternateBuffer}) {
    if (alternateBuffer) {
      stdout.write(ansi_codes.enableAlternativeBuffer);
    } else {
      stdout.write(ansi_codes.disableAlternativeBuffer);
    }
  }

  @override
  void bell() => stdout.write(ansi_codes.bell);

  @override
  void saveCursorPosition() => stdout.write(ansi_codes.saveCursorPositionDEC);

  @override
  void restoreCursorPosition() =>
      stdout.write(ansi_codes.restoreCursorPositionDEC);

  @override
  void changeSize(int width, int height) {
    if (useTermLib) {
      TermLib()
        ..setWindowWidth(width)
        ..setWindowHeight(height);
    } else {
      stdout.write(ansi_codes.changeWindowDimension(width, height));
    }
  }

  @override
  void changeTerminalTitle(String title) {
    stdout.write(ansi_codes.changeTerminalTitle(title));
  }

  @override
  void setInputMode(bool raw) {
    if (useTermLib) {
      if (raw) {
        TermLib().enableRawMode();
      } else {
        TermLib().disableRawMode();
      }
    } else {
      stdin.echoMode = !raw;
      stdin.lineMode = !raw;
    }
  }

  @override
  void changeFocusTrackingMode({required bool enable}) {
    if(enable) {
      stdout.write(ansi_codes.enableFocusTracking);
    } else {
      stdout.write(ansi_codes.disableFocusTracking);
    }
  }

  @override
  void changeMouseTrackingMode({required bool enable}) {
    if(enable) {
      stdout.write(ansi_codes.enableFocusTracking);
    } else {
      stdout.write(ansi_codes.disableFocusTracking);
    }
  }

  @override
  void changeLineWrappingMode({required bool enable}) {
    if(enable) {
      stdout.write(ansi_codes.enableLineWrapping);
    } else {
      stdout.write(ansi_codes.disableLineWrapping);
    }
  }
}
