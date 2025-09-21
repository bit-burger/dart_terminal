import 'geometry.dart';
import 'style.dart';

/// A terminal image representation that can be drawn on the terminal canvas.
///
/// Terminal images are color-based buffers that can be created and manipulated
/// before being rendered to the terminal screen.
abstract class TerminalImage {
  /// The size of the image in terminal cells.
  Size get size;

  /// Get the color at the specified position.
  ///
  /// Returns null if the position is transparent or out of bounds.
  TerminalColor? operator [](Position position);

  /// Set the color at the specified position.
  ///
  /// Use null to make the position transparent.
  void operator []=(Position position, TerminalColor? color);
}

/// Identifier used to track border drawing operations.
///
/// This allows the rendering system to properly handle border intersections
/// when multiple border elements are drawn in the same drawing operation.
extension type const BorderDrawIdentifier._(int id) {
  /// Creates a new unique border draw identifier.
  static int _currentId = 0;

  /// Generates a new unique identifier each time it is called.
  BorderDrawIdentifier() : id = _currentId++;

  /// The unique identifier value.
  int get value => id;
}

/// The primary drawing surface for terminal user interfaces.
///
/// TerminalCanvas provides a set of high-level drawing operations that can be used
/// to create complex terminal user interfaces. It handles text rendering, rectangles,
/// borders, and image composition.
abstract class TerminalCanvas {
  /// The size of the canvas in terminal cells.
  Size get size;

  /// Draws text on the canvas at the specified position.
  ///
  /// The [text] will be rendered starting at [position], applying the optional
  /// [style] for text formatting.
  void drawText({
    required String text,
    required Position position,
    TerminalForegroundStyle? style,
  });

  /// Draws a filled rectangle on the canvas.
  ///
  /// The rectangle is defined by [rect] and can have optional [background] and
  /// [foreground] colors.
  void drawRect({
    required Rect rect,
    TerminalColor? background,
    TerminalForeground? foreground,
  });

  /// Draws a single point on the canvas.
  ///
  /// Colors the terminal cell at [position] with the specified [background]
  /// and [foreground] colors.
  void drawPoint({
    required Position position,
    TerminalColor? background,
    TerminalForeground? foreground,
  });

  /// Draws a box border around or within the specified rectangle.
  ///
  /// Uses [borderStyle] to determine the border characters and [foregroundColor]
  /// for the border color. The [drawIdentifier] helps manage border intersections.
  void drawBorderBox({
    required Rect rect,
    required BorderCharSet borderStyle,
    TerminalColor foregroundColor,
    BorderDrawIdentifier drawIdentifier,
  });

  /// Draws a border line between two points.
  ///
  /// The line is drawn from [from] to [to] using the specified [borderStyle]
  /// and [foregroundColor]. The [drawIdentifier] helps manage line intersections.
  void drawBorderLine({
    required Position from,
    required Position to,
    required BorderCharSet borderStyle,
    TerminalColor foregroundColor,
    BorderDrawIdentifier drawIdentifier,
  });

  /// Composites a terminal image onto the canvas.
  ///
  /// The [image] will be drawn with its top-left corner at [position].
  void drawImage({
    required Position position,
    required covariant TerminalImage image,
  });
}
