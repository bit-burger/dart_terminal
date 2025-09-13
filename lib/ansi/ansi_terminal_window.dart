import 'dart:async';
import 'dart:io' as io;

import 'package:dart_tui/ansi/ansi_terminal_screen.dart';
import 'package:dart_tui/ansi/terminal_capabilities.dart';
import 'package:dart_tui/ansi/terminal_size_tracker.dart';

import '../core/style.dart';
import '../core/terminal.dart';
import 'ansi_escape_codes.dart' as ansi_codes;
import 'ansi_terminal_controller.dart';

class AnsiTerminalWindowFactory extends TerminalWindowFactory {
  final TerminalController controller;
  final TerminalCapabilitiesDetector capabilitiesDetector;
  final TerminalSizeTracker sizeTracker;

  AnsiTerminalWindowFactory({
    required this.controller,
    required this.capabilitiesDetector,
    required this.sizeTracker,
  });

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
  AnsiTerminalWindow createWindow() => AnsiTerminalWindow(
    controller: controller,
    capabilitiesDetector: capabilitiesDetector,
    sizeTracker: sizeTracker,
  );
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
  late final AnsiTerminalScreen screen;

  late final Set<TerminalCapability> _capabilities;

  final List<StreamSubscription> _subscriptions = [];
  Completer<Position>? _cursorPositionCompleter;

  @override
  Position get cursorPosition => _cursorPosition;
  late Position _cursorPosition;

  @override
  Size get size => Size(io.stdout.terminalColumns, io.stdout.terminalLines);

  AnsiTerminalWindow({
    required this.controller,
    required this.capabilitiesDetector,
    required this.sizeTracker,
  });

  factory AnsiTerminalWindow.agnostic({Duration? terminalSizePollingInterval}) {
    return AnsiTerminalWindowFactory.agnostic(
      terminalSizePollingInterval: terminalSizePollingInterval,
    ).createWindow();
  }

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
      ..clearScreen()
      ..changeFocusTrackingMode(enable: true)
      ..changeMouseTrackingMode(enable: true)
      ..changeLineWrappingMode(enable: false);
    _subscriptions.add(io.stdin.listen(_stdinEvent));
    for (final signal in AllowedSignal.values) {
      _subscriptions.add(
        signal.processSignal().watch().listen((_) {
          for (final listener in listeners) {
            listener.signal(signal);
          }
        }),
      );
    }
    sizeTracker
      ..startTracking()
      ..addListener(this);
    controller.setInputMode(true);
    _cursorPosition = await _getCursorPosition();
    screen = AnsiTerminalScreen(size, 1000);
  }

  @override
  Future<void> destroy() async {
    await super.destroy();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    sizeTracker.stopTracking();
    sizeTracker.removeListener(this);
    controller
      ..setInputMode(false)
      ..clearScreen() // necessary?
      ..changeScreenMode(alternateBuffer: false)
      ..restoreCursorPosition()
      ..changeFocusTrackingMode(enable: false)
      ..changeMouseTrackingMode(enable: false)
      ..changeLineWrappingMode(enable: true);
    _cursorPositionCompleter?.complete(Position(0, 0));
  }

  bool _tryToInterpretControlCharacter(List<int> input) {
    if (input[0] >= 0x01 && input[0] <= 0x1a) {
      // Ctrl+A thru Ctrl+Z are mapped to the 1st-26th entries in the
      // enum, so it's easy to convert them across
      _controlCharacter(ControlCharacter.values[input[0] - 1]);
      return true;
    }
    if (input[0] == 127) {
      _controlCharacter(ControlCharacter.wordBackspace);
      return true;
    }
    if (input[0] == 27 && input.length == 1) {
      _controlCharacter(ControlCharacter.escape);
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
      _focusEvent(input.first == 73);
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
      final btnState = args[0]!, pos = Position(args[1]!, args[2]!);
      final lowButton = btnState & 3;
      final shift = btnState & 4 != 0,
          meta = btnState & 8 != 0,
          ctrl = btnState & 16 != 0;
      final isMotion = btnState & 32 != 0, isScroll = btnState & 64 != 0;
      final usingExtraButton = btnState & 128 != 0; // for button 8-11
      if (isMotion) {
        assert(lowButton == 3);
        assert(isPrimaryAction);
        _mouseEvent(MouseHoverMotionEvent(shift, meta, ctrl, pos));
      } else if (isScroll) {
        assert(isPrimaryAction);
        final (xScroll, yScroll) = switch (lowButton) {
          0 => (0, -1),
          1 => (0, 1),
          2 => (1, 0),
          3 => (-1, 0),
          _ => throw StateError(""),
        };
        _mouseEvent(MouseScrollEvent(shift, meta, ctrl, pos, xScroll, yScroll));
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
        _mouseEvent(MouseButtonPressEvent(shift, meta, ctrl, pos, btn, type));
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
        _controlCharacter(ControlCharacter.arrowUp);
      case 66:
        _controlCharacter(ControlCharacter.arrowDown);
      case 67:
        _controlCharacter(ControlCharacter.arrowRight);
      case 68:
        _controlCharacter(ControlCharacter.arrowLeft);
      case 72:
        _controlCharacter(ControlCharacter.home);
      case 70:
        _controlCharacter(ControlCharacter.end);
    }
    return true;
  }

  @override
  void resizeEvent() {
    screen.reset();
    screen.resize(size);
    screen.optimizeForFullDraw();
    controller.clearScreen();
    for (final listener in listeners) {
      listener.screenResize(size);
    }
  }

  void _controlCharacter(ControlCharacter controlCharacter) {
    for (final listener in listeners) {
      listener.controlCharacter(controlCharacter);
    }
  }

  void _focusEvent(bool isFocused) {
    for (final listener in listeners) {
      listener.focusChange(isFocused);
    }
  }

  void _mouseEvent(MouseEvent mouseEvent) {
    for (final listener in listeners) {
      listener.mouseEvent(mouseEvent);
    }
  }

  void _stdinEvent(List<int> input) {
    if (!_tryToInterpretControlCharacter(input)) {
      for (final listener in listeners) {
        final s = String.fromCharCodes(input);
        listener.input(s);
      }
    }
  }

  @override
  void bell() => controller.bell();

  @override
  void changeCursorVisibility({required bool hiding}) =>
      controller.changeCursorVisibility(hiding: hiding);

  @override
  void changeTerminalSize(Size size) =>
      controller.changeSize(size.width, size.height);

  @override
  void changeTerminalTitle(String title) =>
      controller.changeTerminalTitle(title);

  @override
  void drawPoint({
    required Position position,
    TerminalColor? background,
    TerminalForeground? foreground,
  }) => screen.drawPoint(
    position: position,
    backgroundColor: background,
    foreground: foreground,
  );

  @override
  void drawRect({
    required Rect rect,
    TerminalColor? background,
    TerminalForeground? foreground,
  }) => screen.drawRect(
    rect: rect,
    backgroundColor: background,
    foreground: foreground,
  );

  @override
  void drawString({
    required String text,
    required TerminalForegroundStyle? foreground,
    required Position position,
  }) =>
      screen.drawString(text: text, style: foreground, position: position);

  @override
  void changeCursorPosition(Position position) {
    _cursorPosition = position;
    controller.setCursorPosition(position.x, position.y);
  }

  @override
  void writeToScreen() => screen.drawChanges(cursorPosition);

  @override
  bool supportsCapability(TerminalCapability capability) =>
      _capabilities.contains(capability);
}
