import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hatgame/util/markdown.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';

class RulesScreen extends StatelessWidget {
  static const String routeName = '/rules';

  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        title: Text(context.tr('hat_game_rules_title')),
      ),
      body: Markdown(
        data: context.tr('hat_game_rules_body'),
        styleSheet: MarkdownUtil.defaultStyle(context),
        onTapLink: (text, href, title) =>
            MarkdownUtil.onLinkTapped(context, href!),
      ),
    );
  }
}
