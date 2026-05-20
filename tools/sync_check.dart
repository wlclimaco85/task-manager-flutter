// ignore_for_file: avoid_print
/// Checks Web/Windows parity for platform screens.
///
/// Usage:
///   dart tools/sync_check.dart
///
/// It verifies:
/// - missing Dart files in lib/web/screens vs lib/windows/screens
/// - cross imports between Web and Windows screen folders
/// - whether MenuConfig screenIndex values are covered by both platform
///   _screens lists in bottom_navbar_screen.dart
library;


import 'dart:io';

const String kWebScreensDir = 'lib/web/screens';
const String kWindowsScreensDir = 'lib/windows/screens';
const String kWebNavbar = 'lib/web/screens/bottom_navbar_screen.dart';
const String kWindowsNavbar = 'lib/windows/screens/bottom_navbar_screen.dart';
const String kMenuConfig = 'lib/utils/menu_config.dart';

class MissingFilesResult {
  final List<String> missingInWindows;
  final List<String> missingInWeb;

  MissingFilesResult({
    required this.missingInWindows,
    required this.missingInWeb,
  });

  bool get hasIssues => missingInWindows.isNotEmpty || missingInWeb.isNotEmpty;
}

class CrossImportIssue {
  final String filePath;
  final int lineNumber;
  final String importLine;

  CrossImportIssue({
    required this.filePath,
    required this.lineNumber,
    required this.importLine,
  });
}

class CrossImportsResult {
  final List<CrossImportIssue> issues;

  CrossImportsResult({required this.issues});

  bool get hasIssues => issues.isNotEmpty;
}

class MenuEntry {
  final String id;
  final String label;
  final int screenIndex;

  MenuEntry({
    required this.id,
    required this.label,
    required this.screenIndex,
  });
}

class SidebarResult {
  final List<MenuEntry> menuItems;
  final int webScreenCount;
  final int windowsScreenCount;
  final List<String> missingInWebScreens;
  final List<String> missingInWindowsScreens;

  SidebarResult({
    required this.menuItems,
    required this.webScreenCount,
    required this.windowsScreenCount,
    required this.missingInWebScreens,
    required this.missingInWindowsScreens,
  });

  bool get hasIssues =>
      menuItems.isEmpty ||
      webScreenCount != windowsScreenCount ||
      missingInWebScreens.isNotEmpty ||
      missingInWindowsScreens.isNotEmpty;

  int get issueCount =>
      (menuItems.isEmpty ? 1 : 0) +
      (webScreenCount != windowsScreenCount ? 1 : 0) +
      missingInWebScreens.length +
      missingInWindowsScreens.length;

  int get maxScreenIndex {
    final implemented = menuItems.where((item) => item.screenIndex >= 0);
    if (implemented.isEmpty) return -1;
    return implemented
        .map((item) => item.screenIndex)
        .reduce((a, b) => a > b ? a : b);
  }
}

MissingFilesResult checkMissingFiles() {
  final webRelative = _collectDartFiles(kWebScreensDir)
      .map((f) => _relativeTo(f, kWebScreensDir))
      .toSet();
  final windowsRelative = _collectDartFiles(kWindowsScreensDir)
      .map((f) => _relativeTo(f, kWindowsScreensDir))
      .toSet();

  final missingInWindows = webRelative.difference(windowsRelative).toList()
    ..sort();
  final missingInWeb = windowsRelative.difference(webRelative).toList()
    ..sort();

  return MissingFilesResult(
    missingInWindows: missingInWindows,
    missingInWeb: missingInWeb,
  );
}

List<String> _collectDartFiles(String dir) {
  final directory = Directory(dir);
  if (!directory.existsSync()) return [];

  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path.replaceAll('\\', '/'))
      .toList()
    ..sort();
}

String _relativeTo(String filePath, String base) {
  final normalised = filePath.replaceAll('\\', '/');
  final normalBase = base.replaceAll('\\', '/');
  if (normalised.startsWith('$normalBase/')) {
    return normalised.substring(normalBase.length + 1);
  }
  return normalised;
}

CrossImportsResult checkCrossImports() {
  final issues = <CrossImportIssue>[];

  for (final filePath in _collectDartFiles(kWebScreensDir)) {
    _scanForCrossImport(filePath, 'windows/screens/', issues);
  }
  for (final filePath in _collectDartFiles(kWindowsScreensDir)) {
    _scanForCrossImport(filePath, 'web/screens/', issues);
  }

  return CrossImportsResult(issues: issues);
}

