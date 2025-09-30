// Project imports:
import 'package:dart_terminal/ansi.dart';
import 'package:characters/characters.dart';
import 'package:wcwidth/wcwidth.dart';

import '../../core/style.dart';

const int _leftBorderMask = 1 << 63;
const int _topBorderMask = 1 << 62;
const int _rightBorderMask = 1 << 61;
const int _bottomBorderMask = 1 << 60;
const int _borderDrawIdMask = ~(0xF << 60);

/// marks the foreground that an extension has painted this
const extensionForeground = Foreground(codeUnit: 0);

/// an extension for [TerminalCell]s,
/// is on the same layer as the foreground
/// and therefore replaces it.
///
/// The size of the object that is rendered is [size].
/// Only write an extension into the buffer if the [size] fits.
/// In this area there should only be the the [ForegroundCellExtension]
/// on the top left and all other cells foreground should not be changed
/// after setting the extension.
///
/// Therefore setting an extension means:
/// - setting the [TerminalCell.fg] to [extensionForeground]
/// - setting [TerminalCell.changed] to `false`
/// - setting [TerminalCell.extension] to `null`
///   and if it was not 0 before invalidating the complete extension
///
/// Before updating a screen it should be checked
/// if all extensions are still valid (otherwise invalidate it):
/// - check if [TerminalCell.extension] is `null` everywhere
///   (except the top left which is the extension itself)
/// - check if [TerminalCell.fg] is [extensionForeground]
/// - check if another extension is found in the area of the extension,
///   and invalidate the newer extension (check via [extensionTimestamp])
///   except if both extensions are of the same type and [supportStacking]
///   is true
///
/// To invalidate an extension:
/// - set all the foregrounds to the default foreground
/// - set changed to true on the extensions and all of its lines
/// - set the [TerminalCell.extension] to `null` from the extension cell
sealed class ForegroundCellExtension {
  final Size size;
  final int extensionTimestamp;
  static int _extensionCount = 0;
  final bool supportStacking;

  ForegroundCellExtension(this.size, {this.supportStacking = false})
    : extensionTimestamp = _extensionCount++;
}

/// to render a character that either isn't in the unicode BMP
/// or has a with width greater than 1 (e.g emojis)
/// and therefore requires special handling
final class CharacterCellExtension extends ForegroundCellExtension {
  final String grapheme;

  CharacterCellExtension(int width, this.grapheme) : super(Size(width, 1));
}

class TerminalCell {
  bool changed = false;
  Foreground fg = Foreground();
  Color bg = Color.normal();
  Foreground? newFg;
  Color? newBg;
  int borderState = 0;
  ForegroundCellExtension? extension;

  static List<TerminalCell> rowGen(int length) =>
      List.generate(length, (_) => TerminalCell());

  void draw(Foreground? fg, Color? bg) {
    assert(fg != null || bg != null);

    if (fg != null) {
      newFg = fg;
    }
    if (bg != null) {
      newBg = bg;
    }
    changed = true;
  }

  bool calculateDifference() {
    assert(changed);
    bool diff = false;
    if (newFg != null) {
      if (!equalsForeground(newFg!, fg)) {
        diff = true;
        fg = newFg!;
      }
      newFg = null;
    }
    if (newBg != null) {
      if (!equalsColor(newBg!, bg)) {
        diff = true;
        bg = newBg!;
      }
      newBg = null;
    }
    return diff;
  }

  bool isDifferent() =>
      (newBg != null && equalsColor(newBg!, bg)) ||
      (newFg != null && equalsForeground(newFg!, fg));

  void reset(Foreground foreground, Color background) {
    fg = foreground;
    bg = background;
    newFg = newBg = null;
    extension = null;
    changed = false;
    // borderState does not need to be reset as the
    // BorderIdentifier should not be reused between resets
    // and there fore because they are unique
    // one will never find the same BorderIdentifier (of the borderState)
    // across resets
  }

