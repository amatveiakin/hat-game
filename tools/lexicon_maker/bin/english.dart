import 'dart:io';

import 'package:meta/meta.dart';

import 'common.dart';

class EnglishWord extends Word {
  final int rank;

  EnglishWord(
    String text, {
    @required this.rank,
  }) : super(text);

  @override
  String describe() {
    return '${text.padRight(20)} ${rank}';
  }
}

String parseNounIndex(final String line) {
  final String phrase = line.split(' ').first;
  final List<String> words = phrase.split('_');
  if (words.length != 1) {
    return null;
  }
  final String word = words.first;
  if (word.toLowerCase() != word) {
    return null;
  }
  return words.first;
}

// Sources:
//   freqFilename: https://github.com/first20hours/google-10000-english
//   nounFilename: https://wordnet.princeton.edu/download
//              OR http://www.desiquintans.com/nounlist
Future<void> makeEnglishDictionaries(
    String freqFilename, String nounFilename) async {
  final List<String> freqLines = File(freqFilename).readAsLinesSync();
  final List<String> nounLines = File(nounFilename).readAsLinesSync();
  nounLines.removeAt(29); // skip header

  const int numBuckets = 4;
  final buckets = List<List<EnglishWord>>.generate(numBuckets, (_) => []);

  final nouns = Set<String>();
  for (final String line in nounLines) {
    final n = parseNounIndex(line);
    if (n != null) {
      nouns.add(n);
    }
  }

  int rank = 0;
  for (final String text in freqLines) {
    rank++;
    if (!nouns.contains(text)) {
      continue; // skip everything except common nouns
    }
    final word = EnglishWord(text, rank: rank);
    int bucket = rank > 4000 ? 2 : rank > 1000 ? 1 : 0;
    buckets[bucket].add(word);
  }

  for (final b in buckets) {
    b.sort((w1, w2) => w1.text.compareTo(w2.text));
  }

  print('Found words:\n' +
      describeBucket('Easy', buckets[0]) +
      describeBucket('Medium', buckets[1]) +
      describeBucket('Hard', buckets[2]) +
      describeBucket('Impossible', buckets[3]));

  final String lastUpdated = now();
  await File('english_easy.yaml').writeAsString(dumpBucket(
    buckets[0],
    name: 'Easy words',
    lastUpdated: lastUpdated,
  ));
  await File('english_medium.yaml').writeAsString(dumpBucket(
    buckets[1],
    name: 'Medium words',
    lastUpdated: lastUpdated,
  ));
  await File('english_hard.yaml').writeAsString(dumpBucket(
    buckets[2],
    name: 'Hard words',
    lastUpdated: lastUpdated,
  ));

  exit(0);
}
