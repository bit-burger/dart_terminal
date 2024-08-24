/// based on https://notes.burke.libbey.me/ansi-escape-codes/ and
/// https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
abstract class TerminalColor {
  /// representation in RGB, default terminal color is -1
  final int rgbRep;
  final String termRepBackground;
  final String termRepForeground;

  /// To uniquely identify a color.
  ///
  /// [DefaultTerminalColor] gets 0
  /// [BasicTerminalColor] gets [1;9]
  /// [BrightTerminalColor] gets [10;19]
  /// [XTermTerminalColor] gets [20;999]
  /// [RGBTerminalColor] gets [1000;19,999,999]
  ///
  /// Custom implementations should avoid the ranges of
  /// the library classes, by starting at 20,000,000,
  /// or under 0.
  final int _comparisonCode;

  const TerminalColor({
    required int comparisonCode,
    required this.rgbRep,
    required this.termRepForeground,
    required this.termRepBackground,
  })  : _comparisonCode = comparisonCode,
        assert(comparisonCode < 0 || comparisonCode > 20000000);

  const TerminalColor._(
    this.rgbRep,
    this.termRepForeground,
    this.termRepBackground,
    this._comparisonCode,
  );

  @override
  bool operator ==(Object other) =>
      other is TerminalColor && _comparisonCode == other._comparisonCode;

  @override
  int get hashCode => _comparisonCode;
}

/// A decoration of the foreground,
/// not all are supported by all terminals.
enum TextDecoration {
  /// bold or increased intensity, turns off [faint]
  intense(1, 22, 0),

  /// light font weight or decreased intensity, turns off [intense]
  faint(2, 22, 1),

  italic(3, 23, 2),

  /// turns off [doubleUnderline]
  underline(4, 24, 3),

  /// turns off underline, on some terminals will not work,
  /// and will instead disable bold intensity.
  doubleUnderline(21, 24, 4),

  /// turns off [fastBlink]
  slowBlink(5, 25, 5),

  /// turns off [slowBlink]
  fastBlink(6, 25, 6),

  /// not supported in Terminal.app
  crossedOut(9, 29, 7);

  /// SGR code for turning decoration on and off in the terminal.
  final String onCode, offCode;
  final int bitFlag;

  const TextDecoration(int onCode, int offCode, int decorationNumber)
      : assert(decorationNumber < 64),
        onCode = "$onCode",
        offCode = "$offCode",
        bitFlag = 1 << decorationNumber;

  static const highestBitFlag = 7;
}

/// Represents multiple TextDecorations at one time.
class TextDecorationSet {
  final int bitField;

  const TextDecorationSet.all() : bitField = ~0;

  TextDecorationSet.from(Iterable<TextDecoration> textDecorations)
      : bitField = textDecorations.fold(
            0, (previousValue, element) => previousValue & element.bitFlag);

  TextDecorationSet.union(TextDecorationSet a, TextDecorationSet b)
      : bitField = a.bitField & b.bitField;

  TextDecorationSet.without(TextDecorationSet a, TextDecorationSet b)
      : bitField = a.bitField & ~b.bitField;

  const TextDecorationSet({
    bool intense = false,
    bool faint = false,
    bool italic = false,
    bool underline = false,
    bool doubleUnderline = false,
    bool slowBlink = false,
    bool fastBlink = false,
    bool crossedOut = false,
  }) : bitField = ((intense ? 1 : 0) << 0) &
            ((faint ? 1 : 0) << 1) &
            ((italic ? 1 : 0) << 2) &
            ((underline ? 1 : 0) << 3) &
            ((doubleUnderline ? 1 : 0) << 4) &
            ((slowBlink ? 1 : 0) << 5) &
            ((fastBlink ? 1 : 0) << 6) &
            ((crossedOut ? 1 : 0) << 7);

  const TextDecorationSet._decorationNumber(int decorationNumber)
      : bitField = 1 << decorationNumber;

  const TextDecorationSet.empty() : bitField = 0;

  /// sets containing one [TextDecoration]
  /// corresponding to all possible [TextDecoration]s
  static const intense = TextDecorationSet._decorationNumber(0);
  static const faint = TextDecorationSet._decorationNumber(1);
  static const italic = TextDecorationSet._decorationNumber(2);
  static const underline = TextDecorationSet._decorationNumber(3);
  static const doubleUnderline = TextDecorationSet._decorationNumber(4);
  static const slowBlink = TextDecorationSet._decorationNumber(5);
  static const fastBlink = TextDecorationSet._decorationNumber(6);
  static const crossedOut = TextDecorationSet._decorationNumber(7);

  bool contains(TextDecoration decoration) =>
      decoration.bitFlag & bitField != 0;

  @override
  int get hashCode => bitField;

  @override
  bool operator ==(Object other) =>
      other is TextDecorationSet && bitField == other.bitField;
}

