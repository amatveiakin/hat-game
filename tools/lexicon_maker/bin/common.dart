import 'package:meta/meta.dart';

abstract class Word {
  final String text;

  Word(this.text);

  String describe();
}

String describeWord(Word w) {
  return '    ${w.describe()}';
}

String describeBucket(String name, List<Word> words) {
  List<Word> wordsShuffled = List.from(words);
  wordsShuffled.shuffle();
  return '  $name (${words.length}):\n'
      '${wordsShuffled.take(15).map((w) => describeWord(w)).join('\n')}\n'
      '    ...\n';
}

String dumpBucket(
  List<Word> words, {
  @required String name,
  @required String lastUpdated,
}) {
  final buffer = StringBuffer();
  // Note. Other possible fields: author (for non-builtin); comment.
  buffer.writeln("name: '$name'");
  buffer.writeln("last_updated: $lastUpdated");
  buffer.writeln("---");
  for (final w in words) {
    // Quotes prevent YAML from interpreting strings like "yes" or "null".
    buffer.writeln('- "${w.text}"');
  }
  return buffer.toString();
}

String now() {
  // Extract 'yyyy-MM-dd' part from ISO-8601
  return DateTime.now().toIso8601String().substring(0, 10);
}
