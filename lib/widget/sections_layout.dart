import 'package:flutter/material.dart';
import 'package:hatgame/theme.dart';

class SectionTitleData {
  final String text;
  final Icon icon;

  SectionTitleData({this.text, this.icon});
}

class SectionData {
  final SectionTitleData title;
  final Widget body;

  SectionData({@required this.title, @required this.body});
}

class SectionsView extends StatelessWidget {
  final bool appBarAutomaticallyImplyLeading;
  final String appTitle;
  final bool appTitlePresentInNarrowMode;
  final List<SectionData> sections;
  final TabController tabController;
  final Widget bottonWidget;

  SectionsView({
    @required this.appBarAutomaticallyImplyLeading,
    @required this.appTitle,
    @required this.appTitlePresentInNarrowMode,
    @required this.sections,
    @required this.tabController,
    this.bottonWidget,
  });

  @override
  Widget build(BuildContext context) {
    const double boxWidth = 480;
    const double boxMargin = 16;
    final double wideLayoutWidth = (boxWidth + 2 * boxMargin) * sections.length;
    final bool wideLayout =
        MediaQuery.of(context).size.width >= wideLayoutWidth;

    if (!wideLayout) {
      // One-column view for phones and tablets in portrait mode.
      // TODO: Limit column width. Create LimitedWidthScaffold class
      // and use it here as well as for screens without sections.
      final tabBar = TabBar(
        controller: tabController,
        tabs: sections
            .map((s) => Tab(
                  text: s.title.text,
                  icon: s.title.icon,
                ))
            .toList(),
      );
      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: appTitlePresentInNarrowMode
            ? AppBar(
                automaticallyImplyLeading: appBarAutomaticallyImplyLeading,
                title: Text(appTitle),
                // For some reason PreferredSize affects not only the bottom of
                // the AppBar but also the title, making it misaligned with the
                // normal title text position. Hopefully this is not too
                // noticeable. Without PreferredSize the AppBar is just too fat.
                bottom: PreferredSize(
                    preferredSize: Size.fromHeight(64.0), child: tabBar),
              )
            : PreferredSize(
                preferredSize: Size.fromHeight(64.0),
                child: AppBar(
                  automaticallyImplyLeading: appBarAutomaticallyImplyLeading,
                  flexibleSpace: SafeArea(child: tabBar),
                ),
              ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: sections.map((s) => s.body).toList(),
              ),
            ),
            if (bottonWidget != null) bottonWidget,
          ],
        ),
      );
    } else {
      final boxes = List<Widget>();
      for (int i = 0; i < sections.length; i++) {
        boxes.add(
          Padding(
            padding: EdgeInsets.all(boxMargin),
            child: SizedBox(
              width: boxWidth,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: MyTheme.primary,
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        sections[i].title.text,
                        // Use the same text style as AppBar.
                        // TODO: Why is font bigger than in actual AppBar?
                        style: Theme.of(context).textTheme.headline6.copyWith(
                              // TODO: Take color from the theme.
                              color: Colors.white,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: sections[i].body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      // Multi-column view for tablets in landscape mode and desktops.
      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          automaticallyImplyLeading: appBarAutomaticallyImplyLeading,
          title: Text(appTitle),
        ),
        body: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: boxes,
              ),
            ),
            if (bottonWidget != null)
              SizedBox(
                width: wideLayoutWidth,
                child: bottonWidget,
              )
          ],
        ),
      );
    }
  }
}