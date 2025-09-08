import 'dart:convert';
import 'dart:io';

import 'package:ansi_escapes/ansi_escapes.dart';
import '../lib/ffi_system_access.dart';

const ESC = '\u001B[';
const OSC = '\u001B]';
const BEL = '\u0007';
const SEP = ';';


void main() async {
  //stdout.write(ansiEscapes.cursorHide);
  //final access = SystemAccess(baseLibraryPath: "..");
  stdin.echoMode = false;
  stdin.lineMode = false;
  //stdout.write(ESC + "6n"); // tells the core to report mouse position
  // stdout.write("\u001B[?1003h\u001B[?1015h\u001B[?1006h");
  //1015 statt 1006
  //stdout.write("\u001B[?1003;1006;1004h"); // enable mouse events
  stdout.write("\u001B[?1002h");
  stdout.write("\u001B[?1003h"); // enable mouse events
  stdout.write("\u001B[?1006h"); // whcih mouse mode
  stdout.write("\u001B[?1004h"); // enable tracking of focus
  stdout.write("\u001B[?1007h"); // scroll prevention
  final stdinCharacters = stdin/*.transform(utf8.decoder)*/;
  var i = 0;
  await for (var charList in stdinCharacters) {
    charList = [...charList];
    print(String.fromCharCodes(charList..removeAt(0)));
    if (++i == 100) {
      //break;
    }
  }
  stdout.write("\u001B[?1003;1006;1004l"); // disable mouse events
  //stdout.write(ansiEscapes.cursorShow);
}