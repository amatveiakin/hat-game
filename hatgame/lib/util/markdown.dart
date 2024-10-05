import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownUtil {
  static MarkdownStyleSheet defaultStyle(BuildContext context) {
    final baseSheet = MarkdownStyleSheet.fromTheme(Theme.of(context));
    return baseSheet.copyWith(
      h3: baseSheet.h3!.copyWith(fontWeight: FontWeight.w500),
      h1Padding: EdgeInsets.only(top: 20.0),
      h2Padding: EdgeInsets.only(top: 12.0),
      h3Padding: EdgeInsets.only(top: 8.0),
    );
  }

  static Future<void> onLinkTapped(BuildContext context, String href) async {
    const String internalPrefix = 'internal:';
    if (href.startsWith(internalPrefix)) {
      final String route = href.substring(internalPrefix.length);
      Navigator.of(context).pushNamed(route);
    } else {
      // TODO: https://pub.dev/packages/url_launcher mentions that all schemes
      // used ("https", "mailto", etc.) should be mentioned in `<queries>`
      // section in AndroidManifest.xml.
      await launchUrl(Uri.parse(href));
    }
  }
}
