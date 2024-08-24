import '../terminal_writer.dart';
import 'dart:io' as io;

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