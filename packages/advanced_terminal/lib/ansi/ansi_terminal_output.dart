import '../style.dart';
import '../terminal_output.dart';
import 'ansi_escape_codes.dart' as ansiCodes;

class AnsiTerminalOutput extends TerminalOutput {
  AnsiTerminalOutput({required super.writer});

  bool firstParameter = true;

  void _writeParameter(String s) {
    write(s);
    if (!firstParameter) {
      writeCharCode(59);
    }
    firstParameter = false;
  }

  void _writeCharCodeParameter(int x) {
    writeCharCode(x);
    if (!firstParameter) {
      writeCharCode(59);
    }
    firstParameter = false;
  }

  @override
  void setStyle(
    TerminalForegroundStyle foregroundStyle,
    TerminalColor backgroundColor,
  ) {
    final fromBitfield = foregroundStyle.textDecorations.bitField;
    final toBitfield = this.foregroundStyle.textDecorations.bitField;
    final textDecorationsDiff = fromBitfield != toBitfield;
    final foregroundColorDiff = foregroundStyle.color.comparisonCode !=
        this.foregroundStyle.color.comparisonCode;
    final backgroundColorDiff =
        backgroundColor.comparisonCode != this.backgroundColor.comparisonCode;
    if (!textDecorationsDiff) {
      if (foregroundColorDiff && backgroundColorDiff) {
        writer.write(
          "${ansiCodes.CSI}${foregroundStyle.color.termRepForeground};"
          "${backgroundColor.termRepBackground}m",
        );
        this.foregroundStyle = foregroundStyle;
        this.backgroundColor = backgroundColor;
      } else if (foregroundColorDiff) {
        writer.write(
          "${ansiCodes.CSI}${foregroundStyle.color.termRepForeground}m",
        );
        this.foregroundStyle = foregroundStyle;
      } else if (backgroundColorDiff) {
        writer.write("${ansiCodes.CSI}${backgroundColor.termRepBackground}m");
        this.backgroundColor = backgroundColor;
      }
      return;
    } else if(toBitfield == 0) {
      if (foregroundColorDiff && backgroundColorDiff) {
        writer.write(
          "${ansiCodes.CSI}0;${foregroundStyle.color.termRepForeground};"
              "${backgroundColor.termRepBackground}m",
        );
        this.foregroundStyle = foregroundStyle;
        this.backgroundColor = backgroundColor;
      } else if (foregroundColorDiff) {
        writer.write(
          "${ansiCodes.CSI}0;${foregroundStyle.color.termRepForeground}m",
        );
        this.foregroundStyle = foregroundStyle;
      } else if (backgroundColorDiff) {
        writer.write("${ansiCodes.CSI}0;${backgroundColor.termRepBackground}m");
        this.backgroundColor = backgroundColor;
      } else {
        writer.write("${ansiCodes.CSI}0m");
      }
      return;
    }
    firstParameter = true;
    writer.write(ansiCodes.CSI);
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
    writer.writeCharCode(109);
    super.setStyle(foregroundStyle, backgroundColor);
  }

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

  @override
  void changeSize(int width, int height) {
    writer.write(ansiCodes.changeWindowDimension(width, height));
  }

  @override
  void changeTerminalTitle(String title) {
    writer.write(ansiCodes.changeTerminalTitle(title));
  }
}
