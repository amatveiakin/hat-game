import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/start_screen.dart';
import 'package:hatgame/theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics analytics = FirebaseAnalytics();
    return MaterialApp(
      theme: ThemeData(
        // Increase default font sizes
        textTheme: Theme.of(context).textTheme.apply(fontSizeDelta: 2.0),
        primaryColor: MyTheme.primary,
        primaryColorDark: MyTheme.primaryDark,
        accentColor: MyTheme.accent,
      ),
      title: 'Hat Game',
      home: StartScreen(),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics()),
      ]
    );
  }
}
