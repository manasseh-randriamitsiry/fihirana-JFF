import 'package:fihirana/features/intro/presentation/pages/app_bootstrap.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSize = 50;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 20 << 20;
  runApp(const AppBootstrap());
}
