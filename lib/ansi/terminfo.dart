import 'dart:io';

class Terminfo {
  late final String name;
  final List<String> aliases = [];
  final Set<String> booleans = {};
  final Map<String, int> numerics = {};
  final Map<String, String> strings = {};

  Terminfo._();

  static Future<Terminfo?> tryGet() async {
    final term = Platform.environment['TERM'];
    if (term == null || term == '') return null;
    try {
      final result = await Process.run('infocmp', [term]);
      return Terminfo._().._tryParse(result.stdout.toString());
    } catch (e) {
      return null;
    }
  }

  static final numericCapabilityRegex = RegExp(
    r'^(?<name>[a-z][a-z0-9]*)#(?<value>[0-9]+)$',
  );

  static final stringCapabilityRegex = RegExp(
    r'^(?<name>[a-z][a-z0-9]*)=(?<value>\S+)$',
  );

  static final booleanCapabilityRegex = RegExp(r'^[a-z][a-z0-9]*$');

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
      var match = numericCapabilityRegex.firstMatch(entry);
      if (match != null) {
        final name = match.namedGroup('name')!;
        final value = int.tryParse(match.namedGroup('value')!)!;
        numerics[name] = value;
        continue;
      }
      // String capability
      match = stringCapabilityRegex.firstMatch(entry);
      if (match != null) {
        final name = match.namedGroup('name')!;
        final value = match.namedGroup('value')!;
        strings[name] = value;
        continue;
      }
      // Boolean capability
      if (booleanCapabilityRegex.hasMatch(entry)) {
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
