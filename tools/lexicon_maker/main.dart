import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:meta/meta.dart';

class Word {
  final String text;
  final double rarityFactor;
  final double specificityFactor;
  final double nastinessFactor;

  double get difficulty => rarityFactor * specificityFactor * nastinessFactor;

  Word(
    this.text, {
    @required this.rarityFactor,
    @required this.specificityFactor,
    @required this.nastinessFactor,
  });
}

class FreqrncRec {
  final String text;
  final String pos;
  final double ipm; // (0 - 1'000'000], >= 0.4 in practice
  final int r; // (0 - 100]
  final int d; // (0 - 100]
  final int doc; // (0 - ∞)

  FreqrncRec(this.text, this.pos, this.ipm, this.r, this.d, this.doc);
}

FreqrncRec parseFreqrncRec(final String line) {
  final List<String> s = line.split('\t');
  assert(s.length == 6);
  return FreqrncRec(
    s[0],
    s[1],
    double.parse(s[2]),
    int.parse(s[3]),
    int.parse(s[4]),
    int.parse(s[5]),
  );
}

Word makeWord(FreqrncRec rec) {
  final double rarityFactor = 1.0 / rec.ipm; // typically ~1
  final double specificityFactor = 1.0 + (100 - rec.d) / 20.0;
  final String text = rec.text;
  assert(text.toLowerCase() == text);

  double nastinessFactor = 1.0;
  // Nominalization suspected
  if (text.endsWith('ая') || text.endsWith('ое') || text.endsWith('ый'))
    nastinessFactor *= 4.0;
  // Diminutive suspected
  if (text.endsWith('ик') || text.endsWith('ек') || text.endsWith('ок'))
    nastinessFactor *= 4.0;
  // Nasty diminutive suspected
  if (text.endsWith('це') || text.endsWith('цо'))
    nastinessFactor *= 8.0;

  return Word(
    text,
    rarityFactor: rarityFactor,
    specificityFactor: specificityFactor,
    nastinessFactor: nastinessFactor,
  );
}

String describeWord(Word w) {
  return '    ${w.text.padRight(20)} ${w.rarityFactor.toStringAsFixed(3)} * '
      '${w.specificityFactor.toStringAsFixed(3)} = '
      '${w.difficulty.toStringAsFixed(3)}';
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
    buffer.writeln('- ${w.text}');
  }
  return buffer.toString();
}

// Parser for http://dict.ruslang.ru/freq.php
Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.writeln('Expected one argument: path to freqrnc2011.csv');
    exit(1);
  }
  final String filename = arguments[0];

  final List<String> lines = await utf8.decoder
      .bind(File(filename).openRead())
      .transform(const LineSplitter())
      .toList();
  lines.removeAt(0); // skip header

  const int numBuckets = 4;
  final buckets = List<List<Word>>.generate(numBuckets, (_) => []);
  for (final String line in lines) {
    final FreqrncRec rec = parseFreqrncRec(line);
    if (rec.pos != 's') {
      continue; // skip everything except common nouns
    }
    final Word word = makeWord(rec);
    int bucket = word.difficulty > 10.0
        ? 3
        : word.difficulty > 2.0 ? 2 : word.difficulty > 0.25 ? 1 : 0;
    buckets[bucket].add(word);
  }

  print('Found words:\n' +
      describeBucket('Easy', buckets[0]) +
      describeBucket('Medium', buckets[1]) +
      describeBucket('Hard', buckets[2]) +
      describeBucket('Impossible', buckets[3]));

  // Extract 'yyyy-MM-dd' part from ISO-8601
  final String lastUpdated = DateTime.now().toIso8601String().substring(0, 10);
  await new File('russian_easy.yaml').writeAsString(dumpBucket(
    buckets[0],
    name: 'Простые слова',
    lastUpdated: lastUpdated,
  ));
  await new File('russian_medium.yaml').writeAsString(dumpBucket(
    buckets[1],
    name: 'Средние слова',
    lastUpdated: lastUpdated,
  ));
  await new File('russian_hard.yaml').writeAsString(dumpBucket(
    buckets[2],
    name: 'Сложные слова',
    lastUpdated: lastUpdated,
  ));

  exit(0);
}