  void drawBorder(
    bool left,
    bool top,
    bool right,
    bool bottom,
    BorderCharSet charSet,
    Color foregroundColor,
    BorderDrawIdentifier borderIdentifier,
  ) {
    if (borderIdentifier.value != (_borderDrawIdMask & borderState)) {
      borderState = borderIdentifier.value;
    }
    left = left || (borderState & _leftBorderMask != 0);
    top = top || (borderState & _topBorderMask != 0);
    right = right || (borderState & _rightBorderMask != 0);
    bottom = bottom || (borderState & _bottomBorderMask != 0);
    if (left) borderState = borderState | _leftBorderMask;
    if (top) borderState = borderState | _topBorderMask;
    if (right) borderState = borderState | _rightBorderMask;
    if (bottom) borderState = borderState | _bottomBorderMask;

    changed = true;
    newFg = Foreground(
      style: ForegroundStyle(color: foregroundColor),
      codeUnit: charSet.getCorrectGlyph(left, top, right, bottom),
    );
  }
}

abstract class BufferTerminalViewport extends TerminalViewport {
  final List<List<TerminalCell>> _data = [];
  final List<bool> _changeList = [];
  Size _dataSize = Size(0, 0);

  bool checkRowChanged(int row) {
    final changed = _changeList[row];
    _changeList[row] = false;
    return changed;
  }

  List<TerminalCell> getRow(int row) => _data[row];

  void resizeBuffer() {
    if (_dataSize.height < size.height) {
      _changeList.addAll(
        List.generate(size.height - _dataSize.height, (_) => false),
      );
    }
    if (_dataSize.width < size.width) {
      for (final row in _data) {
        row.addAll(TerminalCell.rowGen(size.width - _dataSize.width));
      }
      _dataSize = Size(size.width, _dataSize.height);
    }
    if (_dataSize.height < size.height) {
      _data.addAll(
        List.generate(
          size.height - _dataSize.height,
          (_) => TerminalCell.rowGen(_dataSize.width),
        ),
      );
      _dataSize = Size(_dataSize.width, size.height);
    }
    assert(
      _dataSize.height == _data.length &&
          _data
              .map((r) => r.length == _dataSize.width)
              .reduce((a, b) => a && b),
    );
  }

  void resetBuffer({
    Foreground foreground = const Foreground(),
    Color background = const Color.normal(),
  }) {
    for (int j = 0; j < size.height; j++) {
      _changeList[j] = false;
      for (int i = 0; i < size.width; i++) {
        _data[j][i].reset(foreground, background);
      }
    }
  }

  @override
  void drawColor({
    Color color = const Color.normal(),
    bool optimizeByClear = true,
  }) {
    drawRect(
      background: color,
      foreground: Foreground(),
      rect: Position.topLeft & size,
    );
  }

  @override
  void drawBorderBox({
    required Rect rect,
    required BorderCharSet style,
    Color color = const Color.normal(),
    BorderDrawIdentifier? drawId,
  }) {
    super.drawBorderBox(rect: rect, color: color, drawId: drawId, style: style);
    drawId ??= BorderDrawIdentifier();

    line(Position f, Position t, BorderDrawIdentifier id) =>
        drawBorderLine(from: f, to: t, style: style, color: color, drawId: id);

    line(rect.topLeft, rect.topRight, drawId);
    line(rect.topRight, rect.bottomRight, drawId);
    line(rect.bottomLeft, rect.bottomRight, drawId);
    line(rect.topLeft, rect.bottomLeft, drawId);
  }

  @override
  void drawBorderLine({
    required Position from,
    required Position to,
    required BorderCharSet style,
    Color color = const Color.normal(),
    BorderDrawIdentifier? drawId,
  }) {
    drawId ??= BorderDrawIdentifier();
    if (from.x == to.x) {
      for (int y = from.y; y <= to.y; y++) {
        _changeList[y] = true;
        final cell = _data[y][from.x];
        cell.drawBorder(
          false,
          y != from.y,
          false,
          y != to.y,
          style,
          color,
          drawId,
        );
      }
    } else {
      _changeList[from.y] = true;
      for (int x = from.x; x <= to.x; x++) {
        final cell = _data[from.y][x];
        cell.drawBorder(
          x != from.x,
          false,
          x != to.x,
          false,
          style,
          color,
          drawId,
        );
      }
    }
  }

