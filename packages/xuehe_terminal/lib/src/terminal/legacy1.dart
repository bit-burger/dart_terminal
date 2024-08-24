
abstract class _TerminalWindow {
  int get rows;
  int get columns;

  /// A broadcast stream of when the window size changes
  Stream<void> get windowSizeChange;
  void escBegin({required String type, required String capability});
  void escCSIBegin({required String capability});
  void escParam(String s);
  void escEnd();
  void write(String s);
  void writeCharCode(int c);
  void clearScreen();
  void flush();

  static final TerminalWindow simple = _BasicTerminalEscapeCodeWriter(
    stdout,
    stdin,
  );

  static final TerminalWindow buffered = _BufferedTerminalEscapeCodeWriter(
    stdout,
    stdin,
    StringBuffer(),
  );
}

class _BufferedTerminalEscapeCodeWriter extends TerminalWindow {
  @override
  late final Stream<void> windowSizeChange;

  late String _capability;
  late bool _atLeastOneParam;
  final Stdout _stdout;
  final Stdin _stdin;
  final StringBuffer _stringBuffer;

  _BufferedTerminalEscapeCodeWriter(this._stdout, this._stdin, this._stringBuffer) {
    windowSizeChange = ProcessSignal.sigwinch.watch();
  }

  @override
  int get rows => _stdout.terminalLines;

  @override
  int get columns => _stdout.terminalColumns;

  @override
  void escBegin({String type = "[", required String capability}) {
    _stringBuffer.write(ESC);
    _stringBuffer.write(type);
    _capability = capability;
    _atLeastOneParam = false;
  }

  @override
  void escCSIBegin({required String capability}) {
    _stringBuffer.write(CSI);
    _capability = capability;
    _atLeastOneParam = false;
  }

  @override
  void escParam(String s) {
    if (_atLeastOneParam) {
      _stringBuffer.write(";");
      _stringBuffer.write(s);
    } else {
      _stringBuffer.write(s);
      _atLeastOneParam = true;
    }
  }

  @override
  void escEnd() {
    _stringBuffer.write(_capability);
  }

  @override
  void write(String code) {
    _stringBuffer.write(code);
  }

  @override
  void writeCharCode(int c) {
    if (c == 0) {
      _stringBuffer.write(" ");
    }
    _stringBuffer.writeCharCode(c);
  }

  @override
  void clearScreen() {
    _stringBuffer.write(ansiEscapes.clearTerminal);
  }

  @override
  void flush() {
    _stdout.write(_stringBuffer);
    _stringBuffer.clear();
  }
}


class _BasicTerminalEscapeCodeWriter extends TerminalWindow {
  @override
  late final Stream<void> windowSizeChange;

  late String _capability;
  late bool _atLeastOneParam;
  late final Stdout _stdout;
  late final Stdin _stdin;

  _BasicTerminalEscapeCodeWriter(this._stdout, this._stdin) {
    windowSizeChange = ProcessSignal.sigwinch.watch();
  }

  @override
  int get rows => _stdout.terminalLines;

  @override
  int get columns => _stdout.terminalColumns;

  @override
  void escBegin({String type = "[", required String capability}) {
    stdout.write(ESC);
    stdout.write(type);
    _capability = capability;
    _atLeastOneParam = false;
  }

  @override
  void escCSIBegin({required String capability}) {
    stdout.write(CSI);
    _capability = capability;
    _atLeastOneParam = false;
  }

  @override
  void escParam(String s) {
    if (_atLeastOneParam) {
      stdout.write(";");
      stdout.write(s);
    } else {
      stdout.write(s);
      _atLeastOneParam = true;
    }
  }

  @override
  void escEnd() {
    stdout.write(_capability);
  }

  @override
  void write(String code) {
    stdout.write(code);
  }

  @override
  void writeCharCode(int c) {
    if (c == 0) {
      stdout.write(" ");
    }
    stdout.writeCharCode(c);
  }

  @override
  void clearScreen() {
    stdout.write(ansiEscapes.clearTerminal);
  }

  @override
  void flush() {}
}
