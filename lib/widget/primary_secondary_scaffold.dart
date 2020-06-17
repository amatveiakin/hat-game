import 'package:flutter/material.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/widget/collapsible.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';

class PrimarySecondaryScaffold extends StatefulWidget {
  final bool primaryAutomaticallyImplyLeading;
  final Widget primary;
  final String primaryTitle;
  final String secondaryRouteName;
  final Widget secondary;
  final String secondaryTitle; // used by narrow mode only
  final Widget secondaryIcon;

  PrimarySecondaryScaffold({
    @required this.primaryAutomaticallyImplyLeading,
    @required this.primary,
    @required this.primaryTitle,
    @required this.secondaryRouteName,
    @required this.secondary,
    @required this.secondaryTitle,
    @required this.secondaryIcon,
  });

  @override
  State<StatefulWidget> createState() => _PrimarySecondaryScaffoldState();
}

class _SecondaryView extends StatelessWidget {
  final Widget body;
  final String title;

  _SecondaryView({
    @required this.body,
    @required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(title),
      ),
      body: body,
    );
  }
}

class _PrimarySecondaryScaffoldState extends State<PrimarySecondaryScaffold> {
  bool _secondaryCollapsed = true; // wide mode only

  bool get primaryAutomaticallyImplyLeading =>
      widget.primaryAutomaticallyImplyLeading;
  Widget get primary => widget.primary;
  String get primaryTitle => widget.primaryTitle;
  String get secondaryRouteName => widget.secondaryRouteName;
  Widget get secondary => widget.secondary;
  String get secondaryTitle => widget.secondaryTitle;
  Widget get secondaryIcon => widget.secondaryIcon;

  void _goToSecondary(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => _SecondaryView(
        body: secondary,
        title: secondaryTitle,
      ),
      settings: RouteSettings(name: secondaryRouteName),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const double minPrimaryWidth = 480;
    const double maxPrimaryWidth = ConstrainedScaffold.defaultWidth;
    Assert.le(minPrimaryWidth, maxPrimaryWidth);
    const double secondaryWidth = 480;
    final double minWideLayoutWidth =
        minPrimaryWidth + Collapsible.expandButtonWidth + secondaryWidth;
    final bool wideLayout =
        MediaQuery.of(context).size.width >= minWideLayoutWidth;

    if (!wideLayout) {
      // One-column view for phones and tablets in portrait mode.
      return ConstrainedScaffold(
        appBar: AppBar(
          automaticallyImplyLeading: primaryAutomaticallyImplyLeading,
          title: Text(primaryTitle),
          actions: [
            IconButton(
              icon: secondaryIcon,
              onPressed: () => _goToSecondary(context),
            )
          ],
        ),
        body: primary,
      );
    } else {
      // Two-column view for tablets in landscape mode and desktops.
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: primaryAutomaticallyImplyLeading,
          title: Text(primaryTitle),
        ),
        body: Row(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxPrimaryWidth),
                  child: primary,
                ),
              ),
            ),
            Collapsible(
              collapsed: _secondaryCollapsed,
              onCollapsedChanged: (bool c) => setState(() {
                _secondaryCollapsed = c;
              }),
              child: SizedBox(
                width: secondaryWidth,
                child: secondary,
              ),
            ),
          ],
        ),
      );
    }
  }
}
