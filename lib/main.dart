import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hat Game',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Hat Game'),
        ),
        body: Center(
          child: Text('Hello World'),
        ),
      ),
    );
  }
}