void _scanForCrossImport(
  String filePath,
  String forbiddenPattern,
  List<CrossImportIssue> issues,
) {
  final file = File(filePath);
  if (!file.existsSync()) return;

  final lines = file.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (!line.startsWith('import ')) continue;
    if (line.contains(forbiddenPattern)) {
      issues.add(
        CrossImportIssue(
          filePath: filePath.replaceAll('\\', '/'),
          lineNumber: i + 1,
          importLine: lines[i].trim(),
        ),
      );
    }
  }
}

SidebarResult checkSidebarParity() {
  final menuItems = _parseMenuItems(kMenuConfig);
  final webScreenCount = _parseScreenCount(kWebNavbar, 'List<Widget> get _screens');
  final windowsScreenCount =
      _parseScreenCount(kWindowsNavbar, 'List<Widget> _buildScreens');

  return SidebarResult(
    menuItems: menuItems,
    webScreenCount: webScreenCount,
    windowsScreenCount: windowsScreenCount,
    missingInWebScreens: _menuItemsOutsideScreenList(menuItems, webScreenCount),
    missingInWindowsScreens:
        _menuItemsOutsideScreenList(menuItems, windowsScreenCount),
  );
}

List<MenuEntry> _parseMenuItems(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) return [];

  final content = file.readAsStringSync();
  final items = <MenuEntry>[];
  final pattern = RegExp(
    r'''MenuItem\s*\(\s*id:\s*["']([^"']+)["'][\s\S]*?label:\s*["']([^"']+)["'][\s\S]*?screenIndex:\s*(-?\d+)''',
    multiLine: true,
  );

  for (final match in pattern.allMatches(content)) {
    items.add(
      MenuEntry(
        id: match.group(1)!,
        label: match.group(2)!,
        screenIndex: int.parse(match.group(3)!),
      ),
    );
  }

  return items;
}

List<String> _menuItemsOutsideScreenList(List<MenuEntry> items, int screenCount) {
  return items
      .where((item) => item.screenIndex >= screenCount)
      .map((item) => '${item.label} (index ${item.screenIndex})')
      .toList()
    ..sort();
}

int _parseScreenCount(String filePath, String marker) {
  final file = File(filePath);
  if (!file.existsSync()) return 0;

  final content = file.readAsStringSync();
  final markerIndex = content.indexOf(marker);
  if (markerIndex < 0) return 0;

  var maxCount = 0;
  var searchFrom = markerIndex;
  while (true) {
    final listStart = content.indexOf('[', searchFrom);
    if (listStart < 0) break;
    final count = _countTopLevelListItems(content, listStart);
    if (count > maxCount) maxCount = count;
    searchFrom = listStart + 1;
  }

  return maxCount;
}

int _countTopLevelListItems(String content, int listStart) {
  var squareDepth = 1;
  var parenDepth = 0;
  var braceDepth = 0;
  var count = 0;
  var hasItemContent = false;
  String? stringQuote;

  for (var i = listStart + 1; i < content.length; i++) {
    final char = content[i];
    final next = i + 1 < content.length ? content[i + 1] : '';

    if (stringQuote != null) {
      if (char == r'\') {
        i++;
        continue;
      }
      if (char == stringQuote) stringQuote = null;
      continue;
    }

    if (char == '/' && next == '/') {
      while (i < content.length && content[i] != '\n') {
        i++;
      }
      continue;
    }
    if (char == '/' && next == '*') {
      i += 2;
      while (i + 1 < content.length &&
          !(content[i] == '*' && content[i + 1] == '/')) {
        i++;
      }
      i++;
      continue;
    }

    if (char == '"' || char == "'") {
      stringQuote = char;
      hasItemContent = true;
      continue;
    }
    if (char == '[') {
      squareDepth++;
      hasItemContent = true;
      continue;
    }
    if (char == ']') {
      if (squareDepth == 1) {
        if (hasItemContent) count++;
        return count;
      }
      squareDepth--;
      continue;
    }
    if (char == '(') {
      parenDepth++;
      hasItemContent = true;
      continue;
    }
    if (char == ')') {
      if (parenDepth > 0) parenDepth--;
      continue;
    }
    if (char == '{') {
      braceDepth++;
      hasItemContent = true;
      continue;
    }
    if (char == '}') {
      if (braceDepth > 0) braceDepth--;
      continue;
    }
    if (char == ',' &&
        squareDepth == 1 &&
        parenDepth == 0 &&
        braceDepth == 0) {
      if (hasItemContent) {
        count++;
        hasItemContent = false;
      }
      continue;
    }
    if (char.trim().isNotEmpty) {
      hasItemContent = true;
    }
  }

  return count;
}

