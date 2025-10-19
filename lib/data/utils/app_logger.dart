import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// ✅ AppLogger intercepta todos os prints e permite exibir, copiar e salvar logs
class AppLogger {
  static final StreamController<String> _logController =
      StreamController<String>.broadcast();
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _initialized = true;

    final spec = ZoneSpecification(print: (_, __, ___, String msg) {
      _logController.add(msg);
    });

    runZonedGuarded(() {}, (e, st) {
      _logController.add('💥 ERRO GLOBAL: $e\n$st');
    }, zoneSpecification: spec);
  }

  static Stream<String> get stream => _logController.stream;
}

/// ✅ Console flutuante de debug, com copiar, limpar e exportar logs
class FloatingConsoleOverlay extends StatefulWidget {
  const FloatingConsoleOverlay({Key? key}) : super(key: key);

  @override
  State<FloatingConsoleOverlay> createState() => _FloatingConsoleOverlayState();
}

class _FloatingConsoleOverlayState extends State<FloatingConsoleOverlay> {
  final List<String> _logs = [];
  bool _visible = false;
  Offset _position = const Offset(20, 100);

  @override
  void initState() {
    super.initState();
    AppLogger.stream.listen((msg) {
      setState(() {
        if (_logs.length > 500) _logs.removeAt(0);
        _logs.add(msg);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      if (_visible)
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: Draggable(
            feedback: _buildConsole(context),
            childWhenDragging: const SizedBox.shrink(),
            onDragEnd: (d) => setState(() => _position = d.offset),
            child: _buildConsole(context),
          ),
        ),
      Positioned(
        right: 10,
        bottom: 20,
        child: FloatingActionButton.small(
          heroTag: 'debug_console',
          onPressed: () => setState(() => _visible = !_visible),
          backgroundColor: _visible ? Colors.red : Colors.green,
          child: Icon(_visible ? Icons.close : Icons.terminal),
        ),
      ),
    ]);
  }

  Widget _buildConsole(BuildContext context) {
    final logsText = _logs.join('\n');

    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 300,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, color: Colors.greenAccent),
              const SizedBox(width: 8),
              const Text('Console de Debug',
                  style: TextStyle(color: Colors.greenAccent)),
              const Spacer(),
              IconButton(
                tooltip: 'Copiar logs',
                icon: const Icon(Icons.copy, color: Colors.blueAccent),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: logsText));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('✅ Logs copiados para a área de transferência!'),
                    duration: Duration(seconds: 2),
                  ));
                },
              ),
              IconButton(
                tooltip: 'Exportar logs (.txt)',
                icon: const Icon(Icons.save_alt, color: Colors.orangeAccent),
                onPressed: () async {
                  await _exportLogsToFile(context);
                },
              ),
              IconButton(
                tooltip: 'Limpar logs',
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                onPressed: () => setState(() => _logs.clear()),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 4),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: Text(
                logsText,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 💾 Exporta os logs atuais para um arquivo .txt
  Future<void> _exportLogsToFile(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/app_logs_${DateTime.now().millisecondsSinceEpoch}.txt');

      final logs = _logs.join('\n');
      await file.writeAsString(logs);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('💾 Logs salvos em:\n${file.path}'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Copiar caminho',
          textColor: Colors.amber,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: file.path));
          },
        ),
      ));

      print('📁 [AppLogger] Logs exportados para ${file.path}');
    } catch (e) {
      print('❌ [AppLogger] Falha ao exportar logs: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ Erro ao exportar logs: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
