// Project imports:
import 'package:dart_terminal/core.dart';
import 'package:dart_terminal/src/platform/shared/buffer_terminal_viewport.dart';

class FlutterTerminalViewport extends BufferTerminalViewport {
  bool hasSize = false;
  late Size _size;
  Size get size => _size;
  late void Function() onChanged;

  void updateSize(Size size) {
    hasSize = true;
    _size = size;
    resizeBuffer();
  }

  CursorState? _cursor = CursorState(position: Position.topLeft);
  @override
  CursorState? get cursor => _cursor;
  set cursor(CursorState? cursor) {
    _cursor = cursor;
    onChanged();
  }

  @override
  void updateScreen() {
    for (int y = 0; y < size.height; y++) {
      if (!checkRowChanged(y)) continue;
      final row = getRow(y);
      for (int x = 0; x < size.width; x++) {
        final cell = row[x];
        if (cell.changed) {
          if (cell.extension != null) {
            // TODO
            continue;
          }
          if (cell.calculateDifference()) {
            cell.changed = false;
          }
        }
      }
    }
    onChanged();
  }
}
