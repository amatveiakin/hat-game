import 'dart:io';
import 'dart:math';

import 'package:meta/meta.dart';

import 'common.dart';

class RussianWord extends Word {
  final double rarityFactor;
  final double specificityFactor;
  final double nastinessFactor;
  final double lengthFactor;

  List<double> get factors =>
      [rarityFactor, specificityFactor, nastinessFactor, lengthFactor];

  double get difficulty => factors.reduce((a, b) => a * b);

  RussianWord(
    String text, {
    @required this.rarityFactor,
    @required this.specificityFactor,
    @required this.nastinessFactor,
    @required this.lengthFactor,
  }) : super(text);

  @override
  String describe() {
    return '${text.padRight(20)} ' +
        factors.map((f) => f.toStringAsFixed(3)).join(' * ') +
        ' = ${difficulty.toStringAsFixed(3)}';
  }
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

RussianWord makeWord(FreqrncRec rec) {
  final double rarityFactor = 1.0 / rec.ipm; // typically ~1
  final double specificityFactor = 1.0 + (100 - rec.d) / 20.0;
  final String text = rec.text;
  assert(text.toLowerCase() == text);

  double nastinessFactor = 1.0;
  // Nominalization suspected
  if (text.endsWith('ая') || text.endsWith('ое') || text.endsWith('ый')) {
    nastinessFactor *= 4.0;
  }
  // Diminutive suspected
  if (text.endsWith('ик') || text.endsWith('ек') || text.endsWith('ок')) {
    nastinessFactor *= 4.0;
  }
  // Nasty diminutive suspected
  if (text.endsWith('це') || text.endsWith('цо')) {
    nastinessFactor *= 8.0;
  }

  double lengthFactor = 1.0 + max(0, text.length - 4) / 10.0;

  return RussianWord(
    text,
    rarityFactor: rarityFactor,
    specificityFactor: specificityFactor,
    nastinessFactor: nastinessFactor,
    lengthFactor: lengthFactor,
  );
}

// Parser for http://dict.ruslang.ru/freq.php
Future<void> makeRussianDictionaries(String filename) async {
  final List<String> lines = File(filename).readAsLinesSync();
  lines.removeAt(0); // skip header

  const int numBuckets = 4;
  final buckets = List<List<RussianWord>>.generate(numBuckets, (_) => []);
  for (final String line in lines) {
    final FreqrncRec rec = parseFreqrncRec(line);
    if (rec.pos != 's') {
      continue; // skip everything except common nouns
    }
    final RussianWord word = makeWord(rec);
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

  final String lastUpdated = now();
  await File('russian_easy.yaml').writeAsString(dumpBucket(
    buckets[0],
    name: 'Простые слова',
    lastUpdated: lastUpdated,
  ));
  await File('russian_medium.yaml').writeAsString(dumpBucket(
    buckets[1],
    name: 'Средние слова',
    lastUpdated: lastUpdated,
  ));
  await File('russian_hard.yaml').writeAsString(dumpBucket(
    buckets[2],
    name: 'Сложные слова',
    lastUpdated: lastUpdated,
  ));

  exit(0);
}
