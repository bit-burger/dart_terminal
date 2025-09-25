// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:quiver/collection.dart';

/// A cache of laid out [Paragraph]s. This is used to avoid laying out the same
/// text multiple times, which is expensive.
class ParagraphCache {
  ParagraphCache(int maximumSize)
    : _cache = LruMap<int, Paragraph>(maximumSize: maximumSize);

  final LruMap<int, Paragraph> _cache;

  /// Returns a [Paragraph] for the given [key]. [key] is the same as the
  /// key argument to [performAndCacheLayout].
  Paragraph? getLayoutFromCache(int key) {
    return _cache[key];
  }

  /// Applies [style] and [textScaler] to [text] and lays it out to create
  /// a [Paragraph]. The [Paragraph] is cached and can be retrieved with the
  /// same [key] by calling [getLayoutFromCache].
  Paragraph performAndCacheLayout(
    String text,
    TextStyle style,
    TextScaler textScaler,
    int key,
  ) {
    final builder = ParagraphBuilder(style.getParagraphStyle());
    builder.pushStyle(style.getTextStyle(textScaler: textScaler));
    builder.addText(text);

    final paragraph = builder.build();
    paragraph.layout(ParagraphConstraints(width: double.infinity));

    _cache[key] = paragraph;
    return paragraph;
  }

  /// Clears the cache. This should be called when the same text and style
  /// pair no longer produces the same layout. For example, when a font is
  /// loaded.
  void clear() {
    _cache.clear();
  }

  /// Returns the number of [Paragraph]s in the cache.
  int get length {
    return _cache.length;
  }
}

const _kDefaultFontSize = 13.0;

const _kDefaultHeight = 1.2;

const _kDefaultFontFamily = 'monospace';

const _kDefaultFontFamilyFallback = [
  'Menlo',
  'Monaco',
  'Consolas',
  'Liberation Mono',
  'Courier New',
  'Noto Sans Mono CJK SC',
  'Noto Sans Mono CJK TC',
  'Noto Sans Mono CJK KR',
  'Noto Sans Mono CJK JP',
  'Noto Sans Mono CJK HK',
  'Noto Color Emoji',
  'Noto Sans Symbols',
  'monospace',
  'sans-serif',
];

class TerminalStyle {
  const TerminalStyle({
    this.fontSize = _kDefaultFontSize,
    this.height = _kDefaultHeight,
    this.fontFamily = _kDefaultFontFamily,
    this.fontFamilyFallback = _kDefaultFontFamilyFallback,
  });

  factory TerminalStyle.fromTextStyle(TextStyle textStyle) {
    return TerminalStyle(
      fontSize: textStyle.fontSize ?? _kDefaultFontSize,
      height: textStyle.height ?? _kDefaultHeight,
      fontFamily:
          textStyle.fontFamily ??
          textStyle.fontFamilyFallback?.first ??
          _kDefaultFontFamily,
      fontFamilyFallback:
          textStyle.fontFamilyFallback ?? _kDefaultFontFamilyFallback,
    );
  }

  final double fontSize;

  final double height;

  final String fontFamily;

  final List<String> fontFamilyFallback;

  TextStyle toTextStyle({
    Color? color,
    Color? backgroundColor,
    bool bold = false,
    bool italic = false,
    bool underline = false,
  }) {
    return TextStyle(
      fontSize: fontSize,
      height: height,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      color: color,
      backgroundColor: backgroundColor,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      decoration: underline ? TextDecoration.underline : TextDecoration.none,
    );
  }

  TerminalStyle copyWith({
    double? fontSize,
    double? height,
    String? fontFamily,
    List<String>? fontFamilyFallback,
  }) {
    return TerminalStyle(
      fontSize: fontSize ?? this.fontSize,
      height: height ?? this.height,
      fontFamily: fontFamily ?? this.fontFamily,
      fontFamilyFallback: fontFamilyFallback ?? this.fontFamilyFallback,
    );
  }
}

class TerminalTheme {
  const TerminalTheme({
    required this.cursor,
    required this.selection,
    required this.foreground,
    required this.background,
    required this.black,
    required this.white,
    required this.red,
    required this.green,
    required this.yellow,
    required this.blue,
    required this.magenta,
    required this.cyan,
    required this.brightBlack,
    required this.brightRed,
    required this.brightGreen,
    required this.brightYellow,
    required this.brightBlue,
    required this.brightMagenta,
    required this.brightCyan,
    required this.brightWhite,
    required this.searchHitBackground,
    required this.searchHitBackgroundCurrent,
    required this.searchHitForeground,
  });

  final Color cursor;
  final Color selection;

  final Color foreground;
  final Color background;

  final Color black;
  final Color red;
  final Color green;
  final Color yellow;
  final Color blue;
  final Color magenta;
  final Color cyan;
  final Color white;