void printReport(
  MissingFilesResult missing,
  CrossImportsResult crossImports,
  SidebarResult sidebar,
) {
  final separator = '=' * 60;
  final sectionSep = '-' * 60;

  print(separator);
  print('  RELATORIO DE PARIDADE WEB / WINDOWS');
  print('  Gerado em: ${DateTime.now()}');
  print(separator);
  print('');

  print('ARQUIVOS FALTANTES');
  print(sectionSep);
  if (!missing.hasIssues) {
    print('OK: nenhum arquivo faltante encontrado.');
  } else {
    if (missing.missingInWindows.isNotEmpty) {
      print(
        'Presentes em Web mas ausentes em Windows (${missing.missingInWindows.length}):',
      );
      for (final f in missing.missingInWindows) {
        print('  [WEB->WIN] $f');
      }
    }
    if (missing.missingInWeb.isNotEmpty) {
      print('');
      print(
        'Presentes em Windows mas ausentes em Web (${missing.missingInWeb.length}):',
      );
      for (final f in missing.missingInWeb) {
        print('  [WIN->WEB] $f');
      }
    }
  }
  print('');

  print('CROSS-IMPORTS INCORRETOS');
  print(sectionSep);
  if (!crossImports.hasIssues) {
    print('OK: nenhum cross-import incorreto encontrado.');
  } else {
    print('Imports cruzados detectados (${crossImports.issues.length}):');
    for (final issue in crossImports.issues) {
      print('  ${issue.filePath}:${issue.lineNumber}');
      print('    -> ${issue.importLine}');
    }
  }
  print('');

  print('SIDEBAR / MENUCONFIG');
  print(sectionSep);
  print('MenuConfig -> ${sidebar.menuItems.length} item(s)');
  print('Maior screenIndex usado -> ${sidebar.maxScreenIndex}');
  print('Web _screens -> ${sidebar.webScreenCount} tela(s)');
  print('Windows _screens -> ${sidebar.windowsScreenCount} tela(s)');

  if (!sidebar.hasIssues) {
    print('OK: sidebar e listas de telas compativeis.');
  } else {
    if (sidebar.menuItems.isEmpty) {
      print('Nenhum MenuItem encontrado em $kMenuConfig.');
    }
    if (sidebar.webScreenCount != sidebar.windowsScreenCount) {
      final diff = sidebar.webScreenCount - sidebar.windowsScreenCount;
      final sign = diff > 0 ? '+' : '';
      print('Diferenca entre listas _screens: $sign$diff tela(s).');
    }
    if (sidebar.missingInWebScreens.isNotEmpty) {
      print('');
      print(
        'Itens do MenuConfig sem tela Web correspondente (${sidebar.missingInWebScreens.length}):',
      );
      for (final label in sidebar.missingInWebScreens) {
        print('  [MENU->WEB] $label');
      }
    }
    if (sidebar.missingInWindowsScreens.isNotEmpty) {
      print('');
      print(
        'Itens do MenuConfig sem tela Windows correspondente (${sidebar.missingInWindowsScreens.length}):',
      );
      for (final label in sidebar.missingInWindowsScreens) {
        print('  [MENU->WIN] $label');
      }
    }
  }
  print('');

  print(separator);
  final totalIssues = missing.missingInWindows.length +
      missing.missingInWeb.length +
      crossImports.issues.length +
      sidebar.issueCount;

  if (totalIssues == 0) {
    print('OK: nenhuma divergencia encontrada. Plataformas em paridade.');
  } else {
    print('ATENCAO: total de divergencias encontradas: $totalIssues');
  }
  print(separator);
}

void main() {
  print('Iniciando verificacao de paridade Web/Windows...\n');

  final missing = checkMissingFiles();
  final crossImports = checkCrossImports();
  final sidebar = checkSidebarParity();

  printReport(missing, crossImports, sidebar);

  final hasAnyIssue =
      missing.hasIssues || crossImports.hasIssues || sidebar.hasIssues;
  exit(hasAnyIssue ? 1 : 0);
}
