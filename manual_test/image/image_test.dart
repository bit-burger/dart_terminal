import 'dart:io';

import 'package:dart_tui/ansi.dart';

class ControlTerminalInputListener extends DefaultTerminalListener {
  @override
  void controlCharacter(ControlCharacter controlCharacter) async {
    if (controlCharacter == ControlCharacter.ctrlZ) {
      await window.destroy();
      exit(0);
    }
    if (controlCharacter == ControlCharacter.arrowLeft) {
      offset--;
    } else if (controlCharacter == ControlCharacter.arrowRight) {
      offset++;
    } else {
      monaLisa = !monaLisa;
    }
    paint();
  }

  @override
  void screenResize(Size size) {
    paint();
  }
}

final factory = AnsiTerminalWindowFactory.agnostic();
final window = factory.createWindow(listener: ControlTerminalInputListener());
final marioImage = factory.createImage(
  size: Size(1200, 72),
  filePath: "mario_background.png",
);
int offset = 0;
bool monaLisa = true;

void paint() {
  if (monaLisa) {
    final image = factory.createImage(size: window.size, filePath: "pixelprompt.jpeg");
    window.drawImage(position: Position.zero, image: image);
  } else {
    window.drawImage(position: Position(offset, 0), image: marioImage);
  }
  window.updateScreen();
}

void main() async {
  await window.attach();
  paint();
}
