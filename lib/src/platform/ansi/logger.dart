// Project imports:
import 'package:dart_terminal/core.dart';
import '../shared/size_tracker.dart';

class AnsiTerminalLogger extends TerminalLogger {
  final TerminalSizeTracker _sizeTracker;

  AnsiTerminalLogger(this._sizeTracker);

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
  int get width => _sizeTracker.currentSize.width;
}
