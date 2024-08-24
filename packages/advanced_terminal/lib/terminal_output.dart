import './terminal_writer.dart';

import 'style.dart';
import 'package:meta/meta.dart';


abstract class TerminalOutput {
  @protected
  final TerminalWriter writer;
  TerminalForegroundStyle foregroundStyle = TerminalForegroundStyle.defaultStyle;
  TerminalColor backgroundColor = DefaultTerminalColor();

  TerminalOutput({required this.writer});

  void changeScreenMode({required bool hidden});

  void changeCursorVisibility({required bool hiding});

  void writeCharCode(int x) {
    writer.writeCharCode(x);
  }

  void write(String s) {
    writer.write(s);
  }

  void flush() {
    writer.flush();
  }

  void saveCursorPosition();
  void restoreCursorPosition();
  void setCursorPosition(int x, int y);
  void bell();
  void setStyle(TerminalForegroundStyle foregroundStyle, TerminalColor backgroundColor) {
    this.foregroundStyle = foregroundStyle;
    this.backgroundColor = backgroundColor;
  }
}
