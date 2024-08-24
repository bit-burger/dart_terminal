part of 'terminal.dart';

abstract class TerminalEvent {}

class EofEvent extends TerminalEvent {}

class SigIntEvent extends TerminalEvent {}

class TerminalResizeEvent extends TerminalEvent {
  final int rows, columns;

  TerminalResizeEvent(this.rows, this.columns);
}

class TerminalScrollEvent extends TerminalEvent {}

class TerminalCursorEvent extends TerminalEvent {}

class TerminalTextEvent extends TerminalEvent {
  final String text;

  TerminalTextEvent(this.text);
}

enum ArrowType {
  up(-1, 0),
  down(1, 0),
  left(0, -1),
  right(0, 1);

  final int dx, dy;

  const ArrowType(this.dx, this.dy);
}

class ArrowEvent extends TerminalEvent {
  final ArrowType arrow;

  ArrowEvent(this.arrow);
}

class Backspace extends TerminalEvent {}

abstract class EventListener {}

int get _tLines => io.stdout.terminalLines;
int get _tCols => io.stdout.terminalColumns;

Stream<TerminalEvent> getUnixTerminalEventsStream() => StreamGroup.merge([
      io.ProcessSignal.sigint.watch().map((event) => SigIntEvent()),
      io.ProcessSignal.sigwinch.watch().map((event) => TerminalResizeEvent(
            _tLines,
            _tCols,
          )),
      io.stdin.map(mapStdinToEvent).where((event) => event != null).cast(),
    ]);

TerminalEvent? mapStdinToEvent(List<int> input) {
  input = [...input];
  if (input.first == 4) {
    return EofEvent();
  }
  if (input.first == 127) {
    return Backspace();
  }
  if (input.first == 27) {
    if (input.length < 3) return null;
    input = input.sublist(2); // remove \e[
    final name = input.removeLast();
    // if (input.first == 60) {}
    // TODO: mouse events
    switch (name) {
      case 65:
        return ArrowEvent(ArrowType.up);
      case 66:
        return ArrowEvent(ArrowType.down);
      case 68:
        return ArrowEvent(ArrowType.left);
      case 67:
        return ArrowEvent(ArrowType.right);
    }
  }
  return TerminalTextEvent(String.fromCharCodes(input));
}

Stream<TerminalEvent> getWindowsTerminalEventsStream({
  Duration terminalSizePollRate = const Duration(seconds: 1),
}) =>
    StreamGroup.merge([
      getUnixTerminalEventsStream(),
      periodicWindowSizeUpdates(terminalSizePollRate)
    ]);

Stream<TerminalEvent> periodicWindowSizeUpdates(Duration timeBetween) {
  var lines = _tLines, cols = _tCols;
  late final StreamController<TerminalEvent> controller;
  final timer = Timer.periodic(timeBetween, (_) {
    var newLines = _tLines,
        newCols = _tCols;
    if (newLines != lines || newCols != cols) {
      lines = newLines;
      cols = newCols;
      controller.add(TerminalResizeEvent(lines, cols));
    }
  });
  controller = StreamController(onCancel: timer.cancel);
  return controller.stream;
}
