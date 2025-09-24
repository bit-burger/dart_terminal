import 'dart:io';

import 'package:dart_tui/ansi.dart';

class ExitListener extends DefaultTerminalListener {
  @override
  void controlCharacter(ControlCharacter controlCharacter) async {
    if (controlCharacter == ControlCharacter.ctrlZ) {
      await service.destroy();
      exit(0);
    }
  }
}

final service = AnsiTerminalService.agnostic()..listener = ExitListener();
final viewport = service.viewport;

void main() async {
  await service.attach();
  service.switchToViewPortMode();
  final id = BorderDrawIdentifier();
  final style = BorderCharSet.rounded();
  viewport.drawBorderBox(
    rect: Position(5, 5) & Size(10, 10),
    style: style,
    drawId: id,
  );
  viewport.drawBorderBox(
    rect: Position(8, 8) & Size(10, 10),
    style: style,
    drawId: id,
  );
  viewport.drawBorderLine(
    from: Position(8, 10),
    to: Position(17, 10),
    style: style,
    drawId: id,
  );
  viewport.updateScreen();
}
