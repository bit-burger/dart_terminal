// Dart imports:
import 'dart:typed_data';

// Project imports:
import 'package:dart_terminal/core.dart';
import '../../core/style.dart';
import 'unicode_v11.dart';

class _HashEnd {
  const _HashEnd();
}

const _HashEnd _hashEnd = _HashEnd();

class _Jenkins {
  static int combine(int hash, Object? o) {
    assert(o is! Iterable);
    hash = 0x1fffffff & (hash + o.hashCode);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

int hashValues(
  Object? arg01,
  Object? arg02, [
  Object? arg03 = _hashEnd,
  Object? arg04 = _hashEnd,
  Object? arg05 = _hashEnd,
  Object? arg06 = _hashEnd,
  Object? arg07 = _hashEnd,
  Object? arg08 = _hashEnd,
  Object? arg09 = _hashEnd,
  Object? arg10 = _hashEnd,
  Object? arg11 = _hashEnd,
  Object? arg12 = _hashEnd,
  Object? arg13 = _hashEnd,
  Object? arg14 = _hashEnd,
  Object? arg15 = _hashEnd,
  Object? arg16 = _hashEnd,
  Object? arg17 = _hashEnd,
  Object? arg18 = _hashEnd,
  Object? arg19 = _hashEnd,
  Object? arg20 = _hashEnd,
]) {
  int result = 0;
  result = _Jenkins.combine(result, arg01);
  result = _Jenkins.combine(result, arg02);
  if (!identical(arg03, _hashEnd)) {
    result = _Jenkins.combine(result, arg03);
    if (!identical(arg04, _hashEnd)) {
      result = _Jenkins.combine(result, arg04);
      if (!identical(arg05, _hashEnd)) {
        result = _Jenkins.combine(result, arg05);
        if (!identical(arg06, _hashEnd)) {
          result = _Jenkins.combine(result, arg06);
          if (!identical(arg07, _hashEnd)) {
            result = _Jenkins.combine(result, arg07);
            if (!identical(arg08, _hashEnd)) {
              result = _Jenkins.combine(result, arg08);
              if (!identical(arg09, _hashEnd)) {
                result = _Jenkins.combine(result, arg09);
                if (!identical(arg10, _hashEnd)) {
                  result = _Jenkins.combine(result, arg10);
                  if (!identical(arg11, _hashEnd)) {
                    result = _Jenkins.combine(result, arg11);
                    if (!identical(arg12, _hashEnd)) {
                      result = _Jenkins.combine(result, arg12);
                      if (!identical(arg13, _hashEnd)) {
                        result = _Jenkins.combine(result, arg13);
                        if (!identical(arg14, _hashEnd)) {
                          result = _Jenkins.combine(result, arg14);
                          if (!identical(arg15, _hashEnd)) {
                            result = _Jenkins.combine(result, arg15);
                            if (!identical(arg16, _hashEnd)) {
                              result = _Jenkins.combine(result, arg16);
                              if (!identical(arg17, _hashEnd)) {
                                result = _Jenkins.combine(result, arg17);
                                if (!identical(arg18, _hashEnd)) {
                                  result = _Jenkins.combine(result, arg18);
                                  if (!identical(arg19, _hashEnd)) {
                                    result = _Jenkins.combine(result, arg19);
                                    if (!identical(arg20, _hashEnd)) {
                                      result = _Jenkins.combine(result, arg20);
                                      // I can see my house from here!
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  return _Jenkins.finish(result);
}

int hashList(Iterable<Object> arguments) {
  int result = 0;
  for (Object argument in arguments) {
    result = _Jenkins.combine(result, argument);
  }
  return _Jenkins.finish(result);
}

abstract class CellContent {
  static const codepointMask = 0x1fffff;

  static const widthShift = 22;
  // static const widthMask = 3 << widthShift;
}

const _cellSize = 4;

const _cellForeground = 0;

const _cellBackground = 1;

const _cellAttributes = 2;

const _cellContent = 3;

class BufferLine {
  final int index;
  BufferLine(this._length, {required this.index})
    : _data = Uint32List(_calcCapacity(_length) * _cellSize);

  BufferLine._(this._length, this._data, {required this.index});

  int _length;

  Uint32List _data;

  int get length => _length;

  int getForeground(int index) {
    return _data[index * _cellSize + _cellForeground];
  }

  int getBackground(int index) {
    return _data[index * _cellSize + _cellBackground];
  }

  int getAttributes(int index) {
    return _data[index * _cellSize + _cellAttributes];
  }

  int getContent(int index) {
    return _data[index * _cellSize + _cellContent];
  }

  int getCodePoint(int index) {
    return _data[index * _cellSize + _cellContent] & CellContent.codepointMask;
  }

  int getWidth(int index) {
    return _data[index * _cellSize + _cellContent] >> CellContent.widthShift;
  }

  void setForeground(int index, int value) {
    _data[index * _cellSize + _cellForeground] = value;
  }

  void setBackground(int index, int value) {
    _data[index * _cellSize + _cellBackground] = value;
  }

  void setAttributes(int index, int value) {
    _data[index * _cellSize + _cellAttributes] = value;
  }

  void setCell(
    int index, {
    Foreground? fg = const Foreground(),
    Color? bg = const Color.normal(),
  }) {
    final offset = index * _cellSize;
    if (fg != null) {
      final char = fg.codePoint;
      final width = unicodeV11.wcwidth(char); // performance
      _data[offset + _cellForeground] = colorData(fg.color);
      _data[offset + _cellAttributes] = textEffectsData(fg.effects);
      _data[offset + _cellContent] =
          fg.codePoint | (width << CellContent.widthShift);
    }
    if (bg != null) {
      _data[offset + _cellBackground] = colorData(bg);
    }
  }

  void resetCell(int index) {
    final offset = index * _cellSize;
    _data[offset + _cellForeground] = 0;
    _data[offset + _cellBackground] = 0;
    _data[offset + _cellAttributes] = 0;
    _data[offset + _cellContent] = 0;
  }

  static int _calcCapacity(int length) {
    assert(length >= 0);

    var capacity = 64;

    if (length < 256) {
      while (capacity < length) {
        capacity *= 2;
      }
    } else {
      capacity = 256;
      while (capacity < length) {
        capacity += 32;
      }
    }

    return capacity;
  }

  String getText([int? from, int? to]) {
    if (from == null || from < 0) {
      from = 0;
    }

    if (to == null || to > _length) {
      to = _length;
    }

    final builder = StringBuffer();
    for (var i = from; i < to; i++) {
      final codePoint = getCodePoint(i);
      final width = getWidth(i);
      if (codePoint != 0 && i + width <= to) {
        builder.writeCharCode(codePoint);
      }
    }

    return builder.toString();
  }

  @override
  String toString() {
    return getText();
  }

  void copyFrom(BufferLine bufferLine) {
    _data.setAll(0, bufferLine._data);
  }
}

List<BufferLine> createBuffer(Size size) =>
    List.generate(size.height, (i) => BufferLine(size.width, index: i));
