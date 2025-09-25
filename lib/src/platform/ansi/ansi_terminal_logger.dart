part of 'ansi_terminal_service.dart';

class _AnsiTerminalLogger extends TerminalLogger {
  @override
  final AnsiTerminalService service;

  _AnsiTerminalLogger._(this.service);

  @override
  void deleteLastLine(int count) {
    // TODO: implement deleteLastLine
  }

  @override
  void log(
    String text, {
    ForegroundStyle foregroundStyle = const ForegroundStyle(),
    Color backgroundColor = const Color.normal(),
  }) {
    // TODO: implement log
  }

  @override
  int get width => service._sizeTracker.currentSize.width;
}
