import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hatgame/util/markdown.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';

class RulesScreen extends StatelessWidget {
  static const String routeName = '/rules';

// TODO: Finish
// TODO: tr
  final String content = '''
*This is a stub.*


## Basics

The goal of hat is to explain words as quickly as possible without using
cognates.


## Variants


## Playing with the app

This app helps to streamline the game process: break participants into teams,
generate words, keep track of time and score.

### Playing offline

### Playing online
''';

  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        title: Text(tr('hat_game_rules_title')),
      ),
      body: Markdown(
        data: content,
        styleSheet: MarkdownUtil.defaultStyle(context),
        selectable: true,
      ),
    );
  }
}
