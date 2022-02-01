import 'package:flutter/material.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/list_ext.dart';

// Two-state toggle button that looks like this:
//
//   ┏━━━━━━━━━━━━━━━━━┱─────────────────╮
//   ┃ Selected option ┃  Other option   │
//   ┗━━━━━━━━━━━━━━━━━┹─────────────────╯
//
class SwitchButton extends StatelessWidget {
  final List<String> options;
  final int selectedOption;
  final void Function(int)? onSelectedOptionChanged;

  SwitchButton({
    required this.options,
    required this.selectedOption,
    required this.onSelectedOptionChanged,
  });

  static const _height = 48.0;

  // More vivid design. Didn't suit settings page, because it was conflicting
  // with the big bottom button.
  /*
  Widget _buildOptionEnabled(
      BuildContext context, int index, String text, bool selected) {
    return Expanded(
      child: selected
          ? FlatButton(
              child: Text(
                text,
                style: Theme.of(context)
                    .textTheme
                    .subtitle1
                    .copyWith(fontWeight: FontWeight.w400),
              ),
              color: MyTheme.accent,
              onPressed: () {},
            )
          : FlatButton(
              child: Text(
                text,
                style: Theme.of(context)
                    .textTheme
                    .subtitle1
                    .copyWith(fontWeight: FontWeight.w300),
              ),
              onPressed: () => onSelectedOptionChanged?.call(index),
            ),
    );
  }
  */

  Widget _buildOptionEnabled(
      BuildContext context, int index, String text, bool selected) {
    return Expanded(
      child: selected
          ? Padding(
              padding: EdgeInsets.all(1.5),
              child: OutlineButton(
                borderSide: BorderSide(
                  color: MyTheme.accent,
                  width: 3.0,
                ),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        fontWeight: FontWeight.w400, // normal font weight
                      ),
                ),
                onPressed: () {},
              ),
            )
          : FlatButton(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.subtitle1!.copyWith(
                      fontWeight: FontWeight.w300,
                      color: Colors.black54,
                    ),
              ),
              onPressed: () => onSelectedOptionChanged?.call(index),
            ),
    );
  }

  Widget _buildOptionDisabled(
      BuildContext context, int index, String text, bool selected) {
    return Expanded(
      child: selected
          ? DecoratedBox(
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: MyTheme.accent),
                  borderRadius: BorderRadius.circular(3.0),
                ),
              ),
              child: Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .subtitle1!
                      .copyWith(fontWeight: FontWeight.w400),
                ),
              ),
            )
          : Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .subtitle1!
                    .copyWith(fontWeight: FontWeight.w300),
              ),
            ),
    );
  }

  Widget _buildEnabled(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.black12),
          borderRadius: BorderRadius.circular(3.0),
        ),
      ),
      child: SizedBox(
        height: _height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: options
              .mapWithIndex((index, value) => _buildOptionEnabled(
                  context, index, value, index == selectedOption))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDisabled(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: options
            .mapWithIndex((index, value) => _buildOptionDisabled(
                context, index, value, index == selectedOption))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return onSelectedOptionChanged != null
        ? _buildEnabled(context)
        : _buildDisabled(context);
  }
}
