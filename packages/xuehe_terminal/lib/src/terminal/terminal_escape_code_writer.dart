part of "terminal.dart";

class TerminalEscapeCodeWriter {
  final TerminalWriter terminalWriter;
  late String _capability;
  late bool _atLeastOneParam;

  TerminalEscapeCodeWriter(this.terminalWriter);

  void bell() {
    terminalWriter.write(codes.BEL);
  }

  void escBegin({String type = "[", required String capability}) {
    terminalWriter.write(codes.ESC);
    terminalWriter.write(type);
    _capability = capability;
    _atLeastOneParam = false;
  }

  void escCSIBegin({required String capability}) {
    terminalWriter.write(codes.CSI);
    _capability = capability;
    _atLeastOneParam = false;
  }

  void escParam(String s) {
    if (_atLeastOneParam) {
      terminalWriter
        ..write(";")
        ..write(s);
    } else {
      terminalWriter.write(s);
      _atLeastOneParam = true;
    }
  }

  void escEnd() {
    terminalWriter.write(_capability);
  }

  void clearScreen() {
    terminalWriter.write(codes.clearScreen);
  }

  void clearTerminal() {
    terminalWriter.write(codes.clearTerminal);
  }

  void showCursor() {
    terminalWriter.write(codes.cursorShow);
  }

  void hideCursor() {
    terminalWriter.write(codes.cursorHide);
  }

  void moveCursor(int x, [int y = -1]) {
    terminalWriter
      ..write(codes.CSI)
      ..write(x.toString());
    if (y == -1) {
      terminalWriter.write("G");
    } else {
      terminalWriter
        ..write(";")
        ..write(y.toString())
        ..write("H");
    }
  }

  void flush() {
    terminalWriter.flush();
  }
}
