class AdvancedTerminalStyleExtras {
  int _extras = 0;

  static const int _boldKey = 1;
  static const int _dimKey = 2;
  static const int _italicsKey = 4;
  static const int _underlinedKey = 8;
  static const int _blinkingKey = 16;
  static const int _blinkingAltKey = 32;
  static const int _strikeThroughKey = 64;

  bool get bold => _extras & _boldKey != 0;
  bool get dim => _extras & _dimKey != 0;
  bool get italics => _extras & _italicsKey != 0;
  bool get underlined => _extras & _underlinedKey != 0;
  bool get blinking => _extras & _blinkingKey != 0;
  bool get blinkingAlt => _extras & _blinkingAltKey != 0;
  bool get strikeThrough => _extras & _strikeThroughKey != 0;

  set bold(bool newBold) {
    if (newBold) {
      _extras = _extras | _boldKey;
    } else {
      _extras = _extras & ~_boldKey;
    }
  }

  set dim(bool newDim) {
    if (newDim) {
      _extras = _extras | _dimKey;
    } else {
      _extras = _extras & ~_dimKey;
    }
  }

  set italics(bool newItalics) {
    if (newItalics) {
      _extras = _extras | _italicsKey;
    } else {
      _extras = _extras & ~_italicsKey;
    }
  }

  set underlined(bool newUnderlined) {
    if (newUnderlined) {
      _extras = _extras | _underlinedKey;
    } else {
      _extras = _extras & ~_underlinedKey;
    }
  }

  set blinking(bool newBlinking) {
    if (newBlinking) {
      _extras = _extras | _blinkingKey;
    } else {
      _extras = _extras & ~_blinkingKey;
    }
  }

  set blinkingAlt(bool newBlinkingAlt) {
    if (newBlinkingAlt) {
      _extras = _extras | _blinkingAltKey;
    } else {
      _extras = _extras & ~_blinkingAltKey;
    }
  }

  set strikeThrough(bool newStrikeThrough) {
    if (newStrikeThrough) {
      _extras = _extras | _strikeThroughKey;
    } else {
      _extras = _extras & ~_strikeThroughKey;
    }
  }
}