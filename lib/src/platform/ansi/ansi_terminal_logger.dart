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
    TerminalForegroundStyle foregroundStyle = const TerminalForegroundStyle(),
    TerminalColor backgroundColor = const DefaultTerminalColor(),
  }) {
    // TODO: implement log
  }

  @override
  int get width => service._sizeTracker.currentSize.width;
}
