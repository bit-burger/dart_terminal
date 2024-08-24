import 'dart:io' as io;

import 'package:meta/meta.dart';

enum AllowedSignal {
  sighup,
  sigint,
  sigterm,
  sigusr1,
  sigusr2;

  io.ProcessSignal processSignal() {
    switch (this) {
      case sighup:
        return io.ProcessSignal.sighup;
      case sigint:
        return io.ProcessSignal.sigint;
      case sigterm:
        return io.ProcessSignal.sigterm;
      case sigusr1:
        return io.ProcessSignal.sigusr1;
      case sigusr2:
        return io.ProcessSignal.sigusr2;
    }
  }
}

enum ControlCharacter {
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

  arrowLeft,
  arrowRight,
  arrowUp,
  arrowDown,
  pageUp,
  pageDown,
  wordLeft,
  wordRight,

  home,
  end,
  escape,
  delete,
  wordBackspace,

  // ignore: constant_identifier_names
  F1,
  // ignore: constant_identifier_names
  F2,
  // ignore: constant_identifier_names
  F3,
  // ignore: constant_identifier_names
  F4,
}

enum MouseButton { left, right, middle }

enum MouseEventType { press, release }

abstract class TerminalInputListener {
  void screenResize(int x, int y);

  void input(String s);

  void controlCharacter(ControlCharacter controlCharacter);

  void signal(AllowedSignal signal);

  void mouseEvent(MouseButton button, MouseEventType type, int x, int y);

  void focusChange(bool isFocused);
}

class DefaultTerminalInputListener extends TerminalInputListener {
  @override
  void controlCharacter(ControlCharacter controlCharacter) {}

  @override
  void input(String s) {}

  @override
  void screenResize(int x, int y) {}

  @override
  void signal(AllowedSignal signal) {}

  @override
  void focusChange(bool isFocused) {}

  @override
  void mouseEvent(MouseButton button, MouseEventType type, int x, int y) {}
}

abstract class TerminalInput {
  @protected
  List<TerminalInputListener> listeners = [];

  int get height;
  int get width;


  Future<(int, int)> getCursorPosition();

  // also handle sigint etc...
  // raw scroll mode and stuff like that
  void startDirectListening();

  void stopDirectListening();

  void addListener(TerminalInputListener listener) {
    listeners.add(listener);
  }

  void removeListener(TerminalInputListener listener) {
    listeners.remove(listener);
  }
}
