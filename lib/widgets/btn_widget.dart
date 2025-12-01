import '../../utility/screen_util.dart';
import 'package:flutter/material.dart';

class BtnWidget extends StatelessWidget {
  final double inputWidth;
  final double inputHeight;
  final String text;
  final Function onTap;

  const BtnWidget({
    super.key,
    required this.inputWidth,
    required this.inputHeight,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.dividerColor;

    return Column(
      children: [
        TextButton(
          onPressed: () {
            getHaptics();
            onTap();
          },
          child: SizedBox(
            width: inputWidth,
            height: inputHeight,
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
