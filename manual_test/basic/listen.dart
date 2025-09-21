import 'dart:io';

import 'package:dart_tui/ansi.dart';

List<String> buff = List.filled(1000, "", growable: true);

void _print(String nexText) {
  buff.add(nexText);
  window.drawBackground();
  for(int i = 0; i < window.size.height; i++) {
    final text = buff[buff.length - i - 1];
    window.drawText(text: text, position: Position(0, i));
  }
  window.updateScreen();
}

class ControlTerminalInputListener implements TerminalListener {
  @override
  void controlCharacter(ControlCharacter controlCharacter) async {
    _print("$controlCharacter;");
    if (controlCharacter == ControlCharacter.ctrlZ) {
      await window.destroy();
      exit(0);
    }
  }

  @override
  void input(String s) {
    _print("input('$s')");
  }

  @override
  void screenResize(Size size) {
    _print("resize(width:${size.width},height:${size.height});");
  }

  @override
  void signal(AllowedSignal signal) {
    _print("signal($signal);");
  }

  @override
  void focusChange(bool isFocused) {
    _print("focuschange($isFocused);");
  }

  @override
  void mouseEvent(MouseEvent event) {
    switch (event) {
      case MousePressEvent(
        pressType: var t,
        button: var b,
        position: var pos,
      ):
        final bs = b.toString().substring(12);
        if (t == MousePressEventType.press) {
          _print("press($bs,x:${pos.x},y:${pos.y})");
        } else {
          _print("release($bs,x:${pos.x},y:${pos.y})");
        }
      case MouseScrollEvent(xScroll: var x, yScroll: var y, position: var pos):
        _print("scroll(scrollX:$x,scrollY:$y,x:${pos.x},y:${pos.y});");
      case MouseHoverEvent(position: var pos):
        _print("motion(x:${pos.x},y:${pos.y})");
    }
  }
}

final window = AnsiTerminalWindow.agnostic(
  listener: ControlTerminalInputListener(),
);

void main() async {
  await window.attach();
  _print("start;");
}
