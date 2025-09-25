import 'package:dart_tui/ansi.dart';

void main() async {
  final terminalService = AnsiTerminalService.agnostic();
  terminalService.listener = TerminalListener(
    onControlCharacter: (c) async {
      if ([ControlCharacter.ctrlC, ControlCharacter.ctrlZ].contains(c)) {
        await terminalService.detach();
      }
    },
  );
  await terminalService.attach();
  terminalService.viewPortMode();
  final viewport = terminalService.viewport;
  viewport.drawColor(color: Colors.red);
  viewport.drawText(
    text: "Resize to wipe everything.",
    position: Position(10, 10),
  );
  viewport.updateScreen();
}
