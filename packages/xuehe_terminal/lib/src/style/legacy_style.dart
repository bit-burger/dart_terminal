import '../terminal/terminal.dart';

part 'color.dart';
part 'text_decoration.dart';

class TerminalForegroundStyle {
  final TerminalColor terminalColor;
  final TextDecorationSet textDecorations;

  const TerminalForegroundStyle({
    required this.terminalColor,
    required this.textDecorations,
  });

  static const defaultStyle = TerminalForegroundStyle(
    terminalColor: DefaultTerminalColor(),
    textDecorations: TextDecorationSet.empty(),
  );

  static void forceWriteSGRChangeParameters(
    TerminalForegroundStyle from,
    TerminalForegroundStyle to,
    TerminalEscapeCodeWriter escapeCodeWriter,
  ) {
    escapeCodeWriter.escCSIBegin(capability: "m");
    if (from.terminalColor._comparisonCode !=
        to.terminalColor._comparisonCode) {
      escapeCodeWriter.escParam(to.terminalColor._termRepForeground);
    }
    TextDecorationSet.transitionSGRCode(
      from.textDecorations,
      to.textDecorations,
      escapeCodeWriter,
    );
    escapeCodeWriter.escEnd();
  }
}

class TerminalStyle {
  final TerminalColor? backgroundColor, foregroundColor;
  final TextDecorationSet? foregroundTextDecorations;

  const TerminalStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.foregroundTextDecorations,
  });

  static const defaultStyle = TerminalStyle();

  static void forceWriteSGRChangeParameters(
    TerminalStyle from,
    TerminalStyle to,
    TerminalEscapeCodeWriter escapeCodeWriter,
  ) {
    escapeCodeWriter.escCSIBegin(capability: "m");
    if (from.backgroundColor._comparisonCode !=
        to.backgroundColor._comparisonCode) {
      escapeCodeWriter.escParam(to.backgroundColor._termRepBackground);
    }
    if (from.foregroundColor._comparisonCode !=
        to.foregroundColor._comparisonCode) {
      escapeCodeWriter.escParam(to.backgroundColor._termRepBackground);
    }
    TextDecorationSet.transitionSGRCode(
      from.foregroundTextDecorations,
      to.foregroundTextDecorations,
      escapeCodeWriter,
    );
    escapeCodeWriter.escEnd();
  }
}
