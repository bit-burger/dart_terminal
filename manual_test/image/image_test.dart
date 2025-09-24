import 'dart:io';

import 'package:dart_tui/ansi.dart';

class ControlTerminalInputListener extends DefaultTerminalListener {
  @override
  void controlCharacter(ControlCharacter controlCharacter) async {
    if (controlCharacter == ControlCharacter.ctrlZ) {
      await service.destroy();
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

final service = AnsiTerminalService.agnostic()
  ..listener = ControlTerminalInputListener();
final viewport = service.viewport;
final marioImage = service.createImage(
  size: Size(1200, 72),
  filePath: "mario_background.png",
);
int offset = 0;
bool monaLisa = true;

void paint() {
  if (monaLisa) {
    final image = service.createImage(
      size: viewport.size,
      filePath: "mona_lisa.jpeg",
    );
    viewport.drawImage(position: Position.zero, image: image);
  } else {
    viewport.drawBackground();
    viewport.drawImage(position: Position(offset, 0), image: marioImage);
  }
  viewport.updateScreen();
}

void main() async {
  await service.attach();
  service.switchToViewPortMode();
  paint();
}
