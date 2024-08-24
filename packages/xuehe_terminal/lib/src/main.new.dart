import 'package:advanced_terminal/src/style/style.dart';
import 'dart:io';
import 'package:advanced_terminal/src/window/renderable/renderable.dart';
import 'package:advanced_terminal/src/window/terminal_app.dart';
import 'package:advanced_terminal/src/window/window_capabilites.dart';

import 'nterminal/codes.dart';

void main() async {
  final capabilities =
      TerminalWindowCapabilities.getPlatformCapabilityProvider();
  capabilities.transitionSGR(
    newForeground: ForegroundStyle(
      textDecorations: TextDecorationSet.empty(),
      color: BrightTerminalColor.green,
    ),
  );
  // stdout.write(CSI + BrightTerminalColor.green.termRepBackground + 'masdf');
  capabilities.write("bing bong");
  runApp(
    RenderApp(
      height: 11,
      graphics: ColoredBox(
        backgroundColor: BrightTerminalColor.red,
        child: Padding(
          padding: EdgeInsets.only(left: 10, top: 4),
          child: ColoredBox(
            backgroundColor: BrightTerminalColor.green,
            child: Text("ashdf\nasdf\nasdf", alignment: Alignment.bottomRight),
          ),
        ),
      ),
    ),
  );
}
