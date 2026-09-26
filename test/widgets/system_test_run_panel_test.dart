import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/services/system_test_run_service.dart';
import 'package:task_manager_flutter/widgets/system_test_run_panel.dart';

void main() {
  testWidgets('executar tudo envia o grupo TODOS em homologacao',
      (tester) async {
    Map<String, dynamic>? startBody;
    final service = SystemTestRunService(client: MockClient((request) async {
      if (request.method == 'POST' && request.url.path.endsWith('/runs')) {
        startBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(_run('RUNNING')), 202);
      }
      if (request.url.path.endsWith('/events')) {
        return http.Response('[]', 200);
      }
      return http.Response(jsonEncode(_run('COMPLETED')), 200);
    }));

    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
            body: SystemTestRunPanel(service: service, token: 'token-test'))));

    await tester.tap(find.byKey(const Key('system_test_group_selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tudo: fases 1 e 2').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('system_test_start_button')));
    await tester.pumpAndSettle();

    expect(startBody, {
      'environment': 'HOMOLOGACAO',
      'groups': ['TODOS']
    });
  });
}

Map<String, dynamic> _run(String status) => {
      'runId': 'run-widget',
      'marker': 'E2E-WIDGET',
      'environment': 'HOMOLOGACAO',
      'status': status,
      'progressPercent': status == 'COMPLETED' ? 100 : 1,
      'totalOperations': 10,
      'completedOperations': status == 'COMPLETED' ? 10 : 1,
      'successCount': status == 'COMPLETED' ? 10 : 1,
      'failureCount': 0,
      'cleanedCount': status == 'COMPLETED' ? 2 : 0,
      'residueCount': 0,
    };
