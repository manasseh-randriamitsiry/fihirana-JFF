import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemUiOverlayStyleWrapper extends StatelessWidget {
  final Widget child;

  const SystemUiOverlayStyleWrapper({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
      statusBarBrightness: Theme.of(context).brightness == Brightness.dark
          ? Brightness.dark
          : Brightness.light,
    ));

    return child;
  }
}
