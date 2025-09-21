import 'dart:async';
import 'dart:io' as io;

import 'package:dart_tui/core.dart';

// Terminal input state
enum _TerminalInputState {
  none,
  string,
  esc, // wait on [
  csi, // wait on intermediate, parameters or final byte
}

typedef _T = _TerminalInputState;

class FocusEvent {
  final bool isFocused;

  FocusEvent({required this.isFocused});
}

class CursorPositionEvent {
  final Position position;

  CursorPositionEvent(this.position);
}

sealed class AnsiTerminalInputProcessor {
  /// [FocusEvent] for focusing events for the terminal window
  /// [String] for normal input (can be multiple long on copy paste)
  /// [CursorPositionEvent] for the cursor position (only after request)
  /// [MouseEvent] for mouse events
  /// [ControlCharacter] for various control characters (not complete)
  void Function(Object)? listener;

  late final StreamSubscription<List<int>> _ioSubscription;

  AnsiTerminalInputProcessor();

  FutureOr<void> startListening() {
    _ioSubscription = io.stdin.listen(_onBytes);
  }

  void _onBytes(List<int> bytes);

  FutureOr<void> stopListening() => _ioSubscription.cancel();

  factory AnsiTerminalInputProcessor.waiting() =>
      _WaitingAnsiTerminalInputProcessor();

  factory AnsiTerminalInputProcessor.simple() =>
      _SimpleAnsiTerminalInputProcessor();
}

final class _WaitingAnsiTerminalInputProcessor
    extends AnsiTerminalInputProcessor {
  _TerminalInputState _state = _T.none;
  // Simplified CSI structure:
  // CSI[parameter section (optional)][param1];[param2];[param3]...[final byte]
  // parameter section is 58-63 in ascii
  // params are numbers (ascii 0-9)
  // final byte is 0x40-0x7E in ascii
  //
  // note: technically parameter section belongs to the param
  // and before final byte there is the possibility of intermediates
  // however these are not used by any of the interpreted CSIs here
  late bool _isRealCsi; // if the CSI consists of ESC[
  late int? _parameterSection;
  late List<int> _csiParams;
  late List<int> _currentCsiParamBytes;
  late List<int>
  _allCsiBytesAfterEsc; // if not real CSI => begin at intermediate
  late int _final;
  late List<int> _stringBytes = [];

  Timer? _inputWaitTimeoutTimer;

  @override
  void _onBytes(List<int> bytes) {
    _inputWaitTimeoutTimer?.cancel();
    for (final byte in bytes) {
      _processByte(byte);
    }
    _processEndOfInputBuffer();
    _inputWaitTimeoutTimer = Timer(
      Duration(milliseconds: 50),
      _processInputWaitTimeout,
    );
  }

  void _isString(List<int> bytes) {
    _stringBytes = bytes;
    _state = _T.string;
  }

  void _isEsc() {
    _state = _T.esc;
  }

  void _isCsi(bool isRealCsi) {
    _state = _T.csi;
    _isRealCsi = isRealCsi;
    _parameterSection = null;
    _csiParams = [];
    _currentCsiParamBytes = [];
    _allCsiBytesAfterEsc = isRealCsi ? [91] : []; // 91 is byte for [
  }

  void _processByte(int byte) {
    switch (_state) {
      string:
      case _T.string:
        if (byte <= 27 || byte == 127 || byte == 155) {
          listener?.call(String.fromCharCodes(_stringBytes));
          _state = _T.none;
          continue none;
        } else {
          _stringBytes.add(byte);
        }
      none:
      case _T.none:
        if (byte <= 26) {
          // first 27 ascii bytes match the first 27 values of ControlCharacter
          listener?.call(ControlCharacter.values[byte]);
        } else if (byte == 127) {
          listener?.call(ControlCharacter.delete);
        } else if (byte == 27) {
          _isEsc();
        } else if (byte == 155) {
          _isCsi(false);
          _state = _T.csi;
        } else {
          _isString([byte]);
        }
      case _TerminalInputState.esc:
        if (byte == 91) {
          _isCsi(true);
        } else {
          listener?.call(ControlCharacter.escape);
          _isString([byte]);
        }
      case _TerminalInputState.csi:
        if (58 <= byte &&
            byte <= 63 &&
            _parameterSection == null &&
            _currentCsiParamBytes.isEmpty &&
            _csiParams.isEmpty) {
          // intermediate
          _parameterSection = byte;
        } else if (48 <= byte && byte <= 57) {
          // 0-9 (part of a param)
          _currentCsiParamBytes.add(byte);
        } else if (byte == 59 && _currentCsiParamBytes.isNotEmpty) {
          // semicolon
          final p = int.parse(String.fromCharCodes(_currentCsiParamBytes));
          _currentCsiParamBytes.clear();
          _csiParams.add(p);
        } else if (0x40 <= byte && byte <= 0x7E) {
          // final byte
          if (_currentCsiParamBytes.isNotEmpty) {
            final p = int.parse(String.fromCharCodes(_currentCsiParamBytes));
            _csiParams.add(p);
          }
          _final = byte;
          if (!_tryParseCsi()) {
            _isString(_allCsiBytesAfterEsc);
          } else {
            _state = _T.none;
          }
        } else {
          if (_isRealCsi) {
            listener?.call(ControlCharacter.escape);
          }
          _isString(_allCsiBytesAfterEsc);
          continue string;
        }
        _allCsiBytesAfterEsc.add(byte);
    }
  }

  void _processEndOfInputBuffer() {
    if (_state == _T.string) {
      listener?.call(String.fromCharCodes(_stringBytes));
      _state = _T.none;
    }
  }

  void _processInputWaitTimeout() {
    if (_state == _T.esc || _state == _T.csi) {
      if (_state == _T.esc || _isRealCsi) {
        listener?.call(ControlCharacter.escape);
      }
      listener?.call(String.fromCharCodes(_allCsiBytesAfterEsc));
      _state = _T.none;
    }
  }

  bool _tryParseCsi() {
    const n = null;
    final event = switch ((_final, _parameterSection, _csiParams)) {
      // focus
      (73, n, []) => FocusEvent(isFocused: true),
      (79, n, []) => FocusEvent(isFocused: false),
      // cursor position
      (82, n, [var x, var y]) => CursorPositionEvent(Position(x - 1, y - 1)),
      // button
      (77 || 109, 60, [var s, var x, var y]) => _mouse(_final == 77, s, x, y),
      // control characters
      (65, n, []) => ControlCharacter.arrowUp,
      (66, n, []) => ControlCharacter.arrowDown,
      (67, n, []) => ControlCharacter.arrowRight,
      (68, n, []) => ControlCharacter.arrowLeft,
      (72, n, []) => ControlCharacter.home,
      (70, n, []) => ControlCharacter.end,
      _ => null,
    };
    if (event != null) {
      listener?.call(event);
      return true;
    }
    return false;
  }

  MouseEvent? _mouse(bool isPrimaryAction, int btnState, int x, int y) {
    final pos = Position(x - 1, y - 1);
    final lowButton = btnState & 3;
    final shift = btnState & 4 != 0,
        meta = btnState & 8 != 0,
        ctrl = btnState & 16 != 0;
    final isMotion = btnState & 32 != 0, isScroll = btnState & 64 != 0;
    final usingExtraButton = btnState & 128 != 0; // for button 8-11
    // technically information is getting lost here,
    // as the press events don't have a motion indicator
    // and because this way not all events with the motion indicater (isMotion)
    // will be processed into a hover event
    if (isMotion && lowButton == 3 && !usingExtraButton) {
      if (!isPrimaryAction) return null;
      return MouseHoverEvent(shift, meta, ctrl, pos);
    } else if (isScroll) {
      if (!isPrimaryAction) return null;
      final (xScroll, yScroll) = switch (lowButton) {
        0 => (0, -1),
        1 => (0, 1),
        2 => (1, 0),
        3 => (-1, 0),
        _ => throw StateError(""),
      };
      return MouseScrollEvent(shift, meta, ctrl, pos, xScroll, yScroll);
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
          ? MousePressEventType.press
          : MousePressEventType.release;
      return MousePressEvent(shift, meta, ctrl, pos, btn, type);
    }
  }
}

