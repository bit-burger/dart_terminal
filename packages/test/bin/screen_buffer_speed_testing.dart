import 'dart:io';
import 'dart:math';

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
          rgb: red * 256 * 256 + green * 256 + green,
          color: color,
          comparisonCodeStart: 1000,
        );
}

// A decoration of the foreground,
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

  /// SGR code for turning decoration on and off in the core.
  final String onCode, offCode;
  final int bitFlag;

  const TextDecoration(int onCode, int offCode, int decorationNumber)
      : assert(decorationNumber < 64),
        onCode = "$onCode",
        offCode = "$offCode",
        bitFlag = 1 << decorationNumber;

  static const highestBitFlag = 7;
}

class TextDecorationSetBuilder {
  int _bitField = 0;

  void add(TextDecoration decoration) =>
      _bitField = _bitField | decoration.bitFlag;

  void addAll(Iterable<TextDecoration> decorations) {
    for (final decoration in decorations) {
      add(decoration);
    }
  }

  void removeAll(Iterable<TextDecoration> decorations) {
    for (final decoration in decorations) {
      remove(decoration);
    }
  }

  void remove(TextDecoration decoration) =>
      _bitField = _bitField & ~decoration.bitFlag;

  TextDecorationSet build() => TextDecorationSet._raw(_bitField);
}

/// Represents multiple TextDecorations at one time.
class TextDecorationSet {
  final int bitField;

  TextDecorationSet._raw(this.bitField);

  TextDecorationSet._decorationNumber(int decorationNumber)
      : this._raw(1 << decorationNumber);

  const TextDecorationSet.empty() : bitField = 0;

  factory TextDecorationSet(Iterable<TextDecoration> decorations) =>
      (TextDecorationSetBuilder()..addAll(decorations)).build();

  static TextDecorationSetBuilder getBuilder() {
    return TextDecorationSetBuilder();
  }

  /// sets containing one [TextDecoration]
  /// corresponding to all possible [TextDecoration]s
  static final intense = TextDecorationSet._decorationNumber(0);
  static final faint = TextDecorationSet._decorationNumber(1);
  static final italic = TextDecorationSet._decorationNumber(2);
  static final underline = TextDecorationSet._decorationNumber(3);
  static final doubleUnderline = TextDecorationSet._decorationNumber(4);
  static final slowBlink = TextDecorationSet._decorationNumber(5);
  static final fastBlink = TextDecorationSet._decorationNumber(6);
  static final crossedOut = TextDecorationSet._decorationNumber(7);

  bool contains(TextDecoration decoration) =>
      decoration.bitFlag & bitField != 0;

  // static void transitionSGRCode(
  //   TextDecorationSet from,
  //   TextDecorationSet to,
  //   TerminalEscapeCodeWriter escapeCodeWriter,
  // ) {
  //   if (from._bitField != to._bitField) {
  //     final changedBitMask = ~(from._bitField & to._bitField);
  //     final removedBitField = from._bitField & changedBitMask;
  //     _applyBitFieldToSGR(removedBitField, false, escapeCodeWriter);
  //     final addedBitField = to._bitField & changedBitMask;
  //     _applyBitFieldToSGR(addedBitField, true, escapeCodeWriter);
  //   }
  // }
  //
  // static void _applyBitFieldToSGR(
  //   int bitField,
  //   bool addDecorations,
  //   TerminalEscapeCodeWriter escapeCodeWriter,
  // ) {
  //   if (bitField != 0) {
  //     for (var i = 0; i <= TextDecoration.highestBitFlag; i++) {
  //       final decorationBitFlag = 1 << i;
  //       if (decorationBitFlag & bitField != 0) {
  //         final decoration = TextDecoration.values[i];
  //         if (addDecorations) {
  //           escapeCodeWriter.escParam(decoration.onCode);
  //         } else {
  //           escapeCodeWriter.escParam(decoration.offCode);
  //         }
  //       }
  //     }
  //   }
  // }

  @override
  int get hashCode => bitField;

  @override
  bool operator ==(Object other) =>
      other is TextDecorationSet && bitField == other.bitField;
}

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

class PaintToken {
  int height = 23;
}

