part of 'terminal.dart';

abstract class TerminalAction {
  final String name;

  TerminalAction({required this.name});

  @override
  String toString() {
    return name;
  }

  static void notSupported(TerminalAction action, TerminalActionSupplier supplier) {
    throw Exception('Supplier "$supplier" does not support core action "$action"');
  }
}

abstract class TerminalActionSupplier {
  final String name;

  TerminalActionSupplier({required this.name});

  bool tryToExecuteAction(TerminalAction action, TerminalEscapeCodeWriter writer);

  @override
  String toString() {
    return name;
  }
}