import 'dart:convert';
import 'dart:io';

import 'package:ansi_escapes/ansi_escapes.dart';
import 'package:ffi_system_access/ffi_system_access.dart';

const ESC = '\u001B[';
const OSC = '\u001B]';
const BEL = '\u0007';
const SEP = ';';


void main() async {
  stdout.write(ansiEscapes.cursorHide);
  final access = SystemAccess(baseLibraryPath: "..");
  stdin.echoMode = false;
  stdin.lineMode = false;
  stdout.write(ESC + "6n");
  final stdinCharacters = stdin/*.transform(utf8.decoder)*/;
  var i = 0;
  await for (final character in stdinCharacters) {
    print(character);
    if (++i == 10) {
      return;
    }
  }
}