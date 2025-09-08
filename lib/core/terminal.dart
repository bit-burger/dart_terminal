import 'package:dart_tui/core/style.dart';

abstract class TerminalWindowFactory {
  TerminalWindow createWindow();
}

enum AllowedSignal {
  sighup,
  sigint,
  sigterm,
  sigusr1,
  sigusr2;
}

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

  const MouseEvent(this.shiftKeyPressed, this.metaKeyPressed,
      this.ctrlKeyPressed, this.position);
}

final class MouseButtonPressEvent extends MouseEvent {
  final MouseButton button;
  final MouseButtonPressEventType pressType;
  const MouseButtonPressEvent(super.shiftKeyPressed, super.metaKeyPressed,
      super.ctrlKeyPressed, super.position, this.button, this.pressType);
}

final class MouseHoverMotionEvent extends MouseEvent {
  const MouseHoverMotionEvent(super.shiftKeyPressed, super.metaKeyPressed,
      super.ctrlKeyPressed, super.position);
}

final class MouseScrollEvent extends MouseEvent {
  final int xScroll, yScroll;
  const MouseScrollEvent(super.shiftKeyPressed, super.metaKeyPressed,
      super.ctrlKeyPressed, super.position, this.xScroll, this.yScroll);
}

/// Note: button 4-7 are used for scrolling
enum MouseButton { left, right, middle, button8, button9, button10, button11 }

enum MouseButtonPressEventType { press, release }

abstract class TerminalInputListener {
  void screenResize(Size size);

  void input(String s);

  void controlCharacter(ControlCharacter controlCharacter);

  void signal(AllowedSignal signal);

  void mouseEvent(MouseEvent event);

  void focusChange(bool isFocused);
}

class DefaultTerminalInputListener extends TerminalInputListener {
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

abstract class TerminalWindow implements TerminalCanvas {
  List<TerminalInputListener> listeners = [];

  Position get cursorPosition;

  // also handle sigint etc...
  // raw scroll mode and stuff like that
  Future<void> attach();

  Future<void> destroy();

  void addListener(TerminalInputListener listener) {
    listeners.add(listener);
  }

  void removeListener(TerminalInputListener listener) {
    listeners.remove(listener);
  }

  void changeCursorVisibility({required bool hiding});
  void changeTerminalSize(Size size);
  void changeTerminalTitle(String title);
  void changeCursorPosition(Position position);
  void bell();
  void writeToScreen();
}

typedef Size = ({int height, int width});
typedef Position = ({int x, int y});
typedef Rect = ({int x1, int x2, int y1, int y2});
typedef TerminalForegroundStyle = ({
  TerminalColor color,
  TextDecorationSet textDecorations,
});
typedef TerminalForeground = ({
  TerminalForegroundStyle style,
  int codepoint,
});

abstract class TerminalClipCanvas extends TerminalCanvas {
  Rect? clip;
}

abstract class TerminalCanvas {
  Size get size;

  void drawString({
    required String text,
    required Position position,
  });

  void drawRect({
    required Rect rect,
    TerminalColor? background,
    TerminalForegroundStyle? foreground,
  });

  void drawPoint({
    required Position position,
    TerminalColor? background,
    TerminalForeground? foreground,
  });
}
