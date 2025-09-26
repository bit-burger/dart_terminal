part of 'ansi_terminal_service.dart';

class _AnsiTerminalLogger extends TerminalLogger {
  final AnsiTerminalService _service;

  _AnsiTerminalLogger._(this._service);

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
  int get width => _service._sizeTracker.currentSize.width;
}
