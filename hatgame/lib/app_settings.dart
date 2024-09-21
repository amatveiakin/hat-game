import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/local_storage.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/local_str.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';
import 'package:hatgame/widget/enum_option_selector.dart';

List<OptionItem<String?>> languageOptions() {
  return [
    OptionChoice(
      value: null,
      title: LocalStr.tr('system_default'),
    ),
    OptionDivider(),
    OptionChoice(
      value: 'en',
      title: LocalStr.raw('English'),
    ),
    OptionChoice(
      value: 'ru',
      title: LocalStr.raw('Русский'),
    ),
  ];
}

class LanguageSelector extends EnumOptionSelector<String?> {
  LanguageSelector(String? initialValue, Function changeCallback, {super.key})
      : super(
          windowTitle: LocalStr.tr('app_language'),
          allValues: languageOptions(),
          initialValue: initialValue,
          changeCallback: changeCallback,
        );

  @override
  createState() => LanguageSelectorState();
}

class LanguageSelectorState
    extends EnumOptionSelectorState<String?, LanguageSelector> {}

class AppSettingsView extends StatefulWidget {
  static const String routeName = '/app-settings';

  final BuildContext parentContext;

  const AppSettingsView(this.parentContext, {super.key});

  @override
  createState() => AppSettingsViewState();
}

class AppSettingsViewState extends State<AppSettingsView> {
  String? language;

  void updateLanguage(String? newValue) {
    setState(() {
      language = newValue;
    });
    LocalStorage.instance.set(LocalColLocale(), language);
    final BuildContext context = widget.parentContext;
    if (language != null) {
      final locale = Locale(language!);
      Assert.isIn(locale, context.supportedLocales);
      context.setLocale(locale);
    } else {
      context.resetLocale();
    }
  }

  @override
  void initState() {
    super.initState();
    language = LocalStorage.instance.get<String?>(LocalColLocale());
    if (optionWithValue(languageOptions(), language) == null) {
      language = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
        appBar: AppBar(
          title: Text(context.tr('app_settings')),
        ),
        body: ListView(
          children: [
            OptionSelectorHeader(
                title: Text(context.tr('language') +
                    optionWithValue(languageOptions(), language)!
                        .title
                        .value(context)),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => LanguageSelector(
                            language,
                            updateLanguage,
                          )));
                }),
          ],
        ));
  }
}
