import 'dart:io' as io;
import '../terminal_writer.dart';

class UnbufferedTerminalWriter extends TerminalWriter {
  @override
  void flush() {}

  @override
  void write(String s) {
    io.stdout.write(s);
  }

  @override
  void writeCharCode(int x) {
    io.stdout.writeCharCode(x);
  }
}