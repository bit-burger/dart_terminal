part of "style.dart";

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
  final int _bitField;

  TextDecorationSet._raw(this._bitField);

  TextDecorationSet._decorationNumber(int decorationNumber)
      : this._raw(1 << decorationNumber);

  const TextDecorationSet.empty() : _bitField = 0;

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
      decoration.bitFlag & _bitField != 0;

  static void transitionSGRCode(
    TextDecorationSet from,
    TextDecorationSet to,
    TerminalEscapeCodeWriter escapeCodeWriter,
  ) {
    if (from._bitField != to._bitField) {
      final changedBitMask = ~(from._bitField & to._bitField);
      final removedBitField = from._bitField & changedBitMask;
      _applyBitFieldToSGR(removedBitField, false, escapeCodeWriter);
      final addedBitField = to._bitField & changedBitMask;
      _applyBitFieldToSGR(addedBitField, true, escapeCodeWriter);
    }
  }

  static void _applyBitFieldToSGR(
    int bitField,
    bool addDecorations,
    TerminalEscapeCodeWriter escapeCodeWriter,
  ) {
    if (bitField != 0) {
      for (var i = 0; i <= TextDecoration.highestBitFlag; i++) {
        final decorationBitFlag = 1 << i;
        if (decorationBitFlag & bitField != 0) {
          final decoration = TextDecoration.values[i];
          if (addDecorations) {
            escapeCodeWriter.escParam(decoration.onCode);
          } else {
            escapeCodeWriter.escParam(decoration.offCode);
          }
        }
      }
    }
  }

  @override
  int get hashCode => _bitField;

  @override
  bool operator ==(Object other) =>
      other is TextDecorationSet && _bitField == other._bitField;
}
