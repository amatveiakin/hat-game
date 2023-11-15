import 'package:flutter/material.dart';
import 'package:hatgame/theme.dart';

class StyledDivider extends StatelessWidget {
  const StyledDivider({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: MyTheme.primary,
      thickness: 3.0,
      height: 20.0,
    );
  }
}

class ThinDivider extends StatelessWidget {
  final double? height;

  const ThinDivider({
    super.key,
    this.height,
  });

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

  const SectionDivider({
    super.key,
    required this.title,
    this.firstSection = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6.0),
        if (!firstSection)
          const ThinDivider(
            height: 20.0,
          ),
        Row(
          children: [
            const SizedBox(width: 6.0),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
      ],
    );
  }
}
