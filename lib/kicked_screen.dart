import 'package:flutter/material.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';

class KickedScreen extends StatelessWidget {
  static const String routeName = '/kicked';

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        title: Text('Hat Game'),
      ),
      body: Center(
        child: Text(
          "You have been kicked from this game",
          style: TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }
}
