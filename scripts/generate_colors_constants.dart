import 'dart:io';

void main() async {
  final input = await File('scripts/extended_colors.csv').readAsString();
  var colors = input.split("\n").map((s) => s.split(","));
  var buffer = StringBuffer();
  buffer.write("""
import 'style.dart'; 
 
// GENERATED CODE - DO NOT MODIFY BY HAND
// generated via scripts/generate_color_constants.dart
// ignore_for_file: constant_identifier_names

/// Utility class providing named constants for ANSI colors.
abstract final class Colors { 
  /// The standard 16 ANSI colors.
  ///
  /// See [Color.ansi].
  static const black = Color.ansi(0);
  static const red = Color.ansi(1);
  static const green = Color.ansi(2);
  static const yellow = Color.ansi(3);
  static const blue = Color.ansi(4);
  static const magenta = Color.ansi(5);
  static const cyan = Color.ansi(6);
  static const white = Color.ansi(7);
  static const brightBlack = Color.ansi(8);
  static const brightRed = Color.ansi(9);
  static const brightGreen = Color.ansi(10);
  static const brightYellow = Color.ansi(11);
  static const brightBlue = Color.ansi(12);
  static const brightMagenta = Color.ansi(13);
  static const brightCyan = Color.ansi(14);
  static const brightWhite = Color.ansi(15);
  
  /// The extended 256 ANSI colors commonly known as xterm-256 colors.
  /// However missing the first 16 colors which are available
  /// above and use [Color.ansi].
  ///
  /// See [Color.extended].""");
  buffer.writeln("");
  for (var color in colors) {
    final colorNumber = int.parse(color[0]);
    final alt = int.parse(color[5]);
    var name = color[1];
    if (alt > 0) {
      name = "${name}_alt$alt";
    }
    buffer.writeln(
      "  static const Color $name = Color.extended($colorNumber);",
    );
  }
  buffer.writeln("}");

  final outFile = File('lib/src/core/colors.dart');
  if (await outFile.exists()) {
    await outFile.delete();
  }
  await outFile.writeAsString(buffer.toString());
}
