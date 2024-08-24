import 'package:advanced_terminal/src/style/legacy_style.dart';
import 'dart:typed_data';

import '../terminal/terminal.dart';

enum RedrawMode {
  direct,
  manualRefresh,
  efficientRefresh,
}

abstract class TerminalCanvas {
  int get rows;
  int get columns;

  void draw(int x, int y, int char, TerminalStyle style);
}

class ManualRefreshTerminalCanvas extends TerminalCanvas {
  @override
  int get rows => _rows;
  @override
  int get columns => _columns;
  int _rows, _columns;

  /// Access by: [_columns * y + x]
  final Uint8List _writing;
  final List<TerminalStyle?> _styles;

  ManualRefreshTerminalCanvas(
    this._columns,
    this._rows,
  )   : _styles = List.filled(_rows * _columns, null),
        _writing = Uint8List(_rows * _columns);

  void writeToTerminal(TerminalWindow window) {
    window.bufferedEscapeCodeWriter.clearScreen();
    var lastStyle = TerminalStyle.defaultStyle;
    for (var i = 0; i < _writing.length; i++) {
      final style = _styles[i] ?? TerminalStyle.defaultStyle;
      if (!identical(style, lastStyle)) {
        TerminalStyle.forceWriteSGRChangeParameters(
          lastStyle,
          style,
          window.bufferedEscapeCodeWriter,
        );
      }
      window.bufferedTerminalWriter.writeCharCode(_writing[i]);
      lastStyle = style;
    }
    window.bufferedTerminalWriter.flush();
  }

  @override
  void draw(int x, int y, int char, TerminalStyle style) {
    _writing[_columns * y + x] = char;
    _styles[_columns * y + x] = style;
  }

  @override
  void _resize(int rows, int columns) {
    _rows = rows;
    _columns = columns;
    _writing.length = rows * columns;
    _styles.length = rows * columns;
  }
}

// class TerminalCanvas {
//   final RedrawMode redrawMode;
//   int get rows => _rows;
//   int get columns => _columns;
//   int _rows, _columns;
//
//   Uint8List _writing;
//   List<TerminalStyle> _styles;
//   late BoolList _shouldRedraw;
//
//   TerminalCanvas._(
//     this._rows,
//     this._columns,
//     this.redrawMode,
//   ) : _styles = List.filled(
//           _rows * _columns,
//           TerminalStyle.defaultStyle,
//         );
//
//
// }
//
