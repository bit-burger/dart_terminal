import '../terminal_output.dart';
import 'ansi_escape_codes.dart' as ansiCodes;

class AnsiTerminalOutput extends TerminalOutput {
  AnsiTerminalOutput({required super.writer});

  @override
  void setCursorPosition(int x, int y) {
    writer.write(ansiCodes.cursorTo(x, y));
  }

  @override
  void changeCursorVisibility({required bool hiding}) {
    if (hiding) {
      writer.write(ansiCodes.hideCursor);
    } else {
      writer.write(ansiCodes.showCursor);
    }
  }

  @override
  void changeScreenMode({required bool hidden}) {
    if (hidden) {
      writer.write(ansiCodes.enableAlternativeBuffer);
    } else {
      writer.write(ansiCodes.disableAlternativeBuffer);
    }
  }

  @override
  void bell() => writer.write(ansiCodes.bell);

  @override
  void saveCursorPosition() => writer.write(ansiCodes.saveCursorPositionDEC);

  @override
  void restoreCursorPosition() =>
      writer.write(ansiCodes.restoreCursorPositionDEC);
}
