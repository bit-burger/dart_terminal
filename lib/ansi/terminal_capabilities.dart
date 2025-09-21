import 'dart:io';

import 'package:dart_tui/ansi/terminfo.dart';

import '../core/terminal.dart';

abstract class TerminalCapabilitiesDetector {
  /// sure capabilities
  final Set<Capability> supportedCaps = {};

  /// assumed capabilities
  final Set<Capability> assumedCaps = {};

  /// override the assumed capabilities
  final Set<Capability> unsupportedCaps = {};

  Future<void> detect();

  TerminalCapabilitiesDetector();

  factory TerminalCapabilitiesDetector.agnostic() {
    return CombiningTerminalCapabilitiesDetector(
      detectors: [
        TrueColorsTerminalCapabilitiesDetector(),
        XtermTerminalCapabilitiesDetector(),
        WindowsTerminalCapabilitiesDetector(),
        TerminfoTerminalCapabilitiesDetector(),
      ],
    );
  }
}

class CombiningTerminalCapabilitiesDetector
    extends TerminalCapabilitiesDetector {
  final Iterable<TerminalCapabilitiesDetector> detectors;

  CombiningTerminalCapabilitiesDetector({required this.detectors});

  @override
  Future<void> detect() async {
    await Future.wait(detectors.map((d) => d.detect()));
    supportedCaps.addAll(
      detectors.fold<Set<Capability>>(
        {},
        (caps, detector) => caps..addAll(detector.supportedCaps),
      ),
    );
    assumedCaps.addAll(
      detectors.fold<Set<Capability>>(
        {},
        (caps, detector) => caps..addAll(detector.assumedCaps),
      ),
    );
    unsupportedCaps.addAll(
      detectors.fold<Set<Capability>>(
        {},
        (caps, detector) => caps..addAll(detector.unsupportedCaps),
      ),
    );
    assumedCaps.removeAll(unsupportedCaps);
    final intersection = supportedCaps.intersection(unsupportedCaps);
    supportedCaps.removeAll(intersection);
    unsupportedCaps.removeAll(intersection);
  }
}

/// Detects capabilities for Xterm-compatible terminals via $TERM
class XtermTerminalCapabilitiesDetector extends TerminalCapabilitiesDetector {
  @override
  Future<void> detect() async {
    // -------------------------
    // Environment heuristics
    // -------------------------
    final termEnv = Platform.environment['TERM'] ?? '';

    final isXterm = termEnv.contains('xterm');

    if (!isXterm) return;

    // -------------------------
    // Colors
    // -------------------------
    supportedCaps.add(Capability.basicColors);
    if (termEnv.contains('256')) {
      supportedCaps.add(Capability.extendedColors);
    }
    if (termEnv.contains('direct')) supportedCaps.add(Capability.trueColors);

    // -------------------------
    // Mouse support (SGR/X10)
    // -------------------------
    supportedCaps.add(Capability.mouse);

    // -------------------------
    // Text decorations (SGR sequences)
    // -------------------------
    supportedCaps.add(Capability.intenseTextDecoration);
    supportedCaps.add(Capability.underlineTextDecoration);
    supportedCaps.add(Capability.italicTextDecoration);
    supportedCaps.add(Capability.crossedOutTextDecoration);
    supportedCaps.add(Capability.textBlinkTextDecoration);
    supportedCaps.add(Capability.doubleUnderlineTextDecoration);
  }
}

/// checks the $COLORTERM environment variable for colorterm support
class TrueColorsTerminalCapabilitiesDetector
    extends TerminalCapabilitiesDetector {
  static final _trueColorsRegex = RegExp(
    "truecolor|24bit",
    caseSensitive: false,
  );

  @override
  Future<Set<Capability>> detect() async {
    final colorEnv = (Platform.environment['COLORTERM'] ?? '');
    final trueColorSupport = colorEnv.contains(_trueColorsRegex);
    if (trueColorSupport) return {Capability.trueColors};
    return <Capability>{};
  }
}

