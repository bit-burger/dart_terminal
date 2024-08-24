import 'dart:io';

import 'package:advanced_terminal/src/nterminal/codes.dart';

main() {
  stdout.write("$ESC[?1000l");

  stdin.listen((event) {
    print(event);
  });
}