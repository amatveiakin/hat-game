import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/about_screen.dart';
import 'package:hatgame/app_settings.dart';
import 'package:hatgame/firebase_options.dart';
import 'package:hatgame/lexicon.dart';
import 'package:hatgame/local_storage.dart';
import 'package:hatgame/rules_config_view.dart';
import 'package:hatgame/rules_screen.dart';
import 'package:hatgame/start_game_online_screen.dart';
import 'package:hatgame/start_screen.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/ntp_time.dart';
import 'package:hatgame/util/sounds.dart';

Future<void> _initFirestore() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      supportedLocales: const [Locale('en'), Locale('ru')],
      fallbackLocale: const Locale('en'),
      startLocale: language == null ? null : Locale(language),
      path: 'translations',
      assetLoader: const YamlAssetLoader(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
    final buttonShape = WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: buttonBorderRadius));
    return MaterialApp(
      theme: ThemeData(
        // Increase default font sizes
        textTheme: Theme.of(context).textTheme.apply(fontSizeDelta: 2.0),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: MyTheme.primary,
          accentColor: MyTheme.secondary,
        ),
        textButtonTheme:
            TextButtonThemeData(style: ButtonStyle(shape: buttonShape)),
        elevatedButtonTheme:
            ElevatedButtonThemeData(style: ButtonStyle(shape: buttonShape)),
        outlinedButtonTheme:
            OutlinedButtonThemeData(style: ButtonStyle(shape: buttonShape)),
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
        StartScreen.routeName: (context) => const StartScreen(),
        AppSettingsView.routeName: (context) => AppSettingsView(context),
        AboutScreen.routeName: (context) => const AboutScreen(),
        RulesScreen.routeName: (context) => const RulesScreen(),
        PluraliasHelpScreen.routeName: (context) => const PluraliasHelpScreen(),
      },
      onGenerateRoute: _generateRoute,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
    );
  }
}
