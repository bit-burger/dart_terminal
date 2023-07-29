import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:ansi_escapes/ansi_escapes.dart';
import 'package:path/path.dart' as path;
import 'package:dart_tui/dart_tui.dart' as dart_tui;
import 'dart:ffi' as ffi;

// FFI signature of the hello_world C function
typedef HelloWorldFunc = ffi.Void Function();
// Dart type definition for calling the C foreign function
typedef HelloWorld = void Function();

late final HelloWorld hello;

void setup() {
  var libraryPath =
      path.join(Directory.current.path, 'hello_library', 'libhello.so');

  if (Platform.isMacOS) {
    libraryPath =
        path.join(Directory.current.path, 'hello_library', 'libhello.dylib');
  }

  if (Platform.isWindows) {
    libraryPath = path.join(
        Directory.current.path, 'hello_library', 'Debug', 'hello.dll');
  }

  final dylib = ffi.DynamicLibrary.open(libraryPath);

// Look up the C function 'hello_world'
  hello = dylib
      .lookup<ffi.NativeFunction<HelloWorldFunc>>('hello_world')
      .asFunction();
// Call the function
  hello();
}

Future<void> main(List<String> arguments) async {
  print(ProcessSignal.sigwinch.watch().isBroadcast);
  // setup();
  // hello();
  // stdout.write(ansiEscapes.clearScreen);
  Process.run("/usr/bin/tput", ["civis"]);
  stdout.writeln("asdfadfasdf");
  stdout.writeln("asdfadfasdf");
  stdout.write(ansiEscapes.link('https://github.com', 'github'));

  ProcessSignal.sigwinch.watch().listen((event) {
    stdout.write(ansiEscapes.clearScreen);
    for (var i = 0; i < stdout.terminalLines ~/ 2 - 2; i++) {
      print("");
    }
    print('${stdout.terminalLines} x ${stdout.terminalColumns}');
    print("a" * stdout.terminalColumns * 2);
    stdout.write(ansiEscapes.cursorMove(
        stdout.terminalColumns, stdout.terminalLines + 1));
  });
  void main() {
    ProcessSignal.sigint.watch().listen((ProcessSignal signal) {
      hello();
      exit(0);
    });
  }
  stdin.echoMode = false;
  stdin.lineMode = false;
  stdin.transform(utf8.decoder).listen((event) {
    // stdout.write(event);
  });

  // stdin.listen((event) {
  //   stdout.write(ansiEscapes.scrollDown);
  // });

  Timer.run(() {});
  //TimelineTask

  await Future.delayed(Duration(milliseconds: 2000));
}
