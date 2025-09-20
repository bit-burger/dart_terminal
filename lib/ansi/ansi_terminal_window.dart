import 'dart:async';
import 'dart:io' as io;

import 'package:dart_tui/ansi/ansi_terminal_screen.dart';
import 'package:dart_tui/ansi/terminal_capabilities.dart';
import 'package:dart_tui/ansi/terminal_size_tracker.dart';

import '../core/style.dart';
import '../core/terminal.dart';
import 'ansi_escape_codes.dart' as ansi_codes;
import 'ansi_terminal_controller.dart';
import 'native_terminal_image.dart';

class AnsiTerminalWindowFactory extends TerminalWindowFactory {
  final TerminalController _controller;
  final TerminalCapabilitiesDetector _capabilitiesDetector;
  final TerminalSizeTracker _sizeTracker;

  AnsiTerminalWindowFactory({
    required TerminalController controller,
    required TerminalCapabilitiesDetector capabilitiesDetector,
    required TerminalSizeTracker sizeTracker,
  }) : _controller = controller,
       _sizeTracker = sizeTracker,
       _capabilitiesDetector = capabilitiesDetector;

  factory AnsiTerminalWindowFactory.agnostic({
    Duration? terminalSizePollingInterval,
  }) {
    final controller = AnsiTerminalController();
    final capabilitiesDetector = TerminalCapabilitiesDetector.agnostic();
    final sizeTracker = TerminalSizeTracker.agnostic(
      pollingInterval:
          terminalSizePollingInterval ?? Duration(milliseconds: 50),
    );
    return AnsiTerminalWindowFactory(
      controller: controller,
      capabilitiesDetector: capabilitiesDetector,
      sizeTracker: sizeTracker,
    );
  }