/// Checks the terminfo database for capabilities
class TerminfoTerminalCapabilitiesDetector
    extends TerminalCapabilitiesDetector {
  @override
  Future<void> detect() async {
    final terminfo = await Terminfo.tryGet();
    if (terminfo == null) return;

    // -------------------------
    // Colors
    // -------------------------
    final colors = terminfo.numerics['colors'];
    if (colors != null) {
      if (colors >= 16) supportedCaps.add(Capability.basicColors);
      if (colors >= 256) supportedCaps.add(Capability.extendedColors);
      // trueColors cannot be inferred from terminfo
    }

    final keys = <String>{}
      ..addAll(terminfo.booleans)
      ..addAll(terminfo.strings.keys)
      ..addAll(terminfo.numerics.keys);

    // -------------------------
    // Mouse support
    // -------------------------
    if (keys.contains('km') ||
        keys.contains('kmous') ||
        keys.contains('smkx') || // keypad enable often needed for mouse
        keys.contains('xenl')) {
      supportedCaps.add(Capability.mouse);
    }

    // -------------------------
    // Text decorations
    // -------------------------
    if (keys.contains('blink') ||
        keys.contains('smpch') ||
        keys.contains('blink')) {
      supportedCaps.add(Capability.textBlinkTextDecoration);
    }

    if (keys.contains('bold') || keys.contains('intense')) {
      supportedCaps.add(Capability.intenseTextDecoration);
    }

    if (keys.contains('faint')) {
      supportedCaps.add(Capability.faintTextDecoration);
    }

    if (keys.contains('sitm')) {
      supportedCaps.add(Capability.italicTextDecoration);
    }

    if (keys.contains('smul')) {
      supportedCaps.add(Capability.underlineTextDecoration);
    }

    if (keys.contains('smulx')) {
      supportedCaps.add(Capability.doubleUnderlineTextDecoration);
    }

    if (keys.contains('crossout')) {
      supportedCaps.add(Capability.crossedOutTextDecoration);
    }

    if (keys.contains('blink') || keys.contains('smpch')) {
      supportedCaps.add(Capability.textBlinkTextDecoration);
    }
  }
}

/// Detects capabilities for Windows terminals
class WindowsTerminalCapabilitiesDetector extends TerminalCapabilitiesDetector {
  @override
  Future<void> detect() async {
    if (!Platform.isWindows) return;

    final isWin10OrNewer = _isWindows10OrNewer();
    final isWindowsTerminal = Platform.environment.containsKey('WT_SESSION');
    final isConEmu = Platform.environment.containsKey('ConEmuANSI');

    // -------------------------
    // Colors
    // -------------------------
    supportedCaps.add(Capability.basicColors);

    if (isWin10OrNewer || isConEmu) {
      supportedCaps.add(Capability.extendedColors);
    } else {
      assumedCaps.add(Capability.extendedColors);
      unsupportedCaps.add(Capability.trueColors);
    }

    // -------------------------
    // Mouse support
    // -------------------------

    if (isWindowsTerminal || isConEmu) {
      supportedCaps.add(Capability.mouse);
    } else if (isWin10OrNewer) {
      assumedCaps.add(Capability.mouse);
    } else {
      unsupportedCaps.add(Capability.mouse);
    }

    // -------------------------
    // Cursor blinking
    // -------------------------

    unsupportedCaps.add(Capability.cursorBlinkingDisable);

    // -------------------------
    // Text decorations
    // -------------------------

    supportedCaps.add(Capability.intenseTextDecoration);

    if (isConEmu || isWindowsTerminal) {
      supportedCaps.add(Capability.italicTextDecoration);
      supportedCaps.add(Capability.underlineTextDecoration);
    } else if (isWin10OrNewer) {
      assumedCaps.add(Capability.italicTextDecoration);
      assumedCaps.add(Capability.underlineTextDecoration);
    } else {
      unsupportedCaps.add(Capability.italicTextDecoration);
      unsupportedCaps.add(Capability.underlineTextDecoration);
    }

    // Double underline is not supported
    unsupportedCaps.add(Capability.doubleUnderlineTextDecoration);

    if (isConEmu || isWindowsTerminal) {
      supportedCaps.add(Capability.crossedOutTextDecoration);
    } else if (!isWindowsTerminal) {
      unsupportedCaps.add(Capability.crossedOutTextDecoration);
    }

    if (isWin10OrNewer) {
      assumedCaps.add(Capability.faintTextDecoration);
    } else if (!isConEmu) {
      unsupportedCaps.add(Capability.faintTextDecoration);
    }

    // Blinking is not reliably supported
    unsupportedCaps.add(Capability.textBlinkTextDecoration);
  }

  /// returns true if running on Windows 10 or newer
  bool _isWindows10OrNewer() {
    final version = Platform.operatingSystemVersion;
    final match = RegExp(r'(\d+)\.(\d+)\.(\d+)').firstMatch(version);
    if (match != null) {
      final major = int.tryParse(match.group(1) ?? '') ?? 0;
      return major >= 10;
    }
    return false;
  }
}
