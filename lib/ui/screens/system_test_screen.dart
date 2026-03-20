import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/security_matrix.dart';
import 'package:task_manager_flutter/test/services/test_helper.dart';

class SystemTestScreen extends StatefulWidget {
  const SystemTestScreen({super.key});

  @override
  _SystemTestScreenState createState() => _SystemTestScreenState();
}

class _SystemTestScreenState extends State<SystemTestScreen> {
  final List<String> _logs = [];
  bool _isRunning = false;
  double _progress = 0.0;
  String _progressLabel = '';

  void _addLog(String log) {
    setState(() {
      _logs.add(log);
    });
  }

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
      _progress = 0.0;
      _progressLabel = '';
    });

    _addLog('🔵 INICIANDO TESTES DE INTEGRAÇÃO...');

    // Your test logic from full_system_crud_test.dart goes here.
    // For now, it's a placeholder.
    // You'll need to adapt the test logic to work here.

    await Future.delayed(const Duration(seconds: 2));
    _addLog('✅ Testes concluídos.');

    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testes de Integração'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _runTests,
              child: const Text('Iniciar Testes'),
            ),
            const SizedBox(height: 16),
            if (_isRunning)
              LinearProgressIndicator(
                value: _progress,
                minHeight: 10,
              ),
            if (_isRunning)
              Text(_progressLabel),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(_logs[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