  @override
  AnsiTerminalWindow createWindow({
    TerminalListener listener = const TerminalListener.empty(),
  }) => AnsiTerminalWindow(
    controller: _controller,
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

class AnsiTerminalWindow extends TerminalWindow
    implements TerminalSizeListener {
  final TerminalController controller;
  final TerminalCapabilitiesDetector capabilitiesDetector;
  final TerminalSizeTracker sizeTracker;
  late final AnsiTerminalScreen _screen;

  late final Set<TerminalCapability> _capabilities;

  final List<StreamSubscription> _subscriptions = [];
  Completer<Position>? _cursorPositionCompleter;

  @override
  Position? get cursorPosition => _cursorHidden ? null : _cursorPosition;
  bool _cursorHidden = false;
  late Position _cursorPosition;

  @override
  Size get size => sizeTracker.currentSize;

  AnsiTerminalWindow({
    required this.controller,
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
    io.stdout.write(ansi_codes.cursorPositionQuery);
    _cursorPositionCompleter = Completer<Position>();
    return _cursorPositionCompleter!.future;
  }

  @override
  Future<void> attach() async {
    await super.attach();
    controller
      ..saveCursorPosition()
      ..changeScreenMode(alternateBuffer: true)
      ..changeFocusTrackingMode(enable: true)
      ..changeMouseTrackingMode(enable: true)
      ..changeLineWrappingMode(enable: false);
    _subscriptions.add(io.stdin.listen(_stdinEvent));
    for (final signal in AllowedSignal.values) {
      _subscriptions.add(
        signal.processSignal().watch().listen((_) {
          listener.signal(signal);
        }),
      );
    }
    sizeTracker
      ..startTracking()
      ..addListener(this);
    controller.setInputMode(true);
    _cursorPosition = await _getCursorPosition();
    _screen = AnsiTerminalScreen(size)
      ..resetBackground()
      ..updateScreen();
  }

  @override
  Future<void> destroy() async {
    await super.destroy();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    sizeTracker.stopTracking();
    sizeTracker.removeListener(this);
    _screen
      ..resetBackground()
      ..updateScreen();
    controller
      ..setInputMode(false)
      ..changeScreenMode(alternateBuffer: false)
      ..restoreCursorPosition()
      ..changeFocusTrackingMode(enable: false)
      ..changeMouseTrackingMode(enable: false)
      ..changeLineWrappingMode(enable: true);
    _cursorPositionCompleter?.complete(Position(0, 0));
  }

  bool _tryToInterpretControlCharacter(List<int> input) {
    // TODO: handle multiple control characters at once
    if (input[0] >= 0x01 && input[0] <= 0x1a) {
      // Ctrl+A thru Ctrl+Z are mapped to the 1st-26th entries in the
      // enum, so it's easy to convert them across
      listener.controlCharacter(ControlCharacter.values[input[0] - 1]);
      return true;
    }
    if (input[0] == 127) {
      listener.controlCharacter(ControlCharacter.wordBackspace);
      return true;
    }
    if (input[0] == 27 && input.length == 1) {
      listener.controlCharacter(ControlCharacter.escape);
      return true;
    }
    // reads for CSI (can be ESC[ or just CSI)
    if (input[0] == 27 && input[1] == 91) {
      input = input.sublist(2);
    } else if (input[0] == 0x9b) {
      input = input.sublist(1);
    } else {
      return false;
    }
    // focus
    if (input.first == 73 || input.first == 79) {
      assert(input.length == 1);
      listener.focusChange(input.first == 73);
      return true;
    }
    // mouse reporting https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
    if (input.first == 60) {
      if (input.last != 77 && input.last != 109) return true;
      final isPrimaryAction =
          input.last == 77; // secondary action is release for example
      input = input.sublist(1, input.length - 1);
      final args = String.fromCharCodes(
        input,
      ).split(";").map(int.tryParse).toList(growable: false);
      if (args.length != 3 || args.any((arg) => arg == null)) return true;
      final btnState = args[0]!, pos = Position(args[1]! - 1, args[2]! - 1);
      final lowButton = btnState & 3;
      final shift = btnState & 4 != 0,
          meta = btnState & 8 != 0,
          ctrl = btnState & 16 != 0;
      final isMotion = btnState & 32 != 0, isScroll = btnState & 64 != 0;
      final usingExtraButton = btnState & 128 != 0; // for button 8-11
      if (isMotion) {
        assert(lowButton == 3);
        assert(isPrimaryAction);
        listener.mouseEvent(MouseHoverMotionEvent(shift, meta, ctrl, pos));
      } else if (isScroll) {
        assert(isPrimaryAction);
        final (xScroll, yScroll) = switch (lowButton) {
          0 => (0, -1),
          1 => (0, 1),
          2 => (1, 0),
          3 => (-1, 0),
          _ => throw StateError(""),
        };
        listener.mouseEvent(
          MouseScrollEvent(shift, meta, ctrl, pos, xScroll, yScroll),
        );
      } else {
        final btn = switch ((usingExtraButton, lowButton)) {
          (false, 0) => MouseButton.left,
          (false, 1) => MouseButton.middle,
          (false, 2) => MouseButton.right,
          (true, 0) => MouseButton.button8,
          (true, 1) => MouseButton.button9,
          (true, 2) => MouseButton.button10,
          (true, 3) => MouseButton.button11,
          _ => throw StateError("Release button cannot be pressed"),
        };
        final type = isPrimaryAction
            ? MouseButtonPressEventType.press
            : MouseButtonPressEventType.release;
        listener.mouseEvent(
          MouseButtonPressEvent(shift, meta, ctrl, pos, btn, type),
        );
      }
      return true;
    }
    // cursor position
    if (input.last == 82) {
      int semicolonIndex = input.indexOf(59);
      if (semicolonIndex == -1) return true;
      final x = int.tryParse(
        String.fromCharCodes(input.sublist(0, semicolonIndex)),
      );
      final y = int.tryParse(
        String.fromCharCodes(
          input.sublist(semicolonIndex + 1, input.length - 1),
        ),
      );
      if (x == null || y == null) return true;
      _cursorPositionCompleter?.complete(Position(x - 1, y - 1));
      _cursorPositionCompleter = null;
      return true;
    }
    // other control characters
    switch (input[0]) {
      case 65:
        listener.controlCharacter(ControlCharacter.arrowUp);
      case 66:
        listener.controlCharacter(ControlCharacter.arrowDown);
      case 67:
        listener.controlCharacter(ControlCharacter.arrowRight);
      case 68:
        listener.controlCharacter(ControlCharacter.arrowLeft);
      case 72:
        listener.controlCharacter(ControlCharacter.home);
      case 70:
        listener.controlCharacter(ControlCharacter.end);
    }
    return true;
  }

  @override
  void resizeEvent() {
    /// TODO: optimization?
    _screen
      ..resetBackground()
      ..updateScreen()
      ..resize(size);
    listener.screenResize(size);
  }

  void _stdinEvent(List<int> input) {
    if (!_tryToInterpretControlCharacter(input)) {
      listener.input(String.fromCharCodes(input));
    }
  }

  @override
  void bell() => controller.bell();

  @override
  void setTerminalSize(Size size) =>
      controller.changeSize(size.width, size.height);

  @override
  void setTerminalTitle(String title) => controller.changeTerminalTitle(title);

  @override
  void setCursor([Position? position]) {
    if ((position == null) != _cursorHidden) {
      _cursorHidden = position == null;
      controller.changeCursorVisibility(hiding: _cursorHidden);
    }
    if (position != null && position != _cursorPosition) {
      _cursorPosition = position;
      controller.setCursorPosition(position.x + 1, position.y);
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
      _screen.resetBackground(color);
    } else {
      _screen.drawRect(Position.zero & size, color, null);
    }
  }

  @override
  void updateScreen() {
    _screen.updateScreen();
    if (cursorPosition != null) {
      controller.setCursorPosition(
        cursorPosition!.x + 1,
        cursorPosition!.y + 1,
      );
    }
  }

  @override
  bool supportsCapability(TerminalCapability capability) =>
      _capabilities.contains(capability);
}
