import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

class Sounds {
  static Soundpool? _soundpool;

  static int timeOver = -1;
  static int bonusTimeOver = -1;
  static List<int> wordGuessedCombo = [-1];

  static Future<void> init() async {
    try {
      await _initImpl().timeout(const Duration(seconds: 3));
      debugPrint('Sounds loaded successfully.');
    } catch (e) {
      _soundpool = null;
      // TODO: Firebase log.
      debugPrint("Couldn't initialize sounds!");
      debugPrint('The error was: $e');
    }
  }

  static Future<void> _initImpl() async {
    const options = SoundpoolOptions(
      // Default maxStreams is 1, which seems very low. E.g. it's quite possible
      // for "word guessed" and "round over" sounds to overlap.
      maxStreams: 4,
    );
    _soundpool = Soundpool.fromOptions(options: options);
    timeOver = await _load('sounds/time_over.ogg');
    bonusTimeOver = await _load('sounds/bonus_time_over.ogg');
    wordGuessedCombo = [
      await _load('sounds/word_guessed_combo0.ogg'),
      await _load('sounds/word_guessed_combo1.ogg'),
      await _load('sounds/word_guessed_combo2.ogg'),
      await _load('sounds/word_guessed_combo3.ogg'),
      await _load('sounds/word_guessed_combo4.ogg'),
    ];
  }

  static void play(int sound) async {
    await _soundpool?.play(sound);
  }

  static Future<int> _load(String path) async {
    final asset = await rootBundle.load(path);
    return await _soundpool!.load(asset);
  }
}
