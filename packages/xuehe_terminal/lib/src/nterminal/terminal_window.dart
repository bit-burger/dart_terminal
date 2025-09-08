part of "terminal.dart";

/// USE TPUT RMCUP an TPUT SMCUP to restore core after use
class TerminalWindow {
  final input = _TerminalInputImpl();
  final TerminalEscapeCodeWriter bufferedEscapeCodeWriter;
  final LimitedBufferedTerminalWriter bufferedTerminalWriter;
  final TerminalEscapeCodeWriter directEscapeCodeWriter;
  final DirectTerminalWriter directTerminalWriter;

  int get rows => io.stdout.terminalLines;
  int get columns => io.stdout.terminalColumns;
  late final Stream<void> windowSizeChange;

  TerminalWindow({int maxBufferSize = 1024})
      : this._(
          LimitedBufferedTerminalWriter(maxBufferSize: maxBufferSize),
          DirectTerminalWriter(),
        );

  TerminalWindow._(this.bufferedTerminalWriter, this.directTerminalWriter)
      : bufferedEscapeCodeWriter =
            TerminalEscapeCodeWriter(bufferedTerminalWriter),
        directEscapeCodeWriter = TerminalEscapeCodeWriter(directTerminalWriter);
}
