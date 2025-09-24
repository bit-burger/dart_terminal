// Dart imports:
import 'dart:io' as io;

/// Representation of terminal capabilities as defined in terminfo.
class Terminfo {
  /// Name of the terminal
  late final String name;

  /// Aliases for the terminal
  final List<String> aliases = [];

  /// Boolean capabilities
  final Set<String> booleans = {};

  /// Numeric capabilities
  final Map<String, int> numerics = {};

  /// String capabilities
  final Map<String, String> strings = {};

  Terminfo._();

  /// Attempts to get the terminfo for the current terminal by invoking `infocmp`.
  static Future<Terminfo?> tryGet() async {
    final term = io.Platform.environment['TERM'];
    if (term == null || term == '') return null;
    try {
      final result = await io.Process.run('infocmp', [term]);
      return Terminfo._().._tryParse(result.stdout.toString());
    } catch (e) {
      return null;
    }
  }

  static final _numericCapabilityRegex = RegExp(
    r'^(?<name>[a-z][a-z0-9]*)#(?<value>[0-9]+)$',
  );

  static final _stringCapabilityRegex = RegExp(
    r'^(?<name>[a-z][a-z0-9]*)=(?<value>\S+)$',
  );

  static final _booleanCapabilityRegex = RegExp(r'^[a-z][a-z0-9]*$');

  /// Parse the output of `infocmp <name>` and fill this object
  void _tryParse(String output) {
    var lines = output.split(RegExp(r'[\r\n]+'));
    lines = lines.where((line) => !line.contains(RegExp(r'^#'))).toList();
    if (lines.isEmpty) {
      throw FormatException('Empty infocmp output');
    }

    // Join remaining lines and remove line continuation
    final body = lines.join('').replaceAll(RegExp(r',\s*'), ',').trim();

    // Split by commas
    final entries = body.split(RegExp(r'(?<!\\),'));

    // Extract name and alias
    final nameEntries = entries.first.split('|');
    if (nameEntries.isEmpty) {
      throw FormatException('Empty name entries');
    }
    name = nameEntries.first;
    aliases.addAll(nameEntries.skip(1));

    entries.removeAt(0);

    for (final entry in entries) {
      if (entry.isEmpty) continue;

      // Numeric capability
      var match = _numericCapabilityRegex.firstMatch(entry);
      if (match != null) {
        final name = match.namedGroup('name')!;
        final value = int.tryParse(match.namedGroup('value')!)!;
        numerics[name] = value;
        continue;
      }
      // String capability
      match = _stringCapabilityRegex.firstMatch(entry);
      if (match != null) {
        final name = match.namedGroup('name')!;
        final value = match.namedGroup('value')!;
        strings[name] = value;
        continue;
      }
      // Boolean capability
      if (_booleanCapabilityRegex.hasMatch(entry)) {
        booleans.add(entry);
      }
    }
  }

  @override
  String toString() {
    final b = booleans.join(', ');
    final n = numerics.entries.map((e) => '${e.key}=${e.value}').join(', ');
    final s = strings.entries.map((e) => '${e.key}=${e.value}').join(', ');

    return '''
Terminal: $name
Booleans: $b
Numerics: $n
Strings: $s
''';
  }
}

void main() async {
  final info = await Terminfo.tryGet();
  print(info);
}
