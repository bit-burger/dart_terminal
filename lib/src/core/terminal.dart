// Project imports:
import 'geometry.dart';
import 'graphics.dart';
import 'style.dart';
import 'util.dart';

/// Service for creating and managing terminal windows and associated objects.
///
/// Provides an abstract interface for terminal operations, allowing for different
/// implementations depending on the underlying platform or terminal capabilities.
abstract class TerminalService {
  /// Initializes the terminal service.
  bool _isAttached = false;
  bool _isDestroyed = false;

  Future<void> attach() async {
    if (_isDestroyed) {
      throw StateError(
        "TerminalWindow is already destroyed, cannot attach again.",
      );
    }
    _isAttached = true;
    logger._isActive = true;
  }

  // TODO: do not destroy but attach and unattach
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

  TerminalListener? listener;

  TerminalLogger get logger;
  TerminalViewport get viewport;

  void switchToLoggerMode() {
    logger._isActive = true;
    viewport._isActive = false;
  }

  void switchToViewPortMode() {
    logger._isActive = false;
    viewport._isActive = true;
  }

  TerminalImage createImage({
    required Size size,
    String? filePath,
    TerminalColor? backgroundColor,
  });

  /// Checks if a specific capability is supported by the terminal.
  CapabilitySupport checkSupport(Capability capability);

  /// Tries to set the terminal size, adjusting if necessary.
  void trySetTerminalSize(Size size);

  /// Sets the terminal window title.
  void setTerminalTitle(String title);

  /// Triggers the terminal bell (audible or visible alert).
  void bell();
}

abstract class TerminalLogger {
  bool get isActive => _isActive;
  bool _isActive = false;

  // TODO: remove from public api
  TerminalService get service;

  int get width;

  void deleteLastLine(int count);

  void log(
    String text, {
    TerminalForegroundStyle foregroundStyle,
    TerminalColor backgroundColor,
  });
}

/// Abstract class for terminal windows.
///
/// Represents a window in the terminal where content can be displayed.
/// Supports features like cursor management, screen updating, and event handling.
abstract class TerminalViewport implements TerminalCanvas {
  bool get isActive => _isActive;
  bool _isActive = false;

  TerminalService get service;

  CursorState? get cursor;
  set cursor(CursorState state);

  /// Draws the background of the terminal window.
  void drawBackground({TerminalColor color, bool optimizeByClear = true});

  @override
  void drawBorderBox({
    required Rect rect,
    required BorderCharSet style,
    TerminalColor color = const DefaultTerminalColor(),
    BorderDrawIdentifier? drawId,
  }) {
    assert(rect.height > 1 && rect.width > 1, "Rect needs to be at least 2x2.");
  }

  @override
  void drawBorderLine({
    required Position from,
    required Position to,
    required BorderCharSet style,
    TerminalColor color = const DefaultTerminalColor(),
    BorderDrawIdentifier? drawId,
  }) {
    assert(
      from.x == to.x || from.y == to.y,
      "Points need to be either horizontally or vertically aligned.",
    );
    assert(from != to, "Points need to be different.");
  }

  void drawImage({
    required covariant TerminalImage image,
    required Position position,
  });

  /// Updates the terminal screen with any pending changes.
  void updateScreen();
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
  /// (only available in viewport mode)
  void mouseEvent(MouseEvent event);

  /// Called when the terminal gains or loses focus.
  void focusChange(bool isFocused);

  /// Creates a delegate that forwards events to the provided handlers.
  factory TerminalListener({
    void Function(ControlCharacter) onControlCharacter,
    void Function(bool) onFocusChange,
    void Function(String) onInput,
    void Function(MouseEvent) onMouseEvent,
    void Function(Size) onScreenResize,
    void Function(AllowedSignal) onSignal,
  }) = LambdaTerminalListener;
}

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

  /// If an alternate screen buffer is available or if for the viewport everything needs to be redrawn
  alternateScreenBuffer,

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
