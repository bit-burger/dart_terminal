import 'dart:io';

import 'package:image/image.dart' as img;

import 'package:dart_tui/core.dart';

class NativeTerminalImage extends TerminalImage {
  final List<TerminalColor?> _data;
  final Size _size;

  factory NativeTerminalImage.empty(Size size) =>
      NativeTerminalImage.filled(size, null);

  NativeTerminalImage.filled(Size size, TerminalColor? color)
    : _data = List.filled(size.width * size.height, color),
      _size = size;

  static TerminalColor? _getPixelFromNative(
    int i,
    img.Image img,
    TerminalColor? background,
  ) {
    final x = i % img.width;
    final y = i ~/ img.width;
    final pixel = img.getPixel(x, y);
    if (pixel.a == 0) {
      return background;
    }
    return RGBTerminalColor(
      red: pixel.r.toInt(),
      green: pixel.g.toInt(),
      blue: pixel.b.toInt(),
    );
  }

  static NativeTerminalImage fromPath({
    required Size size,
    required String path,
    TerminalColor? backgroundColor,
  }) {
    var image = img.decodeImage(File(path).readAsBytesSync());
    if (image == null) throw ArgumentError("File could not be decoded");

    image = img.copyResize(image, width: size.width, height: size.height);
    return NativeTerminalImage.fromRealImage(
      image: image,
      backgroundColor: backgroundColor,
    );
  }

  NativeTerminalImage.fromRealImage({
    required img.Image image,
    TerminalColor? backgroundColor,
  }) : _data = List.generate(
         image.height * image.width,
         (i) => _getPixelFromNative(i, image, backgroundColor),
       ),
       _size = Size(image.width, image.height);

  @override
  TerminalColor? operator [](Position position) =>
      _data[position.y * size.width + position.x];

  @override
  void operator []=(Position position, TerminalColor? color) {
    _data[position.y * size.width + position.x] = color;
  }

  @override
  Size get size => _size;
}
