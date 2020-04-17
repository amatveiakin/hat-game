import 'package:flutter/material.dart';
import 'package:hatgame/game_view.dart';

void main() => runApp(MyApp());

class StartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hat Game'),
      ),
      body: Center(
        child: RaisedButton(
          onPressed: () {
            // TODO: remove "back" button
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => GameView()));
          },
          child: Text('New Game'),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Color(0xff4b0082),
        accentColor: Color(0xffccad00),
      ),
      title: 'Hat Game',
      home: StartScreen(),
    );
  }
}
