import '../../style/style.dart';

class _Pixel {
  int charCode = 10;
      bool changed = false;
  int backgroundHeight = 0;
      int foregroundHeight = 0,
  TerminalColor backgroundColor = 0,
      ForegroundStyle foregroundStyle = 0,
}

class ScreenBuffer {
  int _width, _height;
  int _bufferWidth, _bufferHeight;

  final List<
      List<
          (
            int charCode,
            bool changed,
            int backgroundHeight,
            int foregroundHeight,
            TerminalColor backgroundColor,
            ForegroundStyle foregroundStyle,
          )>> _data;

  ScreenBuffer(int width, int height)
      : _width = width,
        _height = height,
        _bufferWidth = width,
        _bufferHeight = height,
        _data = List.generate(
          height,
          (_) => List.generate(
            width,
            (_) => (
              10,
              false,
              0,
              0,
              const DefaultTerminalColor(),
              ForegroundStyle.defaultStyle,
            ),
          ),
        );

  void changeSize(int newWidth, int newHeight) {
    _width = newWidth;
    _height = newHeight;
    if (_width > _bufferWidth) {

    }
    if (_height > _bufferHeight) {

    }
  }
}
