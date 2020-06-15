import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/about_screen.dart';
import 'package:hatgame/lexicon.dart';
import 'package:hatgame/local_storage.dart';
import 'package:hatgame/rules_screen.dart';
import 'package:hatgame/start_game_online_screen.dart';
import 'package:hatgame/start_screen.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/ntp_time.dart';
import 'package:hatgame/util/sounds.dart';

void _initFirestore() {
  // Enable offline mode. This is the default for Android and iOS, but
  // on web it need to be enabled explicitly:
  // https://firebase.google.com/docs/firestore/manage-data/enable-offline
  Firestore.instance.settings(persistenceEnabled: true);
}

Future<void> _initApp() async {
  _initFirestore();
  await Lexicon.init(); // loading text resource: should never fail
  // TODO: Start all init-s in parallel, with a common timeout.
  await LocalStorage.init();
  await Sounds.init();
  await NtpTime.init();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Display a splash screen with a loading indicator.
  await _initApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Route<dynamic> _generateRoute(RouteSettings settings) {
    final joinGameScreen = JoinGameOnlineScreen.fromRoute(settings);
    return joinGameScreen == null
        ? null
        : MaterialPageRoute(
            builder: (context) => joinGameScreen,
            settings: settings,
          );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // Increase default font sizes
        textTheme: Theme.of(context).textTheme.apply(fontSizeDelta: 2.0),
        primaryColor: MyTheme.primary,
        primaryColorDark: MyTheme.primaryDark,
        accentColor: MyTheme.accent,
      ),
      title: 'Hat Game',
      // Use dashes for route names. Route names become urls on web, and Google
      // recommendations suggest to use punctuation and to prefer dashes over
      // underscores: https://support.google.com/webmasters/answer/76329.
      initialRoute: StartScreen.routeName,
      routes: {
        StartScreen.routeName: (context) => StartScreen(),
        AboutScreen.routeName: (context) => AboutScreen(),
        RulesScreen.routeName: (context) => RulesScreen(),
      },
      onGenerateRoute: _generateRoute,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics()),
      ],
    );
  }
}
