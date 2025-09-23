import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';

class TabConfig {
  final String title;
  final IconData icon;
  final bool isGrid;
  final String endpoint;
  final List<FieldConfig>? fields;
  final List<FieldConfig>? gridFieldConfigs;
  final Function(dynamic)? fromJson;
  final Map<String, dynamic> Function(dynamic)? toJson;
  final Widget Function(dynamic item, SecurityCheck hasPermission)?
  detailScreenBuilder;

  TabConfig({
    required this.title,
    required this.icon,
    required this.isGrid,
    required this.endpoint,
    this.fields,
    this.gridFieldConfigs,
    this.fromJson,
    this.toJson,
    this.detailScreenBuilder,
  });
}
