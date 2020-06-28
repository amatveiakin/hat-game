// Based on
//   https://github.com/aissat/easy_localization/blob/661327d9a2338ac1342380381967b4021ebe773b/lib/src/easy_localization_app.dart
// TODO: Remove this file when
//   https://github.com/aissat/easy_localization/issues/206 is fixed.

import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

//If web then import intl_browser else intl_standalone
import 'package:intl/intl_standalone.dart'
    if (dart.library.html) 'package:intl/intl_browser.dart';

void resetLocale(BuildContext context) async {
  Locale _osLocale = await _getDeviceLocale();
  Locale locale = context.supportedLocales.firstWhere(
      (locale) => _checkInitLocale(locale, _osLocale),
      orElse: () =>
          _getFallbackLocale(context.supportedLocales, context.fallbackLocale));

  context.locale = locale;
}

bool _checkInitLocale(Locale locale, Locale _osLocale) {
  // If suported locale not contain countryCode then check only languageCode
  if (locale.countryCode == null) {
    return (locale.languageCode == _osLocale.languageCode);
  } else {
    return (locale == _osLocale);
  }
}

//Get fallback Locale
Locale _getFallbackLocale(
    List<Locale> supportedLocales, Locale fallbackLocale) {
  //If fallbackLocale not set then return first from supportedLocales
  if (fallbackLocale != null) {
    return fallbackLocale;
  } else {
    return supportedLocales.first;
  }
}

// Get Device Locale
Future<Locale> _getDeviceLocale() async {
  final _deviceLocale = await findSystemLocale();
  log('Device locale $_deviceLocale', name: 'Easy Localization');
  return localeFromString(_deviceLocale);
}
