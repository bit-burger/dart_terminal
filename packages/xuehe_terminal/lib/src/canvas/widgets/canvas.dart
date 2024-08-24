import '../../style/style.dart';

class Canvas {
  int _width, _height;
  int get width => _width;
  int get height => _height;

  /// [a, b, c, d, e, f, g, h, i]
  /// ->
  /// [a, b, c, => row abc
  /// d, e, f,
  /// g, h, i]
  /// => column adg
  final List<Pixel> _pixels;

  Canvas(this._width, this._height)
      : _pixels = List.generate(
          _width * _height,
          (_) => Pixel(),
        );

  Pixel getPixel(int x, int y) => _pixels[y * _width + x];

  void paint(
    ForegroundStyle foregroundStyle,
    TerminalColor backgroundColor,
    int x,
    int y,
    int z,
  ) {
    final pixel = getPixel(x, y);
    if (z >= pixel.zAxis) {
      pixel.hasChanged = true;
      pixel.foregroundStyle = foregroundStyle;
      pixel.backgroundColor = backgroundColor;
      pixel.zAxis = z;
    }
  }

  void paintForeground(
    ForegroundStyle foregroundStyle,
    int x,
    int y,
    int z,
  ) {
    final pixel = getPixel(x, y);
    if (z >= pixel.zAxis) {
      pixel.hasChanged = true;
      pixel.foregroundStyle = foregroundStyle;
      pixel.zAxis = z;
    }
  }

  void paintBackground(
    TerminalColor backgroundColor,
    int x,
    int y,
    int z,
  ) {
    final pixel = getPixel(x, y);
    if (z >= pixel.zAxis) {
      pixel.hasChanged = true;
      pixel.backgroundColor = backgroundColor;
      pixel.zAxis = z;
    }
  }
}

class Pixel {
  bool hasChanged = true;
  int zAxis = 0;
  int charCode = 32;
  String? string;
  ForegroundStyle foregroundStyle = ForegroundStyle.defaultStyle;
  TerminalColor backgroundColor = DefaultTerminalColor();
}
