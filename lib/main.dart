import 'package:fihirana/core/error/error_handler.dart';
import 'package:fihirana/features/intro/presentation/pages/app_bootstrap.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorHandler.installWidgetErrorBoundary();
  runApp(const AppBootstrap());
}
