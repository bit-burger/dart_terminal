import './terminal_writer.dart';

import 'style.dart';
import 'package:meta/meta.dart';


abstract class TerminalOutput {
  @protected
  final TerminalWriter writer;
  @protected
  TerminalForegroundStyle foregroundStyle = TerminalForegroundStyle.defaultStyle;
  @protected
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
  void changeSize(int width, int height);
  void changeTerminalTitle(String title);
  void setCursorPosition(int x, int y);
  void bell();
  void setStyle(TerminalForegroundStyle foregroundStyle, TerminalColor backgroundColor) {
    this.foregroundStyle = foregroundStyle;
    this.backgroundColor = backgroundColor;
  }
}