class TerminalForegroundStyle {
  final TextDecorationSet textDecorations;
  final TerminalColor color;

  const TerminalForegroundStyle({
    required this.textDecorations,
    required this.color,
  });

  static const defaultStyle = TerminalForegroundStyle(
    textDecorations: TextDecorationSet.empty(),
    color: DefaultTerminalColor(),
  );

  @override
  bool operator ==(Object other) =>
      other is TerminalForegroundStyle &&
      color._comparisonCode == other.color._comparisonCode &&
      textDecorations.bitField == other.textDecorations.bitField;

  @override
  int get hashCode => color._comparisonCode << 8 + textDecorations.bitField;
}

/// Default terminal color.
class DefaultTerminalColor extends TerminalColor {
  const DefaultTerminalColor() : super._(-1, "39", "49", 0);
}

abstract class _BaseIntTerminalColor extends TerminalColor {
  final int color;

  const _BaseIntTerminalColor(
      String termRepForeground, String termRepBackground,
      {required this.color, required int rgb, required int comparisonCodeStart})
      : super._(
          rgb,
          termRepBackground,
          termRepBackground,
          color + comparisonCodeStart,
        );
}

/// The 8 basic colors.
class BasicTerminalColor extends _BaseIntTerminalColor {
  /// The colors from 0 to 7;
  const BasicTerminalColor({required super.color, required super.rgb})
      : assert(color >= 0 && color < 8),
        super("${30 + color}", "${40 + color}", comparisonCodeStart: 1);

  static const black = BasicTerminalColor(color: 0, rgb: 0);
  static const red = BasicTerminalColor(color: 1, rgb: 0x00FF0000);
  static const green = BasicTerminalColor(color: 2, rgb: 0x0000FF00);
  static const yellow = BasicTerminalColor(color: 3, rgb: 0x00FFFF00);
  static const blue = BasicTerminalColor(color: 4, rgb: 0x000000FF);
  static const magenta = BasicTerminalColor(color: 5, rgb: 0x00FF00FF);
  static const cyan = BasicTerminalColor(color: 6, rgb: 0x0000FFFF);
  static const white = BasicTerminalColor(color: 7, rgb: 0x00FFFFFFFF);
}

/// The 8 bright colors.
class BrightTerminalColor extends _BaseIntTerminalColor {
  /// The colors from 0 to 7;
  const BrightTerminalColor({required super.color, required super.rgb})
      : assert(color >= 0 && color < 8),
        super("${90 + color}", "${100 + color}", comparisonCodeStart: 10);

  String termRep({required bool background}) {
    if (!background) {
      return (90 + color).toString();
    } else {
      return (100 + color).toString();
    }
  }

  static const black = BasicTerminalColor(color: 0, rgb: 0x00050505);
  static const red = BasicTerminalColor(color: 1, rgb: 0x00FF0505);
  static const green = BasicTerminalColor(color: 2, rgb: 0x0005FF05);
  static const yellow = BasicTerminalColor(color: 3, rgb: 0x00FFFF05);
  static const blue = BasicTerminalColor(color: 4, rgb: 0x000505FF);
  static const magenta = BasicTerminalColor(color: 5, rgb: 0x00FF05FF);
  static const cyan = BasicTerminalColor(color: 6, rgb: 0x0005FFFF);
  static const white = BasicTerminalColor(color: 7, rgb: 0x00FFFFFFFF);
}

/// The 256 colors supported by xterm.
/// For all 256 see: {@image <image alt='' src='/docs/xterm_256_colors.png'>}
class XTermTerminalColor extends _BaseIntTerminalColor {
  /// The colors from 0 to 255;
  const XTermTerminalColor({required super.color, super.rgb = 0x00FFFFFF})
      : assert(color >= 0 && color < 256),
        super(
          "38;5;$color",
          "48;5;$color",
          comparisonCodeStart: 20,
        );
}

/// 256^3 colors, not supported by every terminal.
class RGBTerminalColor extends _BaseIntTerminalColor {
  /// The colors from 0 to 256^3 - 1;
  const RGBTerminalColor.raw({required int color})
      : this._(
          color ~/ 256 ~/ 256,
          (color % (256 * 256)) ~/ 256,
          color % 256,
          color,
        );

  /// The colors separated, each can be assigned 0 to 255.
  const RGBTerminalColor({int red = 0, int green = 0, int blue = 0})
      : this._(red, green, blue, red * 256 * 256 + green * 256 + blue);

  const RGBTerminalColor._(int red, int green, int blue, int color)
      : assert(red >= 0 && red < 256),
        assert(green >= 0 && green < 256),
        assert(blue >= 0 && blue < 256),
        super(
          "38;2;$red;$green;$blue",
          "48;2;$red;$green;$blue",
          rgb: red * 256 * 256 + green * 256 + green,
          color: color,
          comparisonCodeStart: 1000,
        );
}
