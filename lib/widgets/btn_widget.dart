import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

import '../../utility/screen_util.dart';

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
    final inputBorderColor = theme.hintColor;
    final textColor = theme.dividerColor;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Column(
      children: [
        NeumorphicButton(
          onPressed: () {
            getHaptics();
            onTap();
          },
          style: NeumorphicStyle(
            shape: NeumorphicShape.flat,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
            depth: 8,
            intensity: 0.65,
            color: backgroundColor,
          ),
          padding: EdgeInsets.zero,
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
