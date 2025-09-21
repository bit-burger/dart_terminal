import 'dart:async' as async;
import 'package:dart_tui/core.dart';
import '../shared/native_terminal_image.dart';
import '../shared/signals.dart';
import '../shared/terminal_capabilities.dart';
import '../shared/terminal_size_tracker.dart';
import 'ansi_terminal_controller.dart';
import 'ansi_terminal_input_processor.dart';
import 'ansi_terminal_screen.dart';

/// Factory for creating ANSI-compatible terminal windows.
///
///
class AnsiTerminalService extends TerminalService {
  /// Detector for terminal capabilities
  final TerminalCapabilitiesDetector capabilitiesDetector;

  /// Tracker for terminal window size changes
  final TerminalSizeTracker sizeTracker;

  /// Creates a new factory with specific capability detection and size tracking.
  AnsiTerminalService({
    required this.capabilitiesDetector,
    required this.sizeTracker,
  });

  /// Creates a factory with automatic configuration
  /// corresponding to the current platform.
  ///
  /// This factory method provides sensible defaults for most use cases:
  /// - Automatically detects terminal capabilities
  /// - Sets up appropriate size tracking for the
  factory AnsiTerminalService.agnostic({
    Duration? terminalSizePollingInterval,
  }) {
    final capabilitiesDetector = TerminalCapabilitiesDetector.agnostic();
    final sizeTracker = TerminalSizeTracker.agnostic(
      pollingInterval:
          terminalSizePollingInterval ?? Duration(milliseconds: 50),
    );
    return AnsiTerminalService(
      capabilitiesDetector: capabilitiesDetector,
      sizeTracker: sizeTracker,
    );
  }

  @override
  AnsiTerminalWindow createWindow({
    TerminalListener listener = const TerminalListener.empty(),
  }) => AnsiTerminalWindow(
    capabilitiesDetector: capabilitiesDetector,
    sizeTracker: sizeTracker,
    listener: listener,
  );

  @override
  NativeTerminalImage createImage({
    required Size size,
    String? filePath,
    TerminalColor? backgroundColor,
  }) {
    if (filePath != null) {
      return NativeTerminalImage.fromPath(
        size: size,
        path: filePath,
        backgroundColor: backgroundColor,
      );
    }
    return NativeTerminalImage.filled(size, backgroundColor);
  }

  @override
  async.Future<void> init() {
    // TODO: implement init
    throw UnimplementedError();
  }
}

/// ANSI terminal window implementation.
///
/// This class represents an ANSI terminal window, providing methods to manipulate
/// the terminal screen, handle input events, and manage cursor state. It uses
/// ANSI escape sequences to perform operations in the terminal.
class AnsiTerminalWindow extends TerminalWindow {
  final TerminalCapabilitiesDetector _capabilitiesDetector;
  final TerminalSizeTracker _sizeTracker;
  final AnsiTerminalController _controller = AnsiTerminalController();
  final AnsiTerminalInputProcessor _inputProcessor =
      AnsiTerminalInputProcessor.waiting();
  late final AnsiTerminalScreen _screen;

  final List<async.StreamSubscription<Object>> _subscriptions = [];
  async.Completer<Position>? _cursorPositionCompleter;

  @override
  CursorState? get cursor => _cursorPosition == null
      ? null
      : CursorState(position: _cursorPosition!, blinking: _cursorBlinking);
  bool _cursorBlinking = true;
  late Position? _cursorPosition;

  @override
  Size get size => _sizeTracker.currentSize;

  /// Creates a new ANSI terminal window with specified capability detection,
  /// size tracking, and event listener.
  ///
  /// The [capabilitiesDetector] is used to determine the terminal's supported
  /// features. The [sizeTracker] is responsible for monitoring terminal size
  /// changes. The [listener] can be set to handle input and signal events.
  ///
  /// Use the [AnsiTerminalWindowFactory.agnostic] factory method for automatic
  /// platform detection and configuration.
  AnsiTerminalWindow({
    required TerminalCapabilitiesDetector capabilitiesDetector,
    required TerminalSizeTracker sizeTracker,
    required TerminalListener listener,
  }) : _sizeTracker = sizeTracker,
       _capabilitiesDetector = capabilitiesDetector,
       super(listener: listener);

  /// Creates an ANSI terminal window with automatic platform detection and
  /// configuration.
  ///
  /// Uses the same configuration options as the
  /// [AnsiTerminalWindowFactory.agnostic] factory.
  factory AnsiTerminalWindow.agnostic({
    TerminalListener listener = const TerminalListener.empty(),
    Duration? terminalSizePollingInterval,
  }) => AnsiTerminalService.agnostic(
    terminalSizePollingInterval: terminalSizePollingInterval,
  ).createWindow(listener: listener);

  Future<Position> _getCursorPosition() {
    _controller.queryCursorPosition();
    _cursorPositionCompleter = async.Completer<Position>();
    return _cursorPositionCompleter!.future;
  }

  @override
  Future<void> attach() async {
    await super.attach();
    await _capabilitiesDetector.detect();
    _controller
      ..saveCursorPosition()
      ..changeScreenMode(alternateBuffer: true)
      ..changeFocusTrackingMode(enable: true)
      ..changeMouseTrackingMode(enable: true)
      ..changeLineWrappingMode(enable: false);
    _inputProcessor
      ..startListening()
      ..listener = _onInputEvent;
    for (final signal in AllowedSignal.values) {
      _subscriptions.add(
        signal.processSignal().watch().listen((_) {
          listener.signal(signal);
        }),
      );
    }
    _sizeTracker
      ..startTracking()
      ..listener = _onResizeEvent;
    _controller.setInputMode(true);
    _cursorPosition = await _getCursorPosition();
    _screen = AnsiTerminalScreen(size)..initScreen();
  }

