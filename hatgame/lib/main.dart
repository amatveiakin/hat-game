import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/about_screen.dart';
import 'package:hatgame/app_settings.dart';
import 'package:hatgame/lexicon.dart';
import 'package:hatgame/local_storage.dart';
import 'package:hatgame/rules_screen.dart';
import 'package:hatgame/start_game_online_screen.dart';
import 'package:hatgame/start_screen.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/ntp_time.dart';
import 'package:hatgame/util/sounds.dart';

Future<void> _initFirestore() async {
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyBX7jo-zBfl0EKR6s7-ph4NhifkhIPzvzw",
          authDomain: "hatgame.firebaseapp.com",
          databaseURL: "https://hatgame.firebaseio.com",
          projectId: "hatgame",
          storageBucket: "hatgame.appspot.com",
          messagingSenderId: "761993928349",
          appId: "1:761993928349:web:a9f63af19ae7b1c9b87e74",
          measurementId: "G-TNXGM73WRF"));

  // Enable offline mode. This is the default for Android and iOS, but
  // on web it need to be enabled explicitly:
  // https://firebase.google.com/docs/firestore/manage-data/enable-offline
  FirebaseFirestore.instance.settings =
      FirebaseFirestore.instance.settings.copyWith(persistenceEnabled: true);
}

Future<void> _initApp() async {
  await _initFirestore();
  await EasyLocalization.ensureInitialized();
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
  final String? language = LocalStorage.instance.get<String?>(LocalColLocale());
  runApp(
    EasyLocalization(
      useOnlyLangCode: true,
      supportedLocales: [Locale('en'), Locale('ru')],
      fallbackLocale: Locale('en'),
      startLocale: language == null ? null : Locale(language),
      path: 'translations',
      assetLoader: YamlAssetLoader(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  Route<dynamic>? _generateRoute(RouteSettings settings) {
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
        // TODO: Why is selected tab highlight color still blue?
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: MyTheme.primary,
          primaryColorDark: MyTheme.primaryDark,
          accentColor: MyTheme.accent,
        ),
      ),
      title: tr('hat_game'),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // Use dashes for route names. Route names become urls on web, and Google
      // recommendations suggest to use punctuation and to prefer dashes over
      // underscores: https://support.google.com/webmasters/answer/76329.
      initialRoute: StartScreen.routeName,
      routes: {
        StartScreen.routeName: (context) => StartScreen(),
        AppSettingsView.routeName: (context) => AppSettingsView(context),
        AboutScreen.routeName: (context) => AboutScreen(),
        RulesScreen.routeName: (context) => RulesScreen(),
      },
      onGenerateRoute: _generateRoute,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
    );
  }
}
