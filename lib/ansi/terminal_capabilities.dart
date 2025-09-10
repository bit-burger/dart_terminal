import 'dart:io';

import 'package:dart_tui/ansi/terminfo.dart';

import '../core/terminal.dart';

abstract class TerminalCapabilitiesDetector {
  Future<Set<TerminalCapability>> detect();
  const TerminalCapabilitiesDetector();

  factory TerminalCapabilitiesDetector.agnostic() {
    return UnionTerminalCapabilitiesDetector(
      detectors: [
        TrueColorsTerminalCapabilitiesDetector(),
        Platform.isWindows
            ? WindowsTerminalCapabilitiesDetector()
            : TerminfoTerminalCapabilitiesDetector(),
      ],
    );
  }
}

class UnionTerminalCapabilitiesDetector extends TerminalCapabilitiesDetector {
  final Iterable<TerminalCapabilitiesDetector> detectors;

  UnionTerminalCapabilitiesDetector({required this.detectors});

  @override
  Future<Set<TerminalCapability>> detect() async {
    final capabilities = await Future.wait(detectors.map((d) => d.detect()));
    return capabilities.fold<Set<TerminalCapability>>(
      <TerminalCapability>{},
      (a, b) => a.union(b),
    );
  }
}

class TrueColorsTerminalCapabilitiesDetector
    extends TerminalCapabilitiesDetector {
  static final _trueColorsRegex = RegExp(
    "truecolor|24bit",
    caseSensitive: false,
  );

  @override
  Future<Set<TerminalCapability>> detect() async {
    final colorEnv = (Platform.environment['COLORTERM'] ?? '');
    final termEnv = (Platform.environment['Tasync ERM'] ?? '');
    final trueColorSupport =
        colorEnv.contains(_trueColorsRegex) ||
        termEnv.contains(_trueColorsRegex);
    if (trueColorSupport) return {TerminalCapability.trueColors};
    return <TerminalCapability>{};
  }
}

class TerminfoTerminalCapabilitiesDetector
    extends TerminalCapabilitiesDetector {
  @override
  Future<Set<TerminalCapability>> detect() async {
    final terminfo = await Terminfo.tryGet();
    final caps = <TerminalCapability>{};
    if (terminfo == null) return caps;

    // -------------------------
    // Colors
    // -------------------------
    final colors = terminfo.numerics['colors'];
    if (colors != null) {
      if (colors >= 16) caps.add(TerminalCapability.basicColors);
      if (colors >= 256) caps.add(TerminalCapability.extendedColors);
      // trueColors cannot be inferred from terminfo alone
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
      caps.add(TerminalCapability.mouse);
    }

    // -------------------------
    // Text decorations
    // -------------------------
    if (keys.contains('blink') ||
        keys.contains('smpch') ||
        keys.contains('blink')) {
      caps.add(TerminalCapability.textBlink);
    }

    if (keys.contains('bold') || keys.contains('intense')) {
      caps.add(TerminalCapability.intense);
    }

    if (keys.contains('faint')) {
      caps.add(TerminalCapability.faint);
    }

    if (keys.contains('sitm')) {
      caps.add(TerminalCapability.italic);
    }

    if (keys.contains('smul')) {
      caps.add(TerminalCapability.underline);
    }

    if (keys.contains('smulx')) {
      caps.add(TerminalCapability.doubleUnderline);
    }

    if (keys.contains('crossout')) {
      caps.add(TerminalCapability.crossedOut);
    }

    if (keys.contains('blink') || keys.contains('smpch')) {
      caps.add(TerminalCapability.textBlink);
    }
    return caps;
  }
}

class WindowsTerminalCapabilitiesDetector extends TerminalCapabilitiesDetector {
  @override
  Future<Set<TerminalCapability>> detect() async {
    final caps = <TerminalCapability>{};

    // Environment variables
    final wt = Platform.environment['WT_SESSION'];
    final conemu = Platform.environment['ConEmuANSI']?.toLowerCase();

    // -------------------------
    // Mouse support
    // -------------------------
    if ((wt != null && wt.isNotEmpty) || (conemu != null && conemu == 'true')) {
      caps.add(TerminalCapability.mouse);
    }

    // -------------------------
    // Colors
    // -------------------------
    // Modern Windows terminals support 16+ colors
    caps.add(TerminalCapability.basicColors);
    caps.add(TerminalCapability.extendedColors);

    // -------------------------
    // Text decorations
    // -------------------------
    caps.add(TerminalCapability.intense); // bold/intense
    caps.add(TerminalCapability.underline); // underline
    caps.add(TerminalCapability.italic); // italic
    caps.add(TerminalCapability.crossedOut); // crossed out
    caps.add(TerminalCapability.textBlink); // blink (may not be visible)
    caps.add(TerminalCapability.doubleUnderline); // double underline

    // Truecolor detection is tricky on Windows, often via environment or strings
    // Leaving out as terminfo is not used here

    return caps;
  }
}
