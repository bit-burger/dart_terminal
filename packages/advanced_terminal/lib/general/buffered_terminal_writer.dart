import '../terminal_writer.dart';
import 'dart:io' as io;

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