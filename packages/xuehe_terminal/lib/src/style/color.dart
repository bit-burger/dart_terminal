part of "style.dart";

/// based on https://notes.burke.libbey.me/ansi-escape-codes/ and
/// https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
abstract class TerminalColor {
  /// representation in RGB, default core color is -1
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

/// Default core color.
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

/// 256^3 colors, not supported by every core.
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
          rgb: red*256*256 + green * 256 + green,
          color: color,
          comparisonCodeStart: 1000,
        );
}
