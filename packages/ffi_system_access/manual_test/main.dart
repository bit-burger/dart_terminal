import 'dart:io';
import 'dart:convert' show utf8;

import 'package:ffi_system_access/ffi_system_access.dart';

void main() async {
  final access = SystemAccess(baseLibraryPath: "..");
  stdin.lineMode = false;
  access.runScript("stty -echo");
  print(
    "you cannot see your characters anymore, "
    "type 10 characters to remove this:",
  );
  final stdinCharacters = stdin.transform(utf8.decoder);
  var i = 0;
  await for (final character in stdinCharacters) {
    if (++i == 10) {
      return;
    }
  }
}
