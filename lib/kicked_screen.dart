import 'package:flutter/material.dart';

class KickedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
