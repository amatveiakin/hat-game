import 'dart:io';
import 'dart:math';

import 'package:meta/meta.dart';

import 'common.dart';

class EnglishWord extends Word {
  final int rawRank;
  final int nounListInc;
  final int gerundInc;
  final int lengthInc;

  List<int> get increments => [nounListInc, gerundInc, lengthInc];

  int get scoreRank => rawRank + increments.reduce((a, b) => a + b);

  EnglishWord(
    String text, {
    @required this.rawRank,
    @required this.nounListInc,
    @required this.gerundInc,
    @required this.lengthInc,
  }) : super(text);

  @override
  String describe() {
    return '${text.padRight(20)} ${scoreRank.toString().padLeft(5)} = '
            '${rawRank.toString().padLeft(5)} + ' +
        increments.map((f) => f.toString().padLeft(4)).join(' + ');
  }
}

final vowelRegexp = RegExp('(a|e|i|o|u|y)');

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
  return word;
}

String parseSimple(final String line) {
  assert(!line.contains(' '));
  assert(!line.contains('_'));
  if (line.toLowerCase() != line) {
    return null;
  }
  return line;
}

EnglishWord makeWord(
  final String text, {
  @required final Set<String> allNouns,
  @required final Set<String> frequentNouns,
  @required final Map<String, int> wordRanks,
}) {
  if (!allNouns.contains(text)) {
    return null; // skip everything except common nouns
  }
  if (text.length <= 2) {
    return null;
  }
  final bool hasVowels = text.contains(vowelRegexp);
  if (!hasVowels) {
    return null;
  }
  // TODO: Filter out proper nouns.

  final int rawRank = wordRanks[text] ?? 15000;
  final int nounListInc = frequentNouns.contains(text) ? 0 : 3000;
  final int gerundInc = text.endsWith('ing') ? 1000 : 0;
  final int lengthInc = max(0, (text.length - 10)) * 100;
  return EnglishWord(
    text,
    rawRank: rawRank,
    nounListInc: nounListInc,
    gerundInc: gerundInc,
    lengthInc: lengthInc,
  );
}

// Sources:
//   freqFilename: https://github.com/first20hours/google-10000-english
//   nounIndexFilename: https://wordnet.princeton.edu/download -> index.noun
//   nounListFilename http://www.desiquintans.com/nounlist
Future<void> makeEnglishDictionaries(String freqFilename,
    String nounIndexFilename, String nounListFilename) async {
  final List<String> freqLines = File(freqFilename).readAsLinesSync();
  final List<String> nounIndexLines = File(nounIndexFilename).readAsLinesSync();
  final List<String> nounListLines = File(nounListFilename).readAsLinesSync();
  nounIndexLines.removeAt(29); // skip header

  const int numBuckets = 4;
  final buckets = List<List<EnglishWord>>.generate(numBuckets, (_) => []);

  final allNouns = Set<String>();
  for (final String line in nounIndexLines) {
    final t = parseNounIndex(line);
    if (t != null) {
      allNouns.add(t);
    }
  }

  final frequentNouns = Set<String>();
  for (final String line in nounListLines) {
    final t = parseSimple(line);
    if (t != null) {
      frequentNouns.add(t);
    }
  }

  // Sanity check to verify that argument order is right.
  assert(allNouns.length > frequentNouns.length);

  final wordRanks = Map<String, int>();
  {
    int rank = 0;
    for (final String line in freqLines) {
      rank++;
      final t = parseSimple(line);
      assert(t != null);
      wordRanks[t] = rank;
    }
  }

  final candidates = frequentNouns.union(Set.of(wordRanks.keys));
  for (final text in candidates) {
    final word = makeWord(text,
        allNouns: allNouns, frequentNouns: frequentNouns, wordRanks: wordRanks);
    if (word == null) {
      continue;
    }
    final int rank = word.scoreRank;
    final int bucket =
        rank > 17000 ? 3 : rank > 10000 ? 2 : rank > 5000 ? 1 : 0;
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
