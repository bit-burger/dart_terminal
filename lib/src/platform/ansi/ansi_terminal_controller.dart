import 'dart:io' as io;
import 'package:dart_console/src/ffi/termlib.dart' as console;
import 'ansi_escape_codes.dart' as ansi_codes;

/// Controls terminal behavior using ANSI escape sequences.
///
/// This class provides high-level methods to manipulate terminal state including:
/// - Cursor positioning and visibility
/// - Screen buffer management
/// - Terminal modes and settings
/// - Input handling configuration
class AnsiTerminalController {
  /// Native terminal library for low-level operations
  final console.TermLib _termLib = console.TermLib();

  /// Moves the cursor to the specified position.
  ///
  /// Coordinates are 1-based, where (1,1) is the top-left corner.
  void setCursorPosition(int x, int y) {
    io.stdout.write(ansi_codes.cursorTo(x, y));
  }

  /// Controls cursor blinking state.
  ///
  /// Not supported by all terminals.
  void changeCursorBlinking({required bool blinking}) {
    if (blinking) {
      io.stdout.write(ansi_codes.enableCursorBlink);
    } else {
      io.stdout.write(ansi_codes.disableCursorBlink);
    }
  }

  /// Requests the current cursor position from the terminal.
  ///
  /// The response will be sent as input and must be parsed separately.
  void queryCursorPosition() {
    io.stdout.write(ansi_codes.cursorPositionQuery);
  }

  /// Shows or hides the cursor.
  void changeCursorVisibility({required bool hiding}) {
    if (hiding) {
      io.stdout.write(ansi_codes.hideCursor);
    } else {
      io.stdout.write(ansi_codes.showCursor);
    }
  }

  /// Switches between main and alternate screen buffers.
  ///
  /// The alternate buffer provides a clean screen for full-screen applications,
  /// preserving the main buffer's content.
  void changeScreenMode({required bool alternateBuffer}) {
    if (alternateBuffer) {
      io.stdout.write(ansi_codes.enableAlternativeBuffer);
    } else {
      io.stdout.write(ansi_codes.disableAlternativeBuffer);
    }
  }

  /// Triggers the terminal bell (audio or visual alert).
  void bell() => io.stdout.write(ansi_codes.bell);

  /// Saves the current cursor position.
  ///
  /// Uses DEC private sequence which is widely supported.
  void saveCursorPosition() =>
      io.stdout.write(ansi_codes.saveCursorPositionDEC);

  /// Restores previously saved cursor position.
  ///
  /// Uses DEC private sequence which is widely supported.
  void restoreCursorPosition() =>
      io.stdout.write(ansi_codes.restoreCursorPositionDEC);

  /// Attempts to change terminal window size.
  void changeSize(int width, int height) {
    _termLib
      ..setWindowWidth(width)
      ..setWindowHeight(height);
  }

  /// Changes terminal window title.
  void changeTerminalTitle(String title) =>
      io.stdout.write(ansi_codes.changeTerminalTitle(title));

  /// Enables or disables line wrapping.
  void changeLineWrappingMode({required bool enable}) {
    if (enable) {
      io.stdout.write(ansi_codes.enableLineWrapping);
    } else {
      io.stdout.write(ansi_codes.disableLineWrapping);
    }
  }

  /// Enables or disables mouse event tracking.
  void changeMouseTrackingMode({required bool enable}) {
    if (enable) {
      io.stdout.write(ansi_codes.enableMouseEvents);
    } else {
      io.stdout.write(ansi_codes.disableMouseEvents);
    }
  }

  /// Enables or disables terminal focus events.
  void changeFocusTrackingMode({required bool enable}) {
    if (enable) {
      io.stdout.write(ansi_codes.enableFocusTracking);
    } else {
      io.stdout.write(ansi_codes.disableFocusTracking);
    }
  }

  /// Configures raw input mode for the terminal.
  ///
  /// When enabled, input is processed character by character without buffering
  /// or line editing.
  void setInputMode(bool enableRaw) {
    if (enableRaw) {
      _termLib.enableRawMode();
    } else {
      _termLib.disableRawMode();
    }
  }
}
