// Dart imports:
import 'dart:io';

// Package imports:
import 'package:image/image.dart' as img;

// Project imports:
import 'package:dart_terminal/core.dart';

/// Implementation of terminal images using native image processing.
///
/// This class provides functionality to display images in the terminal by
/// converting them to colored terminal cells. It supports loading images
/// from files and creating blank or filled image buffers.
class NativeTerminalImage extends TerminalImage {
  /// Storage for color data, where each element represents a terminal cell
  final List<Color?> _data;

  /// Dimensions of the terminal image
  final Size _size;

  /// Creates an empty terminal image with the specified dimensions.
  ///
  /// All cells are initialized as transparent (null color).
  factory NativeTerminalImage.empty(Size size) =>
      NativeTerminalImage.filled(size, null);

  /// Creates a terminal image filled with a single color.
  ///
  /// [size] determines the dimensions of the image.
  /// [color] is the color to fill with, null for transparent.
  NativeTerminalImage.filled(Size size, Color? color)
    : _data = List.filled(size.width * size.height, color),
      _size = size;

  /// Converts a pixel from a native image to a terminal color.
  ///
  /// [i] is the linear index in the image
  /// [img] is the source image
  /// [background] is the color to use for transparent pixels
  static Color? _getPixelFromNative(int i, img.Image img, Color? background) {
    final x = i % img.width;
    final y = i ~/ img.width;
    final pixel = img.getPixel(x, y);

    // Handle transparency
    if (pixel.a == 0) {
      return background;
    }

    // Convert RGB values to terminal color
    return Color.rgbOptimizedForBackground(
      r: pixel.r.toInt(),
      g: pixel.g.toInt(),
      b: pixel.b.toInt(),
    );
  }

  /// Creates a terminal image from an image file.
  ///
  /// [size] specifies the desired dimensions in terminal cells
  /// [path] is the path to the image file
  /// [backgroundColor] is used for transparent pixels
  static NativeTerminalImage fromPath({
    required Size size,
    required String path,
    Color? backgroundColor,
  }) {
    var image = img.decodeImage(File(path).readAsBytesSync());
    if (image == null) throw ArgumentError("File could not be decoded");

    // Resize image to match terminal dimensions
    image = img.copyResize(image, width: size.width, height: size.height);
    return NativeTerminalImage.fromRealImage(
      image: image,
      backgroundColor: backgroundColor,
    );
  }

  /// Creates a terminal image from an existing image object.
  ///
  /// [image] is the source image
  /// [backgroundColor] is used for transparent pixels
  NativeTerminalImage.fromRealImage({
    required img.Image image,
    Color? backgroundColor,
  }) : _data = List.generate(
         image.height * image.width,
         (i) => _getPixelFromNative(i, image, backgroundColor),
       ),
       _size = Size(image.width, image.height);

  @override
  Color? operator [](Position position) =>
      _data[position.y * size.width + position.x];

  @override
  void operator []=(Position position, Color? color) {
    _data[position.y * size.width + position.x] = color;
  }

  @override
  Size get size => _size;
}
