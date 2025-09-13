import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Load ncurses library
final ncurses = DynamicLibrary.open('libncurses.so');

// Bind functions
final initscr = ncurses.lookupFunction<Void Function(), void Function()>('initscr');
final endwin = ncurses.lookupFunction<Void Function(), void Function()>('endwin');

void main() {
  initscr();
  // ... use ncurses functions via FFI
  endwin();
ist}