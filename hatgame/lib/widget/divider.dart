import 'package:flutter/material.dart';
import 'package:hatgame/theme.dart';

class StyledDivider extends StatelessWidget {
  StyledDivider({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: MyTheme.primary,
      thickness: 3.0,
      height: 20.0,
    );
  }
}

class ThinDivider extends StatelessWidget {
  final double height;

  ThinDivider({
    Key key,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Colors.black54,
      thickness: 0.5,
      height: height,
    );
  }
}

class SectionDivider extends StatelessWidget {
  final String title;
  final bool firstSection;

  SectionDivider({
    Key key,
    @required this.title,
    this.firstSection = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 6.0),
        if (!firstSection)
          ThinDivider(
            height: 20.0,
          ),
        Row(
          children: [
            SizedBox(width: 6.0),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.0),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.0),
      ],
    );
  }
}