class _Pixel {
  int charCode = 10;
  bool changed = false;
  int backgroundHeight = 0;
  int foregroundHeight = 0;
  PaintToken? btoken;
  PaintToken? ftoken;
  bool token = false;

  TerminalColor backgroundColor = const DefaultTerminalColor();

  ForegroundStyle foregroundStyle = ForegroundStyle(
    textDecorations: TextDecorationSet.empty(),
    color: const DefaultTerminalColor(),
  );
}

class ScreenBuffer {
  int _width, _height;
  int _bufferWidth, _bufferHeight;

  final List<List<_Pixel>> _data;

  ScreenBuffer(int width, int height)
      : _width = width,
        _height = height,
        _bufferWidth = width,
        _bufferHeight = height,
        _data = List.generate(
          height,
          (_) => List.generate(
            width,
            (_) => _Pixel(),
          ),
        ) {
    var token;
    token = _data[0][0].btoken = PaintToken();
    _data[0][0].token = true;
    token.height = 0;
    token = _data[0][1].btoken = PaintToken();
    _data[0][0].token = true;
    token.height = 233;

    token = _data[0][0].btoken = PaintToken();
    _data[0][0].token = true;
    token.height = 0;
    token = _data[0][1].btoken = PaintToken();
    _data[0][0].token = true;
    token.height = 233;
  }

  setPaintTokens() {
    final token = _data[0][0].btoken = PaintToken();
    token.height = 0;
    for (var i = 0; i < _width; i++) {
      for (var j = 0; j < _height; j++) {
        _data[j][i].btoken = token;
      }
    }
    final ftoken = _data[0][0].btoken = PaintToken();
    token.height = 2;
    for (var i = 0; i < _width; i++) {
      for (var j = 0; j < _height; j++) {
        _data[j][i].ftoken = token;
      }
    }
  }

  repaintsimple() {
    final bcolor = RGBTerminalColor(red: 100);
    final fstyle = ForegroundStyle(
      textDecorations: TextDecorationSet.empty(),
      color: RGBTerminalColor(red: 255),
    );
    final box = Rectangle<int>(100, 100, 100, 100);
    for (var i = 0; i < _width; i++) {
      for (var j = 0; j < _height; j++) {
        final dat = _data[j][i];
        dat.charCode = 50;
        dat.backgroundColor = bcolor;
        dat.foregroundStyle = fstyle;
      }
    }
  }

  repaint() {
    final bcolor = RGBTerminalColor(red: 100);
    final fstyle = ForegroundStyle(
      textDecorations: TextDecorationSet.empty(),
      color: RGBTerminalColor(red: 255),
    );
    final box = Rectangle<int>(100, 100, 100, 100);
    for (var i = 0; i < _width; i++) {
      for (var j = 0; j < _height; j++) {
        if (i > box.left &&
            i < box.left + box.width &&
            j > box.top &&
            j < box.top + box.height) {
          continue;
        }
        final dat = _data[j][i];
        dat.charCode = 50;
        dat.backgroundColor = bcolor;
        dat.foregroundStyle = fstyle;
      }
    }
  }

  repaintcool() {
    final bcolor = RGBTerminalColor(red: 100);
    final fstyle = ForegroundStyle(
      textDecorations: TextDecorationSet.empty(),
      color: RGBTerminalColor(red: 255),
    );
    final box = Rectangle<int>(100, 100, 100, 100);
    final ox = box.left + box.width;
    final oy = box.top + box.height;
    for (int j = 0; j < _height; j++) {
      final y = _data[j];
      for (int i = 0; i < _width; i++) {
        if (i <= box.left || i >= ox || j >= box.top || j <= oy) {
          final dat = y[i];
          dat.charCode = 50;
          dat.backgroundColor = bcolor;
          dat.foregroundStyle = fstyle;
        }
      }
    }
  }

