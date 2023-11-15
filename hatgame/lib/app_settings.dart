import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/local_storage.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';
import 'package:hatgame/widget/enum_option_selector.dart';

List<OptionDescription<String>> languageOptions() {
  return [
    OptionDescription(
      value: null,
      title: tr('system_default'),
    ),
    OptionDescription.divider(),
    OptionDescription(
      value: 'en',
      title: 'English', // no 'tr'
    ),
    OptionDescription(
      value: 'ru',
      title: 'Русский', // no 'tr'
    ),
  ];
}

class LanguageSelector extends EnumOptionSelector<String?> {
  LanguageSelector(String? initialValue, Function changeCallback, {super.key})
      : super(
          windowTitle: tr('app_language'),
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
          title: Text(tr('app_settings')),
        ),
        body: ListView(
          children: [
            OptionSelectorHeader(
                title: Text(tr('language') +
                    optionWithValue(languageOptions(), language)!.title!),
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