  @override
  Future<void> destroy() async {
    await super.destroy();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _inputProcessor.stopListening();
    _sizeTracker.stopTracking();
    _screen.initScreen();
    _controller
      ..setInputMode(false)
      ..changeScreenMode(alternateBuffer: false)
      ..changeCursorVisibility(hiding: false)
      ..changeCursorBlinking(blinking: true)
      ..restoreCursorPosition()
      ..changeFocusTrackingMode(enable: false)
      ..changeMouseTrackingMode(enable: false)
      ..changeLineWrappingMode(enable: true);
    _cursorPositionCompleter?.complete(Position(0, 0));
  }

  void _onInputEvent(Object event) {
    if (event is CursorPositionEvent) {
      _cursorPositionCompleter?.complete(event.position);
      _cursorPositionCompleter = null;
    } else if (event is String) {
      listener.input(event);
    } else if (event is MouseEvent) {
      listener.mouseEvent(event);
    } else if (event is ControlCharacter) {
      listener.controlCharacter(event);
    } else if (event is FocusEvent) {
      listener.focusChange(event.isFocused);
    }
  }

  void _onResizeEvent() {
    /// TODO: optimization?
    _screen
      ..fillBackground()
      ..updateScreen()
      ..resize(size);
    listener.screenResize(size);
  }

  @override
  void bell() => _controller.bell();

  @override
  void trySetTerminalSize(Size size) =>
      _controller.changeSize(size.width, size.height);

  @override
  void setTerminalTitle(String title) => _controller.changeTerminalTitle(title);

  @override
  set cursor(CursorState? cursor) {
    if (cursor != null) {
      if (cursor.blinking != _cursorBlinking) {
        _controller.changeCursorBlinking(blinking: cursor.blinking);
        _cursorBlinking = cursor.blinking;
      }
      if (cursor.position != _cursorPosition) {
        if (_cursorPosition == null) {
          _controller.changeCursorVisibility(hiding: false);
        }
        _controller.setCursorPosition(
          cursor.position.x + 1,
          cursor.position.y + 1,
        );
        _cursorPosition = cursor.position;
      }
    } else if (_cursorPosition != null) {
      _controller.changeCursorVisibility(hiding: true);
      _cursorPosition = null;
    }
  }

  @override
  void drawPoint({
    required Position position,
    TerminalColor? background,
    TerminalForeground? foreground,
  }) => _screen.drawPoint(position, background, foreground);

  @override
  void drawRect({
    required Rect rect,
    TerminalColor? background,
    TerminalForeground? foreground,
  }) => _screen.drawRect(rect, background, foreground);

  @override
  void drawText({
    required String text,
    required Position position,
    TerminalForegroundStyle? style,
  }) => _screen.drawText(text, style, position);

  @override
  void drawBorderBox({
    required Rect rect,
    required BorderCharSet borderStyle,
    TerminalColor foregroundColor = const DefaultTerminalColor(),
    BorderDrawIdentifier? drawIdentifier,
  }) {
    drawIdentifier ??= BorderDrawIdentifier();
    assert(rect.height > 1 && rect.width > 1, "Rect needs to be at least 2x2.");
    _screen.drawBorderBox(rect, borderStyle, foregroundColor, drawIdentifier);
  }

  @override
  void drawBorderLine({
    required Position from,
    required Position to,
    required BorderCharSet borderStyle,
    TerminalColor foregroundColor = const DefaultTerminalColor(),
    BorderDrawIdentifier? drawIdentifier,
  }) {
    drawIdentifier ??= BorderDrawIdentifier();
    assert(
      from.x == to.x || from.y == to.y,
      "Points need to be either horizontally or vertically aligned.",
    );
    assert(from != to, "Points need to be different.");
    _screen.drawBorderLine(
      from,
      to,
      borderStyle,
      foregroundColor,
      drawIdentifier,
    );
  }

  @override
  void drawImage({
    required Position position,
    required NativeTerminalImage image,
  }) => _screen.drawImage(position, image);

  @override
  void drawBackground({
    TerminalColor color = const DefaultTerminalColor(),
    bool optimize = true,
  }) {
    if (optimize) {
      _screen.fillBackground(color);
    } else {
      _screen.drawRect(Position.zero & size, color, null);
    }
  }

  @override
  void updateScreen() {
    final cursorMoved = _screen.updateScreen();
    if (cursorMoved && cursor != null) {
      _controller.setCursorPosition(
        cursor!.position.x + 1,
        cursor!.position.y + 1,
      );
    }
  }

  @override
  CapabilitySupport checkSupport(Capability capability) {
    if (_capabilitiesDetector.supportedCaps.contains(capability)) {
      return CapabilitySupport.supported;
    }
    if (_capabilitiesDetector.assumedCaps.contains(capability)) {
      return CapabilitySupport.assumed;
    }
    if (_capabilitiesDetector.unsupportedCaps.contains(capability)) {
      return CapabilitySupport.unsupported;
    }
    return CapabilitySupport.unknown;
  }
}