final class _SimpleAnsiTerminalInputProcessor
    extends AnsiTerminalInputProcessor {
  @override
  void _onBytes(List<int> input) {
    if (!_tryToInterpretControlCharacter(input)) {
      listener?.call(String.fromCharCodes(input));
    }
  }

  bool _tryToInterpretControlCharacter(List<int> input) {
    if (input[0] <= 0x1a) {
      // Ctrl+A thru Ctrl+Z are mapped to the 1st-26th entries in the
      // enum, so it's easy to convert them across
      listener?.call(ControlCharacter.values[input[0]]);
      return true;
    }
    if (input[0] == 127) {
      listener?.call(ControlCharacter.delete);
      return true;
    }
    if (input[0] == 27 && input.length == 1) {
      listener?.call(ControlCharacter.escape);
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
      listener?.call(input.first == 73);
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
        listener?.call(MouseHoverEvent(shift, meta, ctrl, pos));
      } else if (isScroll) {
        assert(isPrimaryAction);
        final (xScroll, yScroll) = switch (lowButton) {
          0 => (0, -1),
          1 => (0, 1),
          2 => (1, 0),
          3 => (-1, 0),
          _ => throw StateError(""),
        };
        listener?.call(
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
            ? MousePressEventType.press
            : MousePressEventType.release;
        listener?.call(MousePressEvent(shift, meta, ctrl, pos, btn, type));
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
      listener?.call(CursorPositionEvent(Position(x - 1, y - 1)));
      return true;
    }
    // other control characters
    switch (input[0]) {
      case 65:
        listener?.call(ControlCharacter.arrowUp);
      case 66:
        listener?.call(ControlCharacter.arrowDown);
      case 67:
        listener?.call(ControlCharacter.arrowRight);
      case 68:
        listener?.call(ControlCharacter.arrowLeft);
      case 72:
        listener?.call(ControlCharacter.home);
      case 70:
        listener?.call(ControlCharacter.end);
    }
    return true;
  }
}
