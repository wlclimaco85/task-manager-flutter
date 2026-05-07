// test/integration/full_system_crud_test.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';
import 'test/services/test_helper.dart';

/// Classe que representa o cenário de teste de uma tela/entidade
class CrudScenario {
  final String name;
  final String endpoint;
  final Map<String, dynamic> Function() createPayloadFactory;
  final Map<String, dynamic> Function(int id) updatePayloadFactory;
  final String idField;

  CrudScenario({
    required this.name,
    required this.endpoint,
    required this.createPayloadFactory,
    required this.updatePayloadFactory,
    this.idField = 'id',
  });
}

// Armazena o resultado de cada operação para o relatório final
final Map<String, Map<String, String>> _executionReport = {};

void _logResult(String screen, String operation, bool success,
    [String? error]) {
  if (!_executionReport.containsKey(screen)) {
    _executionReport[screen] = {};
  }
  _executionReport[screen]![operation] = success ? '✅ PASS' : '❌ FAIL';
  if (!success && error != null) {
    print('   🚨 FALHA EM $screen ($operation): $error');
  }
}

void main() {
  group('🧪 Integração Sistêmica (End-to-End)', () {
    late String token;
    late Map<String, String> headers;

    // ─────────────────────────────────────────────────────────────────────────
    // 1. SETUP: Login e Preparação
    // ─────────────────────────────────────────────────────────────────────────
    setUpAll(() async {
      print('\n🔵 INICIANDO TESTES DE INTEGRAÇÃO...');
      print('   🔑 Autenticando usuário: $kTestEmail ...');
      token = await loginAndGetToken();
      headers = authHeaders(token);
      print('   ✅ Token obtido. Iniciando bateria de testes nas telas.\n');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 2. CONFIGURAÇÃO DOS CENÁRIOS (Use seus Models.toJson() aqui)
    // ─────────────────────────────────────────────────────────────────────────

    // Gerador de data única para evitar conflitos de Unique Key no banco
    String uniqueIso() => DateTime.now().toIso8601String();
    String uniqueName(String base) =>
        '$base ${DateTime.now().millisecondsSinceEpoch}';

    final scenarios = [
      // --- CALENDÁRIO ---
      CrudScenario(
        name: 'Calendário',
        endpoint:
            '${ApiLinks.baseUrl}/calendario', // Confirme se ApiLinks tem essa const ou use string
        createPayloadFactory: () => {
          // Exemplo: CalendarEventModel(...).toJson()
          "titulo": uniqueName("Evento Teste"),
          "descricao": "Teste Automatizado",
          "dataInicio": uniqueIso(),
          "dataFim":
              DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
          "diaTodo": false
        },
        updatePayloadFactory: (id) => {"titulo": "Evento Teste ATUALIZADO"},
      ),

      // --- CHAT ---
      CrudScenario(
        name: 'Chat (Salas)',
        endpoint: '${ApiLinks.baseUrl}/chats',
        createPayloadFactory: () => {
          "nome": uniqueName("Sala Teste"),
          "tipo": "GRUPO",
          "descricao": "Sala criada via teste automatizado"
        },
        updatePayloadFactory: (id) => {"nome": "Sala Teste UPDATE"},
      ),

      // --- COMUNICADOS ---
      CrudScenario(
        name: 'Comunicados',
        endpoint: '${ApiLinks.baseUrl}/comunicados',
        createPayloadFactory: () => {
          "titulo": "Comunicado Teste",
          "conteudo": "Teste de integração",
          "dataPublicacao": uniqueIso(),
          "prioridade": "ALTA"
        },
        updatePayloadFactory: (id) => {"titulo": "Comunicado UPDATE"},
      ),

      // --- CHAMADOS ---
      CrudScenario(
        name: 'Chamados',
        endpoint: '${ApiLinks.baseUrl}/chamados',
        createPayloadFactory: () => {
          "assunto": uniqueName("Chamado Teste"),
          "descricao": "Teste automatizado",
          "tipo": "INCIDENTE",
          "prioridade": "NORMAL"
        },
        updatePayloadFactory: (id) => {"descricao": "Descrição UPDATE"},
      ),

      // --- PARCEIROS ---
      CrudScenario(
        name: 'Parceiros',
        endpoint:
            '${ApiLinks.baseUrl}/parceiros', // Ajuste para sua rota real de parceiros
        createPayloadFactory: () => {
          // Aqui usaria ParceiroModel(...).toJson()
          "nome": uniqueName("Parceiro"),
          "razaoSocial": "Razão Social Teste",
          "cnpj": "00.000.000/0001-00",
          "email": "teste@exemplo.com",
          "ativo": true
        },
        updatePayloadFactory: (id) => {"nome": "Parceiro UPDATE"},
      ),

      // --- FINANCEIRO (PAGAR) ---
      CrudScenario(
        name: 'Contas a Pagar',
        endpoint: '${ApiLinks.baseUrl}/financeiro/pagar',
        createPayloadFactory: () => {
          "descricao": uniqueName("Conta Pagar"),
          "valor": 100.50,
          "dataVencimento": uniqueIso(),
          "status": "ABERTO"
        },
        updatePayloadFactory: (id) => {"valor": 105.00},
      ),

      // --- FINANCEIRO (RECEBER) ---
      CrudScenario(
        name: 'Contas a Receber',
        endpoint: '${ApiLinks.baseUrl}/financeiro/receber',
        createPayloadFactory: () => {
          "descricao": uniqueName("Conta Receber"),
          "valor": 200.00,
          "dataVencimento": uniqueIso(),
          "status": "PENDENTE"
        },
        updatePayloadFactory: (id) => {"valor": 210.00},
      ),

      // --- CONTAS BANCÁRIAS ---
      CrudScenario(
        name: 'Contas Bancárias',
        endpoint: '${ApiLinks.baseUrl}/financeiro/contas-bancarias',
        createPayloadFactory: () => {
          "nome": uniqueName("Banco"),
          "agencia": "0001",
          "conta": "9999-9",
          "saldoInicial": 100.00
        },
        updatePayloadFactory: (id) => {"nome": "Banco UPDATE"},
      ),

      // --- PONTO ---
      CrudScenario(
        name: 'Registro de Ponto',
        endpoint: '${ApiLinks.baseUrl}/ponto',
        createPayloadFactory: () =>
            {"dataHora": uniqueIso(), "tipo": "ENTRADA", "origem": "APP_TESTE"},
        updatePayloadFactory: (id) => {"observacao": "Ponto ajustado UPDATE"},
      ),
    ];

    // ─────────────────────────────────────────────────────────────────────────
    // 3. EXECUÇÃO DINÂMICA (Loop de Testes)
    // ─────────────────────────────────────────────────────────────────────────

    for (final scenario in scenarios) {
      group('📱 Tela: ${scenario.name}', () {
        int? createdId;

        // --- 3.1 READ (GET) ---
        test('Step 1: Fetch (GET)', () async {
          try {
            print('\n   👉 [GET] ${scenario.endpoint}');
            final response =
                await http.get(Uri.parse(scenario.endpoint), headers: headers);

            if (response.statusCode == 200) {
              _logResult(scenario.name, 'GET', true);
            } else {
              _logResult(scenario.name, 'GET', false,
                  '${response.statusCode} - ${response.body}');
              fail('Status ${response.statusCode}');
            }
          } catch (e) {
            _logResult(scenario.name, 'GET', false, e.toString());
            rethrow;
          }
        });

        // --- 3.2 CREATE (POST) ---
        test('Step 2: Insert (POST)', () async {
          try {
            final payload = withAudit(scenario.createPayloadFactory());
            print('   👉 [POST] Enviando payload...');

            final response = await http.post(
              Uri.parse(scenario.endpoint),
              headers: headers,
              body: jsonEncode(payload),
            );

            if (response.statusCode == 200 || response.statusCode == 201) {
              final body = jsonDecode(response.body);
              // Tenta localizar o ID em diferentes padrões de API
              createdId = body[scenario.idField] ??
                  body['data']?[scenario.idField] ??
                  body['dados']?[scenario.idField] ??
                  body['id']; // fallback

              if (createdId != null) {
                print('      ✅ Criado com ID: $createdId');
                _logResult(scenario.name, 'POST', true);
              } else {
                _logResult(
                    scenario.name, 'POST', false, 'ID não retornado: $body');
                fail('Objeto criado mas ID não encontrado na resposta.');
              }
            } else {
              _logResult(scenario.name, 'POST', false,
                  '${response.statusCode} - ${response.body}');
              fail('Falha no POST: ${response.statusCode}');
            }
          } catch (e) {
            _logResult(scenario.name, 'POST', false, e.toString());
            rethrow;
          }
        });

        // --- 3.3 UPDATE (PUT) ---
        test('Step 3: Update (PUT)', () async {
          if (createdId == null) {
            _logResult(scenario.name, 'PUT', false, 'Skipped (No ID)');
            markTestSkipped('Sem ID para atualizar');
            return;
          }

          try {
            final payload = withAudit({
              ...scenario.updatePayloadFactory(createdId!),
              scenario.idField: createdId
            });

            final url = Uri.parse('${scenario.endpoint}/$createdId');
            print('   👉 [PUT] Atualizando ID $createdId...');

            final response = await http.put(url,
                headers: headers, body: jsonEncode(payload));

            if (response.statusCode == 200 || response.statusCode == 204) {
              _logResult(scenario.name, 'PUT', true);
            } else {
              _logResult(scenario.name, 'PUT', false,
                  '${response.statusCode} - ${response.body}');
              fail('Falha no PUT');
            }
          } catch (e) {
            _logResult(scenario.name, 'PUT', false, e.toString());
            rethrow;
          }
        });

        // --- 3.4 DELETE (DELETE) ---
        test('Step 4: Delete (DEL)', () async {
          if (createdId == null) {
            _logResult(scenario.name, 'DEL', false, 'Skipped (No ID)');
            markTestSkipped('Sem ID para deletar');
            return;
          }

          try {
            final url = Uri.parse('${scenario.endpoint}/$createdId');
            print('   👉 [DEL] Removendo ID $createdId...');

            final response = await http.delete(url, headers: headers);

            if (response.statusCode == 200 || response.statusCode == 204) {
              _logResult(scenario.name, 'DEL', true);
            } else {
              _logResult(scenario.name, 'DEL', false, '${response.statusCode}');
              fail('Falha no DELETE');
            }
          } catch (e) {
            _logResult(scenario.name, 'DEL', false, e.toString());
            rethrow;
          }
        });
      });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 4. RELATÓRIO FINAL (TearDown)
    // ─────────────────────────────────────────────────────────────────────────
    tearDownAll(() {
      print(
          '\n\n=============================================================');
      print('📊 RELATÓRIO DE EXECUÇÃO - INTEGRAÇÃO (End-to-End)');
      print('=============================================================');
      print('| Tela                   | GET  | POST | PUT  | DEL  |');
      print('|------------------------|------|------|------|------|');

      _executionReport.forEach((screen, ops) {
        final get = ops['GET'] ?? ' -- ';
        final post = ops['POST'] ?? ' -- ';
        final put = ops['PUT'] ?? ' -- ';
        final del = ops['DEL'] ?? ' -- ';

        // Formatação básica de colunas
        final screenCol = screen.padRight(22).substring(0, 22);

        print('| $screenCol | $get | $post | $put | $del |');
      });
      print('=============================================================\n');
    });
  });
}
