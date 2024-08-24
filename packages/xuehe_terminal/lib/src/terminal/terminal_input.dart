part of "terminal.dart";

abstract class TerminalInput {
  Stream<InputKey> get input;

  Stream<Point<int>> get mouseClick;


}

class _TerminalInputImpl extends TerminalInput {
  _TerminalInputImpl() {
    io.stdin.echoMode = false;
    io.stdin.lineMode = false;
  }
  final inputController = StreamController<InputKey>.broadcast();
  @override
  Stream<InputKey> get input => inputController.stream;

  final mouseClickController = StreamController<Point<int>>.broadcast();
  @override
  Stream<Point<int>> get mouseClick => mouseClickController.stream;
}

class InputKey {

}