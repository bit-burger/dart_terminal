part of "terminal.dart";

abstract class TerminalWriter {
  void write(String s);

  void writeCharCode(int charCode);

  void flush() {}
}

class DirectTerminalWriter extends TerminalWriter {
  @override
  void write(String s) => io.stdout.write(s);

  @override
  void writeCharCode(int charCode) => io.stdout.writeCharCode(charCode);
}

class LimitedBufferedTerminalWriter extends TerminalWriter {
  final int maxBufferSize;
  final _buffer = StringBuffer();

  LimitedBufferedTerminalWriter({required this.maxBufferSize});

  @override
  void write(String s) {
    if (_buffer.length + s.length > maxBufferSize) {
      flush();
    }
    _buffer.write(s);
  }

  @override
  void writeCharCode(int charCode) {
    if (_buffer.length + 1 == maxBufferSize) {
      flush();
    }
    _buffer.writeCharCode(charCode);
  }

  @override
  void flush() {
    io.stdout.write(_buffer);
    _buffer.clear();
  }
}

class BufferedTerminalWriter extends TerminalWriter {
  final _buffer = StringBuffer();

  @override
  void write(String s) => _buffer.write(s);

  @override
  void writeCharCode(int charCode) => _buffer.writeCharCode(charCode);

  @override
  void flush() {
    io.stdout.write(_buffer);
    _buffer.clear();
  }
}
