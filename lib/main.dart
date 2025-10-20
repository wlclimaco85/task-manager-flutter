import 'package:flutter/material.dart';
import 'package:task_manager_flutter/app.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

void main() {
  AppLogger.i.initCapture();
  runApp(const TaskManagerApp());
}
