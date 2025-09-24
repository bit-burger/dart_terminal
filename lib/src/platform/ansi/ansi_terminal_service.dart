// Dart imports:
import 'dart:async' as async;
import 'dart:io' as io;

// Project imports:
import 'package:dart_tui/core.dart';
import 'package:dart_tui/src/platform/ansi/ansi_terminal_controller.dart';
import 'package:dart_tui/src/platform/ansi/ansi_terminal_input_processor.dart';
import '../shared/native_terminal_image.dart';
import '../shared/signals.dart';
import '../shared/terminal_capabilities.dart';
import '../shared/terminal_size_tracker.dart';
import 'ansi_escape_codes.dart' as ansi_codes;

part 'ansi_terminal_logger.dart';
part 'ansi_terminal_viewport.dart';

// ignore: public_member_api_docs
class AnsiTerminalService extends TerminalService {
  final TerminalCapabilitiesDetector _capabilitiesDetector;
  final TerminalSizeTracker _sizeTracker;
  final AnsiTerminalInputProcessor _inputProcessor =
      AnsiTerminalInputProcessor.waiting();
  final AnsiTerminalController _controller = AnsiTerminalController();

  final List<async.StreamSubscription<Object>> _subscriptions = [];
  late final _AnsiTerminalViewport viewport;
  late final _AnsiTerminalLogger logger;

  /// Creates a new factory with specific capability detection and size tracking.
  AnsiTerminalService({
    required TerminalCapabilitiesDetector capabilitiesDetector,
    required TerminalSizeTracker sizeTracker,
  }) : _capabilitiesDetector = capabilitiesDetector,
       _sizeTracker = sizeTracker {
    viewport = _AnsiTerminalViewport._(this);
    logger = _AnsiTerminalLogger._(this);
  }

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
  Future<void> attach() async {
    await _capabilitiesDetector.detect();
    _controller
      ..saveCursorPosition()
      ..changeFocusTrackingMode(enable: true);
    _inputProcessor
      ..startListening()
      ..listener = _onInputEvent;
    for (final signal in AllowedSignal.values) {
      _subscriptions.add(
        signal.processSignal().watch().listen((_) {
          listener?.signal(signal);
        }),
      );
    }
    _sizeTracker
      ..startTracking()
      ..listener = _onResizeEvent;
    _controller.setInputMode(true);
    await super.attach();
  }

  @override
  Future<void> destroy() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _inputProcessor.stopListening();
    _sizeTracker.stopTracking();
    // TODO: perhaps clear alternative buffer?
    _controller
      ..setInputMode(false)
      ..changeScreenMode(alternateBuffer: false)
      ..changeCursorVisibility(hiding: false)
      ..changeCursorBlinking(blinking: true)
      ..restoreCursorPosition()
      ..changeFocusTrackingMode(enable: false)
      ..changeMouseTrackingMode(enable: false)
      ..changeLineWrappingMode(enable: true);
    await super.destroy();
  }

  @override
  void switchToLoggerMode() {
    if (logger.isActive) return;
    super.switchToLoggerMode();
    _controller
      ..changeLineWrappingMode(enable: true)
      ..changeScreenMode(alternateBuffer: false)
      ..changeMouseTrackingMode(enable: false);
  }

  @override
  void switchToViewPortMode() {
    if (viewport.isActive) return;
    super.switchToViewPortMode();
    _controller
      ..changeLineWrappingMode(enable: false)
      ..changeScreenMode(alternateBuffer: true)
      ..changeMouseTrackingMode(enable: true);
    viewport._onActivationEvent();
  }

  void _onInputEvent(Object event) {
    if (event is CursorPositionEvent) {
      // nothing done as cursor position known at all times
    } else if (event is String) {
      listener?.input(event);
    } else if (event is MouseEvent) {
      listener?.mouseEvent(event);
    } else if (event is ControlCharacter) {
      listener?.controlCharacter(event);
    } else if (event is FocusEvent) {
      listener?.focusChange(event.isFocused);
    }
  }

  void _onResizeEvent() {
    if (viewport.isActive) viewport._onResizeEvent();
    listener?.screenResize(_sizeTracker.currentSize);
  }

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

  @override
  void bell() => _controller.bell();

  @override
  void setTerminalTitle(String title) => _controller.changeTerminalTitle(title);

  @override
  void trySetTerminalSize(Size size) =>
      _controller.changeSize(size.width, size.height);
}
