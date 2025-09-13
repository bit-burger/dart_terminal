import 'dart:math' show min, max;

import 'package:dart_tui/core/style.dart';

abstract class TerminalWindowFactory {
  TerminalWindow createWindow();
}

enum AllowedSignal { sighup, sigint, sigterm, sigusr1, sigusr2 }

enum ControlCharacter {
  ctrlA,
  ctrlB,
  ctrlC, // Break
  ctrlD, // End of File
  ctrlE,
  ctrlF,
  ctrlG, // Bell
  ctrlH, // Backspace
  tab,
  ctrlJ,
  ctrlK,
  ctrlL,
  enter,
  ctrlN,
  ctrlO,
  ctrlP,
  ctrlQ,
  ctrlR,
  ctrlS,
  ctrlT,
  ctrlU,
  ctrlV,
  ctrlW,
  ctrlX,
  ctrlY,
  ctrlZ, // Suspend

  arrowLeft,
  arrowRight,
  arrowUp,
  arrowDown,
  pageUp,
  pageDown,
  wordLeft,
  wordRight,

  home,
  end,
  escape,
  delete,
  wordBackspace,

  // ignore: constant_identifier_names
  F1,
  // ignore: constant_identifier_names
  F2,
  // ignore: constant_identifier_names
  F3,
  // ignore: constant_identifier_names
  F4,
}

sealed class MouseEvent {
  final bool shiftKeyPressed, metaKeyPressed, ctrlKeyPressed;
  final Position position;

  const MouseEvent(
    this.shiftKeyPressed,
    this.metaKeyPressed,
    this.ctrlKeyPressed,
    this.position,
  );
}

final class MouseButtonPressEvent extends MouseEvent {
  final MouseButton button;
  final MouseButtonPressEventType pressType;
  const MouseButtonPressEvent(
    super.shiftKeyPressed,
    super.metaKeyPressed,
    super.ctrlKeyPressed,
    super.position,
    this.button,
    this.pressType,
  );
}

final class MouseHoverMotionEvent extends MouseEvent {
  const MouseHoverMotionEvent(
    super.shiftKeyPressed,
    super.metaKeyPressed,
    super.ctrlKeyPressed,
    super.position,
  );
}

final class MouseScrollEvent extends MouseEvent {
  final int xScroll, yScroll;
  const MouseScrollEvent(
    super.shiftKeyPressed,
    super.metaKeyPressed,
    super.ctrlKeyPressed,
    super.position,
    this.xScroll,
    this.yScroll,
  );
}

/// Note: button 4-7 are used for scrolling
enum MouseButton { left, right, middle, button8, button9, button10, button11 }

enum MouseButtonPressEventType { press, release }

abstract interface class TerminalListener {
  void screenResize(Size size);

  void input(String s);

  void controlCharacter(ControlCharacter controlCharacter);

  void signal(AllowedSignal signal);

  void mouseEvent(MouseEvent event);

  void focusChange(bool isFocused);

  factory TerminalListener.delegate({
    void Function(ControlCharacter) controlCharacter,
    void Function(bool) focusChange,
    void Function(String) input,
    void Function(MouseEvent) mouseEvent,
    void Function(Size) screenResize,
    void Function(AllowedSignal) signal,
  }) = _LambdaTerminalListener;
}

class _LambdaTerminalListener implements TerminalListener {
  final void Function(ControlCharacter) _controlCharacter;
  final void Function(bool) _focusChange;
  final void Function(String) _input;
  final void Function(MouseEvent) _mouseEvent;
  final void Function(Size) _screenResize;
  final void Function(AllowedSignal) _signal;

  static void _(_) {}

  const _LambdaTerminalListener({
    void Function(ControlCharacter) controlCharacter = _,
    void Function(bool) focusChange = _,
    void Function(String) input = _,
    void Function(MouseEvent) mouseEvent = _,
    void Function(Size) screenResize = _,
    void Function(AllowedSignal) signal = _,
  }) : _controlCharacter = controlCharacter,
       _focusChange = focusChange,
       _input = input,
       _mouseEvent = mouseEvent,
       _screenResize = screenResize,
       _signal = signal;

  @override
  void controlCharacter(ControlCharacter controlCharacter) =>
      _controlCharacter(controlCharacter);

  @override
  void focusChange(bool isFocused) => _focusChange(isFocused);

  @override
  void input(String s) => _input(s);

  @override
  void mouseEvent(MouseEvent event) => _mouseEvent(event);

  @override
  void screenResize(Size size) => _screenResize(size);

  @override
  void signal(AllowedSignal signal) => _signal(signal);
}

class DefaultTerminalListener implements TerminalListener {
  const DefaultTerminalListener();

  @override
  void controlCharacter(ControlCharacter controlCharacter) {}

  @override
  void input(String s) {}

