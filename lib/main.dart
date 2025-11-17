import 'package:flutter/material.dart';
import 'package:task_manager_flutter/app.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  AppLogger.i.initCapture();
  runApp(const ProviderScope(child: TaskManagerApp()));
}