  final Color brightBlack;
  final Color brightRed;
  final Color brightGreen;
  final Color brightYellow;
  final Color brightBlue;
  final Color brightMagenta;
  final Color brightCyan;
  final Color brightWhite;

  final Color searchHitBackground;
  final Color searchHitBackgroundCurrent;
  final Color searchHitForeground;
}

class PaletteBuilder {
  final TerminalTheme theme;

  PaletteBuilder(this.theme);

  List<Color> build() {
    return List<Color>.generate(256, paletteColor, growable: false);
  }

  /// https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
  Color paletteColor(int colNum) {
    switch (colNum) {
      case 0:
        return theme.black;
      case 1:
        return theme.red;
      case 2:
        return theme.green;
      case 3:
        return theme.yellow;
      case 4:
        return theme.blue;
      case 5:
        return theme.magenta;
      case 6:
        return theme.cyan;
      case 7:
        return theme.white;
      case 8:
        return theme.brightBlack;
      case 9:
        return theme.brightRed;
      case 10:
        return theme.brightGreen;
      case 11:
        return theme.brightYellow;
      case 12:
        return theme.brightBlue;
      case 13:
        return theme.brightMagenta;
      case 14:
        return theme.brightCyan;
      case 15:
        return theme.brightWhite;
    }

    if (colNum < 232) {
      var r = 0;
      var g = 0;
      var b = 0;

      final index = colNum - 16;

      for (var i = 0; i < index; i++) {
        if (b == 0) {
          b = 95;
        } else if (b < 255) {
          b += 40;
        } else {
          b = 0;
          if (g == 0) {
            g = 95;
          } else if (g < 255) {
            g += 40;
          } else {
            g = 0;
            if (r == 0) {
              r = 95;
            } else if (r < 255) {
              r += 40;
            } else {
              break;
            }
          }
        }
      }

      return Color.fromARGB(0xFF, r, g, b);
    }

    return Color(_grayscaleColors[colNum.clamp(232, 255)]!);
  }
}

final _grayscaleColors = FastLookupTable({
  232: 0xff080808,
  233: 0xff121212,
  234: 0xff1c1c1c,
  235: 0xff262626,
  236: 0xff303030,
  237: 0xff3a3a3a,
  238: 0xff444444,
  239: 0xff4e4e4e,
  240: 0xff585858,
  241: 0xff626262,
  242: 0xff6c6c6c,
  243: 0xff767676,
  244: 0xff808080,
  245: 0xff8a8a8a,
  246: 0xff949494,
  247: 0xff9e9e9e,
  248: 0xffa8a8a8,
  249: 0xffb2b2b2,
  250: 0xffbcbcbc,
  251: 0xffc6c6c6,
  252: 0xffd0d0d0,
  253: 0xffdadada,
  254: 0xffe4e4e4,
  255: 0xffeeeeee,
});

class FastLookupTable<T> {
  FastLookupTable(Map<int, T> data) {
    var maxIndex = data.keys.first;

    for (var key in data.keys) {
      if (key > maxIndex) {
        maxIndex = key;
      }
    }

    _maxIndex = maxIndex;

    _table = List<T?>.filled(maxIndex + 1, null);

    for (var entry in data.entries) {
      _table[entry.key] = entry.value;
    }
  }

  late final List<T?> _table;
  late final int _maxIndex;

  T? operator [](int index) {
    if (index > _maxIndex) {
      return null;
    }

    return _table[index];
  }

  int get maxIndex => _maxIndex;
}

const defaultTheme = TerminalTheme(
  cursor: Color(0XAAAEAFAD),
  selection: Color(0XAAAEAFAD),
  foreground: Color(0XFFCCCCCC),
  background: Color(0XFF1E1E1E),
  black: Color(0XFF000000),
  red: Color(0XFFCD3131),
  green: Color(0XFF0DBC79),
  yellow: Color(0XFFE5E510),
  blue: Color(0XFF2472C8),
  magenta: Color(0XFFBC3FBC),
  cyan: Color(0XFF11A8CD),
  white: Color(0XFFE5E5E5),
  brightBlack: Color(0XFF666666),
  brightRed: Color(0XFFF14C4C),
  brightGreen: Color(0XFF23D18B),
  brightYellow: Color(0XFFF5F543),
  brightBlue: Color(0XFF3B8EEA),
  brightMagenta: Color(0XFFD670D6),
  brightCyan: Color(0XFF29B8DB),
  brightWhite: Color(0XFFFFFFFF),
  searchHitBackground: Color(0XFFFFFF2B),
  searchHitBackgroundCurrent: Color(0XFF31FF26),
  searchHitForeground: Color(0XFF000000),
);

abstract class CellFlags {
  static const bold = 1 << 0;
  static const faint = 1 << 1;
  static const italic = 1 << 2;
  static const underline = 1 << 3;
  static const blink = 1 << 4;
  static const inverse = 1 << 5;
  static const invisible = 1 << 6;
}
