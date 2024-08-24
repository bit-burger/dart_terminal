part "color.dart";
part "text_decoration.dart";

class ForegroundStyle {
  final TextDecorationSet textDecorations;
  final TerminalColor color;

  const ForegroundStyle({
    required this.textDecorations,
    required this.color,
  });

  static const defaultStyle = ForegroundStyle(
    textDecorations: TextDecorationSet.empty(),
    color: DefaultTerminalColor(),
  );
}