  @override
  void drawImage({
    required Position position,
    required NativeTerminalImage image,
  }) {
    final clip = (Position.topLeft & size).clip(position & image.size);
    for (int y = clip.y1; y <= clip.y2; y++) {
      _changeList[y] = true;
      for (int x = clip.x1; x <= clip.x2; x++) {
        final color = image[Position(x - position.x, y - position.y)];
        if (color != null) _data[y][x].draw(null, color);
      }
    }
  }

  @override
  void drawPoint({
    required Position position,
    Color? background,
    Foreground? foreground,
  }) {
    if (!(Position.topLeft & size).contains(position)) return;
    _changeList[position.y] = true;
    _data[position.y][position.x].draw(foreground, background);
  }

  @override
  void drawRect({
    required Rect rect,
    Color? background,
    Foreground? foreground,
  }) {
    rect = rect.clip(Position.topLeft & size);
    for (int y = rect.y1; y <= rect.y2; y++) {
      _changeList[y] = true;
      for (int x = rect.x1; x <= rect.x2; x++) {
        _data[y][x].draw(foreground, background);
      }
    }
  }

  @override
  void drawText({
    required String text,
    required Position position,
    TextStyle style = const TextStyle(),
  }) {
    _changeList[position.y] = true;
    for (int i = 0; i < text.length; i++) {
      int codepoint = text.codeUnitAt(i);
      final charPosition = Position(position.x + i, position.y);

      if (!(Position.topLeft & size).contains(charPosition)) continue;
      if (codepoint < 32 || codepoint == 127) continue;

      final foreground = Foreground(style: style.fgStyle, codeUnit: codepoint);
      _data[charPosition.y][charPosition.x].draw(
        foreground,
        style.backgroundColor,
      );
    }
  }

  /// draws the [extension]
  void _drawExtension(
    ForegroundCellExtension extension,
    Position position,
    Color background,
  ) {
    if (!(Position.topLeft & size).containsRect(position & extension.size)) {
      return;
    }
    final cell = _data[position.y][position.x];
    if (cell.extension != null) {
      invalidateExtension(position);
    }
    cell
      ..extension = extension
      ..changed = true;
    for (int j = 0; j < extension.size.height; j++) {
      for (int i = 0; i < extension.size.width; i++) {
        final cell = _data[j][i];
        cell.newBg = background;
        cell.calculateDifference();
        cell.changed = false;
      }
    }
  }

  void invalidateExtension(Position cellPos) {
    final extensionCell = _data[cellPos.y][cellPos.x];
    final extension = extensionCell.extension!;
    extensionCell.extension = null;
    for (int y = cellPos.y; y < extension.size.height + cellPos.y; y++) {
      _changeList[y] = true;
      final row = getRow(y);
      for (int x = cellPos.x; x < extension.size.width + cellPos.x; x++) {
        final cell = row[x];
        cell.changed = true;
        cell.newFg = Foreground();
      }
    }
  }

  @override
  void drawUnicodeText({
    required String text,
    required Position position,
    TextStyle style = const TextStyle(),
  }) {
    _changeList[position.y] = true;
    int x = position.x;
    for (final character in text.characters) {
      final charPos = Position(x, position.y);
      if (!(Position.topLeft & size).contains(charPos)) continue;
      final width = character.wcwidth();
      if (width == 1 && character.length == 1) {
        // is in BMP (only one code unit) and width is 1
        final foreground = Foreground(
          style: style.fgStyle,
          codeUnit: character.codeUnitAt(0),
        );
        _data[charPos.y][charPos.x].draw(foreground, style.backgroundColor);
      } else {
        // if width == 2 will check if sticks out right
        _drawExtension(
          CharacterCellExtension(width, character),
          Position(x, position.y),
          style.backgroundColor ?? const Color.normal(),
        );
      }
      x += width;
    }
  }
}
