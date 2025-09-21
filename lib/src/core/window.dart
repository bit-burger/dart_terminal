import 'geometry.dart';
import 'graphics.dart';
import 'style.dart';

abstract class TerminalWindowFactory {
  TerminalWindow createWindow({TerminalListener listener});

  TerminalImage createImage({
    required Size size,
    String? filePath,
    TerminalColor? backgroundColor,
  });
}

enum AllowedSignal { sighup, sigint, sigterm, sigusr1, sigusr2 }

enum ControlCharacter {
  ctrlSpace, // NULL
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

  // TODO: interpret these correctly (until F12)
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

final class MousePressEvent extends MouseEvent {
  final MouseButton button;
  final MousePressEventType pressType;
  const MousePressEvent(
    super.shiftKeyPressed,
    super.metaKeyPressed,
    super.ctrlKeyPressed,
    super.position,
    this.button,
    this.pressType,
  );
}

final class MouseHoverEvent extends MouseEvent {
  const MouseHoverEvent(
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

enum MousePressEventType { press, release }

abstract interface class TerminalListener {
  void screenResize(Size size);

  void input(String s);

  void controlCharacter(ControlCharacter controlCharacter);

  void signal(AllowedSignal signal);

  void mouseEvent(MouseEvent event);

  void focusChange(bool isFocused);

  const factory TerminalListener.delegate({
    void Function(ControlCharacter) controlCharacter,
    void Function(bool) focusChange,
    void Function(String) input,
    void Function(MouseEvent) mouseEvent,
    void Function(Size) screenResize,
    void Function(AllowedSignal) signal,
  }) = _LambdaTerminalListener;

  const factory TerminalListener.empty() = DefaultTerminalListener;
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

enum CapabilitySupport implements Comparable<CapabilitySupport> {
  /// if a capability is very likely to be unsupported
  unsupported,

  /// if there is no information on if a capability is supported or not
  unknown,

  /// features that might work
  assumed,

  /// features that will work with high degree of reliability
  supported;

  @override
  int compareTo(CapabilitySupport other) => index.compareTo(other.index);
}

enum Capability {
  /// Support for [BasicTerminalColor]
  basicColors,

  /// Support for [XTermTerminalColor]
  extendedColors,

  /// Support for [RGBTerminalColor]
  trueColors,

  /// Support for [TerminalListener.mouseEvent]
  mouse,

  /// Support for setting [CursorState.blinking] to false
  cursorBlinkingDisable,

  /// Support for [TextDecorationSet.intense]
  intenseTextDecoration,

  /// Support for [TextDecorationSet.italic]
  italicTextDecoration,

  /// Support for [TextDecorationSet.underline]
  underlineTextDecoration,

  /// Support for [TextDecorationSet.doubleUnderline]
  doubleUnderlineTextDecoration,

  /// Support for [TextDecorationSet.crossedOut]
  crossedOutTextDecoration,

  /// Support for [TextDecorationSet.faint]
  faintTextDecoration,

  /// Support for at least [TextDecorationSet.slowBlink]
  /// and possibly [TextDecorationSet.fastBlink]
  textBlinkTextDecoration,
}

final class CursorState {
  final Position position;
  final bool blinking;

  CursorState({required this.position, this.blinking = true});

  @override
  bool operator ==(Object other) =>
      other is CursorState &&
      position == other.position &&
      blinking == other.blinking;

  @override
  int get hashCode => Object.hash(position.hashCode, blinking);
}

abstract class TerminalWindow implements TerminalCanvas {
  final TerminalListener listener;
  bool _isAttached = true;
  bool _isDestroyed = false;

  TerminalWindow({required this.listener});

  CursorState? get cursor;
  set cursor(CursorState state);

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

  CapabilitySupport checkSupport(Capability capability);

  void trySetTerminalSize(Size size);
  void setTerminalTitle(String title);
  void bell();
  void drawBackground({TerminalColor color});
  void updateScreen();
}

abstract class TerminalClipCanvas extends TerminalCanvas {
  Rect? clip;
}
