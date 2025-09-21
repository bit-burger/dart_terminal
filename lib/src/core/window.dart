import 'geometry.dart';
import 'graphics.dart';
import 'style.dart';


// TODO: rename file to terminal.dart
/// Service for creating and managing terminal windows and associated objects.
///
/// Provides an abstract interface for terminal operations, allowing for different
/// implementations depending on the underlying platform or terminal capabilities.
abstract class TerminalService {
  /// Initializes the terminal service, .
  Future<void> init();

  /// Creates a new terminal window with an optional event listener.
  TerminalWindow createWindow({TerminalListener listener});

  /// Creates a terminal image with the specified properties.
  ///
  /// [size] determines the dimensions of the image.
  /// [filePath] optionally specifies an image file to load.
  /// [backgroundColor] sets the default background color.
  TerminalImage createImage({
    required Size size,
    String? filePath,
    TerminalColor? backgroundColor,
  });
}

/// System signals that can be handled by the terminal application.
///
/// These signals correspond to standard POSIX signals that the application
/// may need to respond to.
enum AllowedSignal {
  /// Hangup detected on controlling terminal
  sighup,

  /// Interrupt from keyboard (Ctrl+C)
  sigint,

  /// Termination signal
  sigterm,

  /// User-defined signal 1
  sigusr1,

  /// User-defined signal 2
  sigusr2,
}

/// Control characters and special keys that can be received as input.
///
/// These represent both standard control characters (Ctrl+key combinations)
/// and special keys like arrows and function keys.
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
  /// Navigation keys
  arrowLeft,
  arrowRight,
  arrowUp,
  arrowDown,
  pageUp,
  pageDown,
  wordLeft,
  wordRight,

  /// Editing keys
  home,
  end,
  escape,
  delete,
  wordBackspace,

  /// Function keys F1-F4 (TODO: extend to F12)
  F1,
  F2,
  F3,
  F4,
}

/// Base class for mouse events in the terminal.
///
/// Provides common properties for all mouse-related events including
/// modifier key states and cursor position.
sealed class MouseEvent {
  /// Whether the shift key was pressed during the event
  final bool shiftKeyPressed;

  /// Whether the meta (command/windows) key was pressed
  final bool metaKeyPressed;

  /// Whether the control key was pressed
  final bool ctrlKeyPressed;

  /// The position of the mouse cursor when the event occurred
  final Position position;

  const MouseEvent(
    this.shiftKeyPressed,
    this.metaKeyPressed,
    this.ctrlKeyPressed,
    this.position,
  );
}

/// Represents a mouse button press or release event.
///
/// Includes information about which button was involved and the type of press.
final class MousePressEvent extends MouseEvent {
  /// The mouse button that triggered the event
  final MouseButton button;

  /// The type of press event (click, double-click, etc)
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

/// Represents mouse movement without button presses.
///
/// Used for tracking mouse position during hover operations.
final class MouseHoverEvent extends MouseEvent {
  const MouseHoverEvent(
    super.shiftKeyPressed,
    super.metaKeyPressed,
    super.ctrlKeyPressed,
    super.position,
  );
}

/// Represents mouse wheel scrolling.
///
/// Contains information about the scroll amount in both x and y directions.
final class MouseScrollEvent extends MouseEvent {
  /// The amount of scrolling in the x direction
  final int xScroll;

  /// The amount of scrolling in the y direction
  final int yScroll;

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

/// Interface for handling terminal events.
///
/// Implement this interface to receive events from the terminal such as
/// input, screen resizes, and signal interruptions.
abstract interface class TerminalListener {
  /// Called when the terminal screen is resized.
  void screenResize(Size size);

  /// Called when there is input from the user.
  void input(String s);

  /// Called for control characters like Ctrl+C.
  void controlCharacter(ControlCharacter controlCharacter);

  /// Called when the terminal receives a system signal.
  void signal(AllowedSignal signal);

  /// Called for mouse events like clicks and movement.
  void mouseEvent(MouseEvent event);

  /// Called when the terminal gains or loses focus.
  void focusChange(bool isFocused);

  /// Creates a delegate that forwards events to the provided handlers.
  const factory TerminalListener.delegate({
    void Function(ControlCharacter) controlCharacter,
    void Function(bool) focusChange,
    void Function(String) input,
    void Function(MouseEvent) mouseEvent,
    void Function(Size) screenResize,
    void Function(AllowedSignal) signal,
  }) = _LambdaTerminalListener;

  /// Creates an empty terminal listener that ignores all events.
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

/// Support levels for terminal capabilities.
///
/// Used to indicate whether a specific capability is supported, unsupported,
/// or somewhere in between.
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

/// List of terminal capabilities.
///
/// These capabilities represent various features and options that may be
/// supported by the terminal, such as color support and mouse event handling.
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

/// Represents the state of the text cursor.
///
/// Includes the cursor's position and whether it is currently blinking.
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

/// Abstract class for terminal windows.
///
/// Represents a window in the terminal where content can be displayed.
/// Supports features like cursor management, screen updating, and event handling.
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

  /// Checks if a specific capability is supported by the terminal.
  CapabilitySupport checkSupport(Capability capability);

  /// Tries to set the terminal size, adjusting if necessary.
  void trySetTerminalSize(Size size);

  /// Sets the terminal window title.
  void setTerminalTitle(String title);

  /// Triggers the terminal bell (audible or visible alert).
  void bell();

  /// Draws the background of the terminal window.
  void drawBackground({TerminalColor color});

  /// Updates the terminal screen with any pending changes.
  void updateScreen();
}

/// Abstract class for terminal canvases with clipping support.
///
/// Extends [TerminalCanvas] to add rectangular clipping regions,
/// allowing for optimized redrawing of only a portion of the terminal.
abstract class TerminalClipCanvas extends TerminalCanvas {
  /// The current clipping rectangle, if any
  Rect? clip;
}
