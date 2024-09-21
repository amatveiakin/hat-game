import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';

class KickedScreen extends StatelessWidget {
  static const String routeName = '/kicked';

  const KickedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        title: Text(context.tr('hat_game')),
      ),
      body: Center(
        child: Text(
          context.tr('you_have_been_kicked'),
          style: const TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }
}
