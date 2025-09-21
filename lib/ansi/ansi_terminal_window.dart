import 'dart:async';
import 'dart:io' as io;

import 'package:dart_tui/ansi/ansi_terminal_input_processor.dart';
import 'package:dart_tui/ansi/ansi_terminal_screen.dart';
import 'package:dart_tui/ansi/terminal_capabilities.dart';
import 'package:dart_tui/ansi/terminal_size_tracker.dart';

import '../core/style.dart';
import '../core/terminal.dart';
import 'ansi_terminal_controller.dart';
import 'native_terminal_image.dart';

class AnsiTerminalWindowFactory extends TerminalWindowFactory {
  final TerminalCapabilitiesDetector _capabilitiesDetector;
  final TerminalSizeTracker _sizeTracker;

  AnsiTerminalWindowFactory({
    required TerminalCapabilitiesDetector capabilitiesDetector,
    required TerminalSizeTracker sizeTracker,
  }) : _sizeTracker = sizeTracker,
       _capabilitiesDetector = capabilitiesDetector;

  factory AnsiTerminalWindowFactory.agnostic({
    Duration? terminalSizePollingInterval,
  }) {
    final capabilitiesDetector = TerminalCapabilitiesDetector.agnostic();
    final sizeTracker = TerminalSizeTracker.agnostic(
      pollingInterval:
          terminalSizePollingInterval ?? Duration(milliseconds: 50),
    );
    return AnsiTerminalWindowFactory(
      capabilitiesDetector: capabilitiesDetector,
      sizeTracker: sizeTracker,
    );
  }

  @override
  AnsiTerminalWindow createWindow({
    TerminalListener listener = const TerminalListener.empty(),
  }) => AnsiTerminalWindow(
    capabilitiesDetector: _capabilitiesDetector,
    sizeTracker: _sizeTracker,
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
}

extension on AllowedSignal {
  io.ProcessSignal processSignal() {
    switch (this) {
      case AllowedSignal.sighup:
        return io.ProcessSignal.sighup;
      case AllowedSignal.sigint:
        return io.ProcessSignal.sigint;
      case AllowedSignal.sigterm:
        return io.ProcessSignal.sigterm;
      case AllowedSignal.sigusr1:
        return io.ProcessSignal.sigusr1;
      case AllowedSignal.sigusr2:
        return io.ProcessSignal.sigusr2;
    }
  }
}

class AnsiTerminalWindow extends TerminalWindow {
  final TerminalCapabilitiesDetector capabilitiesDetector;
  final TerminalSizeTracker sizeTracker;
  final AnsiTerminalController controller = AnsiTerminalController();
  final AnsiTerminalInputProcessor inputProcessor =
      AnsiTerminalInputProcessor.waiting();
  late final AnsiTerminalScreen _screen;

  final List<StreamSubscription> _subscriptions = [];
  Completer<Position>? _cursorPositionCompleter;

  @override
  CursorState? get cursor => _cursorPosition == null
      ? null
      : CursorState(position: _cursorPosition!, blinking: _cursorBlinking);
  bool _cursorBlinking = true;
  late Position? _cursorPosition;

  @override
  Size get size => sizeTracker.currentSize;

  AnsiTerminalWindow({
    required this.capabilitiesDetector,
    required this.sizeTracker,
    required TerminalListener listener,
  }) : super(listener: listener);

  factory AnsiTerminalWindow.agnostic({
    TerminalListener listener = const TerminalListener.empty(),
    Duration? terminalSizePollingInterval,
  }) => AnsiTerminalWindowFactory.agnostic(
    terminalSizePollingInterval: terminalSizePollingInterval,
  ).createWindow(listener: listener);

  Future<Position> _getCursorPosition() {
    controller.queryCursorPosition();
    _cursorPositionCompleter = Completer<Position>();
    return _cursorPositionCompleter!.future;
  }

  @override
  Future<void> attach() async {
    await super.attach();
    await capabilitiesDetector.detect();
    controller
      ..saveCursorPosition()
      ..changeScreenMode(alternateBuffer: true)
      ..changeFocusTrackingMode(enable: true)
      ..changeMouseTrackingMode(enable: true)
      ..changeLineWrappingMode(enable: false);
    inputProcessor
      ..startListening()
      ..listener = _onInputEvent;
    for (final signal in AllowedSignal.values) {
      _subscriptions.add(
        signal.processSignal().watch().listen((_) {
          listener.signal(signal);
        }),
      );
    }
    sizeTracker
      ..startTracking()
      ..listener = _onResizeEvent;
    controller.setInputMode(true);
    _cursorPosition = await _getCursorPosition();
    _screen = AnsiTerminalScreen(size)..initScreen();
  }

  @override
  Future<void> destroy() async {
    await super.destroy();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    inputProcessor.stopListening();
    sizeTracker.stopTracking();
    _screen.initScreen();
    controller
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
  void bell() => controller.bell();

  @override
  void trySetTerminalSize(Size size) =>
      controller.changeSize(size.width, size.height);

  @override
  void setTerminalTitle(String title) => controller.changeTerminalTitle(title);

  @override
  set cursor(CursorState? cursor) {
    if (cursor != null) {
      if (cursor.blinking != _cursorBlinking) {
        controller.changeCursorBlinking(blinking: cursor.blinking);
        _cursorBlinking = cursor.blinking;
      }
      if (cursor.position != _cursorPosition) {
        if (_cursorPosition == null) {
          controller.changeCursorVisibility(hiding: false);
        }
        controller.setCursorPosition(
          cursor.position.x + 1,
          cursor.position.y + 1,
        );
        _cursorPosition = cursor.position;
      }
    } else if (_cursorPosition != null) {
      controller.changeCursorVisibility(hiding: true);
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
      controller.setCursorPosition(
        cursor!.position.x + 1,
        cursor!.position.y + 1,
      );
    }
  }

  @override
  CapabilitySupport checkSupport(Capability capability) {
    if (capabilitiesDetector.supportedCaps.contains(capability)) {
      return CapabilitySupport.supported;
    }
    if (capabilitiesDetector.assumedCaps.contains(capability)) {
      return CapabilitySupport.assumed;
    }
    if (capabilitiesDetector.unsupportedCaps.contains(capability)) {
      return CapabilitySupport.unsupported;
    }
    return CapabilitySupport.unknown;
  }
}
