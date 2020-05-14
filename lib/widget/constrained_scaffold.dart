import 'package:flutter/material.dart';

// A limited-width scaffold to avoid bloating on desktop. Limits only the
// body width by default. To limit AppBar content width, use constrainedAppBar.
class ConstrainedScaffold extends StatelessWidget {
  static const double defaultWidth = 800.0;

  final PreferredSizeWidget appBar;
  final Widget body;
  final bool resizeToAvoidBottomInset;
  final double width;

  ConstrainedScaffold({
    @required this.appBar,
    @required this.body,
    this.resizeToAvoidBottomInset,
    this.width = defaultWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: body,
        ),
      ),
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

// AppBar with constrained content width, to be used together with
// ConstrainedScaffold.
//
// Use constrainedAppBar with care. In my opinion:
//   - Limiting AppBar title width (as well as repositioning leading and
//     actions) looks bad.
//   - Limiting TabBar width to a value only slightly smaller than screen
//     width looks bad.
// It only makes sense to limit TabBar width if content is significantly
// smaller than the screen (so you are not mislead by the fact that the
// entiry app body is under the middle tab, for example). But this never
// happens if layout is adjusting to screen width and uses non-tabular
// representation format on wide screen.
/*
AppBar constrainedAppBar({
  // TODO: Find a way to sync this with ConstrainedScaffold automatically.
  // May be context.findAncestorWidgetOfExactType could help?
  double width = ConstrainedScaffold.defaultWidth,
  Widget leading,
  bool automaticallyImplyLeading,
  Widget title,
  List<Widget> actions,
  Widget flexibleSpace,
  PreferredSizeWidget bottom,
}) {
  Widget constrain(Widget child, double width) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: child,
      ),
    );
  }

  return AppBar(
    leading: leading,
    automaticallyImplyLeading: automaticallyImplyLeading,
    title: title,
    actions: actions,
    flexibleSpace:
        flexibleSpace == null ? null : constrain(flexibleSpace, width),
    bottom: bottom == null
        ? null
        : PreferredSize(
            preferredSize: bottom.preferredSize,
            child: constrain(bottom, width),
          ),
  );
}
*/