  repaintwithtokencheckcool() {
    final bcolor = RGBTerminalColor(red: 100);
    final fstyle = ForegroundStyle(
      textDecorations: TextDecorationSet.empty(),
      color: RGBTerminalColor(red: 255),
    );
    final box = Rectangle<int>(100, 100, 100, 100);
    final ox = box.left + box.width;
    final oy = box.top + box.height;
    for (int j = 0; j < _height; j++) {
      final y = _data[j];
      for (int i = 0; i < _width; i++) {
        if (i <= box.left || i >= ox || j >= box.top || j <= oy) {
          final dat = y[i];
          if (!dat.token || ((dat.btoken?.height ?? 0) <= 10 && (dat.btoken?.height ?? 0) <= 10)) {
            dat.charCode = 50;
            dat.backgroundColor = bcolor;
            dat.foregroundStyle = fstyle;
          }
        }
      }
    }
  }

  repaintwithtokencheck() {
    final bcolor = RGBTerminalColor(red: 100);
    final fstyle = ForegroundStyle(
      textDecorations: TextDecorationSet.empty(),
      color: RGBTerminalColor(red: 255),
    );
    final box = Rectangle<int>(100, 100, 100, 100);
    for (int i = 0; i < _width; i++) {
      for (int j = 0; j < _height; j++) {
        if (i > box.left &&
            i < box.left + box.width &&
            j > box.top &&
            j < box.top + box.height) {
          continue;
        }
        final dat = _data[j][i];
        if (!dat.token || ((dat.btoken?.height ?? 0) <= 10 && (dat.btoken?.height ?? 0) <= 10)) {
          dat.charCode = 50;
          dat.backgroundColor = bcolor;
          dat.foregroundStyle = fstyle;
        }
      }
    }
  }
}

main() {
  final buff = ScreenBuffer(1000, 1000);
  for (var i = 0; i < 100; i++) {
    buff.repaintwithtokencheck();
  }
  var s;
  //print("repaintsimple:");
  //var s = Stopwatch()..start();
  //for (var i = 0; i < 500; i++) {
  //  buff.repaintsimple();
 // }
 // print((s..stop()).elapsedMilliseconds);
 // print("repaint:");
 // s = Stopwatch()..start();
 // for (var i = 0; i < 500; i++) {
 //   buff.repaint();
 // }
 // print((s..stop()).elapsedMilliseconds);
 // print("repainttoken(without):");
 // s = Stopwatch()..start();
 // for (var i = 0; i < 500; i++) {
 //   buff.repaintwithtokencheck();
 // }
 // print((s..stop()).elapsedMilliseconds);
 // buff.setPaintTokens();
 // print("repainttoken(with):");
 // s = Stopwatch()..start();
 // for (var i = 0; i < 500; i++) {
 //   buff.repaintwithtokencheck();
 // }
 // print((s..stop()).elapsedMilliseconds);
  print("repaintcool:");

  s = Stopwatch()..start();
  for (int i = 0; i < 500; i++) {
    buff.repaintcool();
  }
  print((s..stop()).elapsedMilliseconds);
  print("repaintcool:");

  s = Stopwatch()..start();
  for (var i = 0; i < 500; i++) {
    buff.repaintcool();
  }
  print((s..stop()).elapsedMilliseconds);
  print("repainttokencool(with):");
  s = Stopwatch()..start();
  for (var i = 0; i < 500; i++) {
    buff.repaintwithtokencheckcool();
  }
  print((s..stop()).elapsedMilliseconds);
  print("repainttokencool(with):");
  s = Stopwatch()..start();
  for (var i = 0; i < 500; i++) {
    buff.repaintwithtokencheckcool();
  }
  print((s..stop()).elapsedMilliseconds);
  print("repaint:");
  s = Stopwatch()..start();
  for (var i = 0; i < 500; i++) {
    buff.repaint();
  }
  print((s..stop()).elapsedMilliseconds);
  print("repaintcool:");

  s = Stopwatch()..start();
  for (var i = 0; i < 500; i++) {
    buff.repaintcool();
  }
  print((s..stop()).elapsedMilliseconds);

}

/// TEST WITH: dart compile exe
/// FASTEST: repaintcool
/// FASTEST with tokens: repaintwithtokencheckcool
/// IMPROVEMENTS:
/// - possibly even faster with for in
/// - improve speed of repaintwithtokencheckcool,
/// maybe implement global flag if there are any tokens
/// (and if there are none use repaintcool)
/// (and increment dekrement amount of tokens if adding any tokens,
/// if flag is at zero, delete all tokens)
