import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownUtil {
  static String joinParagraphs(String text) {
    final regExp = RegExp('(?<!\n)\n(?!\n)', multiLine: true);
    return text.replaceAll(regExp, ' ');
  }

  static MarkdownStyleSheet defaultStyle(BuildContext context) {
    final baseSheet = MarkdownStyleSheet.fromTheme(Theme.of(context));
    return baseSheet.copyWith(
      // Make padding before the header larger than after.
      h1: baseSheet.h1.copyWith(height: 2.0),
      h2: baseSheet.h2.copyWith(height: 2.0),
      h3: baseSheet.h3.copyWith(fontWeight: FontWeight.w500),
    );
  }

  static Future<void> onLinkTapped(BuildContext context, String href) async {
    const String internalPrefix = 'internal:';
    if (href.startsWith(internalPrefix)) {
      final String route = href.substring(internalPrefix.length);
      Navigator.of(context).pushNamed(route);
    } else {
      await launch(href);
    }
  }
}
