import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';

class KickedScreen extends StatelessWidget {
  static const String routeName = '/kicked';

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        title: Text(tr('hat_game')),
      ),
      body: Center(
        child: Text(
          tr('you_have_been_kicked'),
          style: TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }
}