  @override
  void screenResize(Size size) {}

  @override
  void signal(AllowedSignal signal) {}

  @override
  void focusChange(bool isFocused) {}

  @override
  void mouseEvent(MouseEvent event) {}
}

class TerminalNotSupportedException extends Error {}

enum TerminalCapability {
  /// Support for [BasicTerminalColor]
  basicColors,

  /// Support for [XTermTerminalColor]
  extendedColors,

  /// Support for [RGBTerminalColor]
  trueColors,

  /// Support for [TerminalListener.mouseEvent]
  mouse,

  /// Support for at least [TextDecorationSet.slowBlink]
  /// and possibly [TextDecorationSet.fastBlink]
  textBlink,

  /// Support for [TextDecorationSet.intense]
  intense,

  /// Support for [TextDecorationSet.faint]
  faint,

  /// Support for [TextDecorationSet.italic]
  italic,

  /// Support for [TextDecorationSet.underline]
  underline,

  /// Support for [TextDecorationSet.doubleUnderline]
  doubleUnderline,

  /// Support for [TextDecorationSet.crossedOut]
  crossedOut,
}

abstract class TerminalWindow implements TerminalCanvas {
  final TerminalListener listener;
  bool _isAttached = true;
  bool _isDestroyed = false;

  TerminalWindow({required this.listener});

  Position? get cursorPosition;

  // also handle sigint etc...
  // raw scroll mode and stuff like that
  Future<void> attach() async {
    if (_isDestroyed) {
      throw StateError(
        "TerminalWindow is already destroyed, cannot attach again.",
      );
    }
    _isAttached = true;
  }

  Future<void> destroy() async {
    if (_isDestroyed) {
      throw StateError(
        "TerminalWindow is already destroyed, cannot destroy again.",
      );
    }
    if (!_isAttached) {
      throw StateError("TerminalWindow has not been attached, cannot destroy.");
    }
    _isDestroyed = true;
  }

  bool supportsCapability(TerminalCapability capability);

  void setCursor([Position? position]);
  void setTerminalSize(Size size);
  void setTerminalTitle(String title);
  void bell();
  void clearScreen();
  void updateScreen();
}

extension type const Size._(({int width, int height}) _) {
  const Size(int width, int height) : this._((width: width, height: height));
  int get width => _.width;
  int get height => _.height;
}

extension type const Position._(({int x, int y}) _) {
  const Position(int x, int y) : this._((x: x, y: y));

  static const Position zero = Position(0, 0);

  Rect operator &(Size size) =>
      Rect(x, x + size.width - 1, y, y + size.height - 1);

  int get x => _.x;
  int get y => _.y;
}

extension type const Rect._(({int x1, int x2, int y1, int y2}) _) {
  const Rect(int x1, int x2, int y1, int y2)
    : this._((x1: x1, x2: x2, y1: y1, y2: y2));

  int get width => _.x2 - _.x1 + 1;
  int get height => _.y2 - _.y1 + 1;
  Size get size => Size(width, height);
  int get x1 => _.x1;
  int get x2 => _.x2;
  int get y1 => _.y1;
  int get y2 => _.y2;

  Rect clip(Rect clip) => Rect(
    max(_.x1, clip.x1),
    min(_.x2, clip.x2),
    max(_.y1, clip.y1),
    min(_.y2, clip.y2),
  );

  bool contains(Position position) =>
      _.x1 <= position.x &&
      _.x2 >= position.x &&
      _.y1 <= position.y &&
      _.y2 >= position.y;
}

extension type const TerminalForegroundStyle._(
  ({TerminalColor color, TextDecorationSet textDecorations}) _
) {
  const TerminalForegroundStyle({
    TerminalColor color = const DefaultTerminalColor(),
    TextDecorationSet textDecorations = const TextDecorationSet.empty(),
  }) : this._((color: color, textDecorations: textDecorations));

  TerminalColor get color => _.color;
  TextDecorationSet get textDecorations => _.textDecorations;
}

extension type const TerminalForeground._(
  ({TerminalForegroundStyle style, int codePoint}) _
) {
  const TerminalForeground({
    TerminalForegroundStyle style = const TerminalForegroundStyle(),
    int codePoint = 32,
  }) : this._((style: style, codePoint: codePoint));

  TerminalForegroundStyle get style => _.style;
  int get codePoint => _.codePoint;
}

abstract class TerminalClipCanvas extends TerminalCanvas {
  Rect? clip;
}

abstract class TerminalCanvas {
  Size get size;

  void drawString({
    required String text,
    required Position position,
    TerminalForegroundStyle? style,
  });

  void drawRect({
    required Rect rect,
    TerminalColor? background,
    TerminalForeground? foreground,
  });

  void drawPoint({
    required Position position,
    TerminalColor? background,
    TerminalForeground? foreground,
  });
}
