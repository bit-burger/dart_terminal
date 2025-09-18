import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Load ncurses library
final ncurses = DynamicLibrary.open('libncurses.so');

// Bind functions
final initscr = ncurses.lookupFunction<Void Function(), void Function()>(
  'initscr',
);
final endwin = ncurses.lookupFunction<Void Function(), void Function()>(
  'endwin',
);

void main() {
  final a = "a";
  switch (a) {
    case "a":
      print("wuff");
    case "b":
      print("miaow");
  }
}
