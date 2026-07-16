import 'package:flutter/material.dart';
import 'package:task_manager_flutter/widgets/responsive_widget.dart';

/// Grid layout responsivo mobile-first
/// - Mobile (320px): 1 coluna
/// - Tablet (768px): 2 colunas
/// - Desktop (1024px): 3+ colunas
class ResponsiveGridLayout extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacing;
  final double? runSpacing;

  const ResponsiveGridLayout({
    required this.children,
    this.padding,
    this.spacing,
    this.runSpacing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobileBuilder: (context, width) =>
          _buildGridView(context, 1, width),
      tabletBuilder: (context, width) =>
          _buildGridView(context, 2, width),
      desktopBuilder: (context, width) =>
          _buildGridView(context, 3, width),
    );
  }

  Widget _buildGridView(BuildContext context, int crossAxisCount, double width) {
    final actualSpacing = spacing ?? 8.0;
    final actualRunSpacing = runSpacing ?? 8.0;

    return Padding(
      padding: padding ?? const EdgeInsets.all(8.0),
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: actualRunSpacing,
        crossAxisSpacing: actualSpacing,
        children: children,
      ),
    );
  }
}
