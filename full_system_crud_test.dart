// full_system_crud_test.dart
// Teste de integração sistêmica — cobre todas as telas/entidades do App Academia.
// Execução: flutter test full_system_crud_test.dart --dart-define=BACKEND_URL=http://127.0.0.1:9001

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/utils/api_links.dart';
import 'test/services/test_helper.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Utilitários de payload
// ═══════════════════════════════════════════════════════════════════════════

String _ts() => DateTime.now().millisecondsSinceEpoch.toString();
String _uid(String base) => '$base ${_ts()}';
String _isoNow() => DateTime.now().toIso8601String();
String _isoFuture([int hours = 1]) =>
    DateTime.now().add(Duration(hours: hours)).toIso8601String();
String _isoDate([int days = 0]) =>
    DateTime.now().add(Duration(days: days)).toIso8601String().substring(0, 10);

// ═══════════════════════════════════════════════════════════════════════════
// Estado global dos testes — populado no setUpAll, lido nos test()
// ═══════════════════════════════════════════════════════════════════════════

Map<String, String> _h = {}; // headers autenticados
int? _empId; // ID da primeira empresa disponível
int? _alunoId; // ID do primeiro aluno disponível
int? _academiaId; // ID da primeira academia disponível
int? _parceiroId; // ID do primeiro parceiro disponível
int? _personalId; // ID do primeiro personal disponível
int? _nutricionistaId; // ID do primeiro nutricionista disponível

Map<String, dynamic> _ref(int id) => {'id': id};

/// Extrai a lista de dados de qualquer envelope de resposta do backend.
/// Padrões suportados: lista direta, data.dados, data (lista), content, dados, items.
List _extractList(dynamic body) {
  if (body is List) return body;
  if (body is Map) {
    final data = body['data'];
    if (data is Map) {
      final dados = data['dados'] ?? data['content'] ?? data['items'];
      if (dados is List) return dados;
    }
    if (data is List) return data;
    for (final key in ['content', 'dados', 'items']) {
      final v = body[key];
      if (v is List) return v;
    }
  }
  return [];
}

/// Busca o primeiro ID de uma lista REST. Retorna null se vazio ou erro.
Future<int?> _firstId(String url) async {
  try {
    final r = await http.get(Uri.parse(url), headers: _h);
    if (r.statusCode != 200) return null;
    final body = jsonDecode(r.body);
    final list = _extractList(body);
    if (list.isNotEmpty) return list.first['id'];
  } catch (_) {}
  return null;
}

Future<int?> _postFirstId(String url, [Map<String, dynamic>? payload]) async {
  try {
    final r = await http.post(
      Uri.parse(url),
      headers: _h,
      body: jsonEncode(payload ?? {}),
    );
    if (r.statusCode != 200 && r.statusCode != 201) return null;
    final body = jsonDecode(r.body);
    final list = _extractList(body);
    if (list.isNotEmpty) return list.first['id'];
    if (body is Map<String, dynamic>) return _extractId(body, 'id');
  } catch (_) {}
  return null;
}

// ═══════════════════════════════════════════════════════════════════════════
// Relatório de execução
// ═══════════════════════════════════════════════════════════════════════════

final _report = <String, Map<String, String>>{};

void _log(String tela, String op, bool ok, [String? err]) {
  _report.putIfAbsent(tela, () => {});
  _report[tela]![op] = ok ? '✅' : '❌';
  if (!ok && err != null) print('  🚨 $tela [$op]: $err');
}

void _logSkip(String tela, String op, [String? reason]) {
  _report.putIfAbsent(tela, () => {});
  _report[tela]![op] = '⏭';
  if (reason != null) print('  ⏭ $tela [$op]: $reason');
}

int? _extractId(Map<String, dynamic> body, String idField) {
  // Resposta direta
  if (body[idField] != null) return body[idField];
  // Envelope data.dados (lista de 1)
  final data = body['data'];
  if (data is Map) {
    if (data[idField] != null) return data[idField];
    final dados = data['dados'];
    if (dados is List && dados.isNotEmpty) return dados.first[idField];
  }
  if (data is List && data.isNotEmpty) return data.first[idField];
  // Outros envelopes
  for (final key in ['dados', 'items', 'content']) {
    final v = body[key];
    if (v is List && v.isNotEmpty) return v.first[idField];
    if (v is Map && v[idField] != null) return v[idField];
  }
  return body['id'];
}

// ═══════════════════════════════════════════════════════════════════════════
// Modelo de cenário CRUD
// ═══════════════════════════════════════════════════════════════════════════

class CrudScenario {
  final String name;
  final String listUrl;
  final String createUrl;
  final String Function(String id) updateUrl;
  final String Function(String id) deleteUrl;
  final Map<String, dynamic> Function() createPayload;
  final Map<String, dynamic> Function(int id) updatePayload;
  final String idField;
  // 'PUT' para REST padrão; 'POST' para endpoints legados /update/{id}
  final String updateMethod;

  CrudScenario({
    required this.name,
    required this.listUrl,
    required this.createUrl,
    required this.updateUrl,
    required this.deleteUrl,
    required this.createPayload,
    required this.updatePayload,
    this.idField = 'id',
    this.updateMethod = 'PUT',
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Executor do ciclo GET → POST → PUT/POST → DELETE
// ═══════════════════════════════════════════════════════════════════════════

void _runCrud(CrudScenario s) {
  group('🖥  ${s.name}', () {
    int? createdId;

    test('GET (listar)', () async {
      try {
        final r = await http.get(Uri.parse(s.listUrl), headers: _h);
        if (r.statusCode == 200) {
          _log(s.name, 'GET', true);
        } else {
          _log(s.name, 'GET', false, '${r.statusCode} ${r.body}');
          fail('GET ${s.listUrl} → ${r.statusCode}');
        }
      } catch (e) {
        _log(s.name, 'GET', false, e.toString());
        rethrow;
      }
    });

    test('POST (criar)', () async {
      try {
        final body = withAudit(s.createPayload());
        final r = await http.post(
          Uri.parse(s.createUrl),
          headers: _h,
          body: jsonEncode(body),
        );
        if (r.statusCode == 200 || r.statusCode == 201) {
          final decoded = jsonDecode(r.body) as Map<String, dynamic>;
          createdId = _extractId(decoded, s.idField);
          if (createdId != null) {
            _log(s.name, 'POST', true);
          } else {
            _log(s.name, 'POST', false, 'ID não retornado: ${r.body}');
            fail('Objeto criado mas ID não encontrado');
          }
        } else {
          _log(s.name, 'POST', false, '${r.statusCode} ${r.body}');
          fail('POST → ${r.statusCode}');
        }
      } catch (e) {
        _log(s.name, 'POST', false, e.toString());
        rethrow;
      }
    });

    test('${s.updateMethod} (atualizar)', () async {
      if (createdId == null) {
        _logSkip(s.name, s.updateMethod, 'sem ID criado no POST');
        markTestSkipped('Sem ID para atualizar');
        return;
      }
      try {
        final body =
            withAudit({...s.updatePayload(createdId!), s.idField: createdId});
        final uri = Uri.parse(s.updateUrl(createdId.toString()));
        final r = s.updateMethod == 'PUT'
            ? await http.put(uri, headers: _h, body: jsonEncode(body))
            : await http.post(uri, headers: _h, body: jsonEncode(body));
        if (r.statusCode == 200 || r.statusCode == 204) {
          _log(s.name, s.updateMethod, true);
        } else {
          _log(s.name, s.updateMethod, false, '${r.statusCode} ${r.body}');
          fail('${s.updateMethod} → ${r.statusCode}');
        }
      } catch (e) {
        _log(s.name, s.updateMethod, false, e.toString());
        rethrow;
      }
    });

    test('DELETE (excluir)', () async {
      if (createdId == null) {
        _logSkip(s.name, 'DELETE', 'sem ID criado no POST');
        markTestSkipped('Sem ID para deletar');
        return;
      }
      try {
        final r = await http
            .delete(Uri.parse(s.deleteUrl(createdId.toString())), headers: _h);
        if (r.statusCode == 200 || r.statusCode == 204) {
          _log(s.name, 'DELETE', true);
        } else {
          _log(s.name, 'DELETE', false, '${r.statusCode}');
          fail('DELETE → ${r.statusCode}');
        }
      } catch (e) {
        _log(s.name, 'DELETE', false, e.toString());
        rethrow;
      }
    });
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// main
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  group('🧪 INTEGRAÇÃO SISTÊMICA — Todas as Telas', () {
    setUpAll(() async {
      print('\n🔵 INICIANDO TESTES DE INTEGRAÇÃO SISTÊMICA...');
      final token = await loginAndGetToken();
      _h = authHeaders(token);
      _empId = cachedEmpresaId;

      // ── Bootstrap: garante que empresa exista ────────────────────────────
      _empId ??= await _firstId(ApiLinks.allEmpresas);
      if (_empId == null) {
        try {
          final ts = _ts();
          final cr = await http.post(
            Uri.parse(ApiLinks.allEmpresas), // POST /api/empresa
            headers: _h,
            body: jsonEncode({
              'nome': 'Empresa Teste $ts',
              'email': 'empresa$ts@teste.com',
              'centroCustoObrigatorio': false,
              'aplicativo': {},
              'audit': {},
            }),
          );
          if (cr.statusCode == 200 || cr.statusCode == 201) {
            final dec = jsonDecode(cr.body);
            _empId = _extractId(dec, 'id');
          }
        } catch (_) {}
        _empId ??= await _firstId(ApiLinks.allEmpresas);
      }

      // ── Bootstrap: garante que academia exista ───────────────────────────
      _academiaId = await _firstId(ApiLinks.allAcademia);
      if (_academiaId == null) {
        try {
          final cr = await http.post(
            Uri.parse('${ApiLinks.baseUrl}/academia'),
            headers: _h,
            body: jsonEncode({
              'nome': 'Academia Teste ${_ts()}',
              if (_empId != null) 'codEmpresa': _empId,
              'audit': const {},
            }),
          );
          if (cr.statusCode == 200 || cr.statusCode == 201) {
            final dec = jsonDecode(cr.body);
            _academiaId = _extractId(dec, 'id');
          }
        } catch (_) {}
        _academiaId ??= await _firstId(ApiLinks.allAcademia);
      }

      // ── Busca IDs reais para FKs obrigatórias ───────────────────────────
      _alunoId ??= await _firstId('${ApiLinks.baseUrl}/aluno');
      _alunoId ??= await _postFirstId('${ApiLinks.baseUrl}/aluno', {
        'nome': _uid('Aluno'),
        'cpf': _ts().padLeft(11, '0').substring(0, 11),
        'email': 'aluno${_ts()}@teste.com',
      });
      _parceiroId ??= await _firstId(ApiLinks.allParceiros);
      _personalId ??= await _firstId('${ApiLinks.baseUrl}/api/personal');
      _nutricionistaId ??=
          await _firstId('${ApiLinks.baseUrl}/api/nutricionistas');
      if (_nutricionistaId == null) {
        _nutricionistaId = await _postFirstId(
          '${ApiLinks.baseUrl}/api/nutricionistas',
          {
            'nome': _uid('Nutricionista'),
            'email': 'nutri${_ts()}@teste.com',
            'telefone': '11977770000',
          },
        );
      }

      print(
          '✅ Autenticado | empresaId=$_empId | academiaId=$_academiaId | alunoId=$_alunoId | parceiroId=$_parceiroId\n');
    });

    // ─────────────────────────────────────────────────────────────────────
    // DOMÍNIO: ACADEMIA
    // ─────────────────────────────────────────────────────────────────────

    group('📦 ACADEMIA', () {
      final scenarios = [
        CrudScenario(
          name: 'Modalidade',
          listUrl: ApiLinks.allModalidades,
          createUrl: ApiLinks.createModalidade,
          updateUrl: ApiLinks.updateModalidade,
          deleteUrl: ApiLinks.deleteModalidade,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Modalidade'),
            'descricao': 'Desc teste',
            if (_academiaId != null) 'codAcademia': _ref(_academiaId!),
          },
          updatePayload: (id) => {
            'nome': _uid('Modalidade EDIT'),
            if (_academiaId != null) 'codAcademia': _ref(_academiaId!),
          },
        ),
        CrudScenario(
          name: 'Objetivo',
          listUrl: ApiLinks.allObjetivos,
          createUrl: ApiLinks.createObjetivo,
          updateUrl: ApiLinks.updateObjetivo,
          deleteUrl: ApiLinks.deleteObjetivo,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Objetivo'),
            'descricao': 'Desc teste objetivo',
            'status': 'A',
            if (_alunoId != null) 'cod_aluno': _alunoId,
          },
          updatePayload: (id) => {
            'nome': _uid('Objetivo EDIT'),
            if (_alunoId != null) 'cod_aluno': _alunoId,
          },
        ),
        CrudScenario(
          name: 'Plano',
          listUrl: ApiLinks.allPlanos,
          createUrl: ApiLinks.createPlano,
          updateUrl: ApiLinks.updatePlano,
          deleteUrl: ApiLinks.deletePlano,
          // GenericController legado usa PUT no endpoint /insert
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Plano'),
            'descricao': 'Desc plano',
            'valor': 99.90,
            'duracao': 30,
          },
          updatePayload: (id) => {'nome': _uid('Plano EDIT'), 'valor': 109.90},
        ),
        CrudScenario(
          name: 'Treino',
          listUrl: ApiLinks.allTreinos,
          createUrl: ApiLinks.createTreino,
          updateUrl: ApiLinks.updateTreino,
          deleteUrl: ApiLinks.deleteTreino,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Treino'),
            'descricao': 'Desc treino',
            if (_alunoId != null) 'idaluno': _alunoId,
          },
          updatePayload: (id) => {
            'nome': _uid('Treino EDIT'),
            if (_alunoId != null) 'idaluno': _alunoId,
          },
        ),
        CrudScenario(
          name: 'Grupo Muscular',
          listUrl: ApiLinks.allGruposMusculares,
          createUrl: ApiLinks.createGrupoMuscular,
          updateUrl: ApiLinks.updateGrupoMuscular,
          deleteUrl: ApiLinks.deleteGrupoMuscular,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Grupo Musc'),
            'descricao': 'Desc grupo muscular',
          },
          updatePayload: (id) => {'nome': _uid('Grupo Musc EDIT')},
        ),
        CrudScenario(
          name: 'Exercício',
          listUrl: ApiLinks.allExercicios,
          createUrl: ApiLinks.createExercicio,
          updateUrl: ApiLinks.updateExercicio,
          deleteUrl: ApiLinks.deleteExercicio,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Exercicio'),
            'descricao': 'Desc exercicio',
          },
          updatePayload: (id) => {'nome': _uid('Exercicio EDIT')},
        ),
        CrudScenario(
          name: 'Alimento',
          listUrl: ApiLinks.allAlimentos,
          createUrl: ApiLinks.createAlimento,
          updateUrl: ApiLinks.updateAlimento,
          deleteUrl: ApiLinks.deleteAlimento,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Alimento'),
            'calorias': 100.0,
            'proteina': 20.0,
            'carboidrato': 10.0,
            'gordura': 5.0,
            'unidade': 'g',
          },
          updatePayload: (id) =>
              {'nome': _uid('Alimento EDIT'), 'calorias': 120.0},
        ),
        CrudScenario(
          name: 'Suplemento',
          listUrl: ApiLinks.allSuplementos,
          createUrl: ApiLinks.createSuplemento,
          updateUrl: ApiLinks.updateSuplemento,
          deleteUrl: ApiLinks.deleteSuplemento,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Suplemento'),
            'descricao': 'Desc suplemento',
            'fabricante': 'Fabricante Teste',
            'preco': 89.90,
          },
          updatePayload: (id) =>
              {'nome': _uid('Suplemento EDIT'), 'preco': 95.00},
        ),
        CrudScenario(
          name: 'Medicamento',
          listUrl: ApiLinks.allMedicamentos,
          createUrl: ApiLinks.createMedicamento,
          updateUrl: ApiLinks.updateMedicamento,
          deleteUrl: ApiLinks.deleteMedicamento,
          updateMethod: 'PUT',
          createPayload: () => {
            'medicamento': _uid('Medicamento'),
            'descricao': 'Desc medicamento',
            'dosagem': '500mg',
          },
          updatePayload: (id) => {'medicamento': _uid('Medicamento EDIT')},
        ),
        CrudScenario(
          name: 'Mensalidade',
          listUrl: ApiLinks.allMensalidades,
          createUrl: ApiLinks.createMensalidade,
          updateUrl: ApiLinks.updateMensalidade,
          deleteUrl: ApiLinks.deleteMensalidade,
          updateMethod: 'PUT',
          createPayload: () => {
            'descricao': _uid('Mensalidade'),
            'valor': 150.00,
            'dataVencimento': _isoDate(30),
            'status': 'PENDENTE',
          },
          updatePayload: (id) => {'valor': 160.00},
        ),
        CrudScenario(
          name: 'Dieta',
          listUrl: ApiLinks.allDietas,
          createUrl: ApiLinks.createDieta,
          updateUrl: ApiLinks.updateDieta,
          deleteUrl: ApiLinks.deleteDieta,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Dieta'),
            'descricao': 'Dieta de teste',
            'objetivo': 'EMAGRECIMENTO',
            if (_alunoId != null) 'cod_aluno': _alunoId,
          },
          updatePayload: (id) => {
            'nome': _uid('Dieta EDIT'),
            if (_alunoId != null) 'cod_aluno': _alunoId,
          },
        ),
        CrudScenario(
          name: 'Avaliação Física',
          listUrl: ApiLinks.allAvaliacoesFisicas,
          createUrl: ApiLinks.createAvaliacaoFisica,
          updateUrl: ApiLinks.updateAvaliacaoFisica,
          deleteUrl: ApiLinks.deleteAvaliacaoFisica,
          updateMethod: 'PUT',
          createPayload: () => {
            'descricao': _uid('Avaliacao fisica'),
            'valor': '80.0',
            if (_alunoId != null) 'codAluno': _ref(_alunoId!),
            if (_nutricionistaId != null)
              'codNutricionistas': _ref(_nutricionistaId!),
            if (_personalId != null) 'codPersonal': _ref(_personalId!),
          },
          updatePayload: (id) => {'peso': 79.0, 'imc': 25.8},
        ),
        CrudScenario(
          name: 'Exame',
          listUrl: ApiLinks.allExames,
          createUrl: ApiLinks.createExame,
          updateUrl: ApiLinks.updateExame,
          deleteUrl: ApiLinks.deleteExame,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Exame'),
            'descricao': 'Exame de sangue',
            'tipoExame': 'SANGUE',
            'laboratorio': 'Lab Teste',
            'status': 1,
            if (_alunoId != null) 'cod_aluno': _alunoId,
          },
          updatePayload: (id) => {
            'nome': _uid('Exame EDIT'),
            if (_alunoId != null) 'cod_aluno': _alunoId,
          },
        ),
        CrudScenario(
          name: 'Alerta Aluno',
          listUrl: ApiLinks.allAlertasAluno,
          createUrl: ApiLinks.createAlertaAluno,
          updateUrl: ApiLinks.updateAlertaAluno,
          deleteUrl: ApiLinks.deleteAlertaAluno,
          updateMethod: 'PUT',
          createPayload: () => {
            'titulo': _uid('Alerta'),
            'mensagem': 'Mensagem de alerta de teste',
            'tipo': 'INFO',
            'dataEnvio': _isoNow(),
          },
          updatePayload: (id) => {'titulo': _uid('Alerta EDIT')},
        ),
      ];

      for (final s in scenarios) {
        _runCrud(s);
      }
    });

    // ─────────────────────────────────────────────────────────────────────
    // DOMÍNIO: PARCEIRO / EMPRESA
    // ─────────────────────────────────────────────────────────────────────

    group('🏢 PARCEIRO / EMPRESA', () {
      final scenarios = [
        CrudScenario(
          name: 'Parceiro',
          listUrl: ApiLinks.allParceiros,
          createUrl: ApiLinks.createParceiro,
          updateUrl: ApiLinks.updateParceiro,
          deleteUrl: ApiLinks.deleteParceiro,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Parceiro'),
            'email': 'parceiro${_ts()}@teste.com',
            'telefone': '11999999999',
            'tipo': 'CLIENTE',
            'ativo': true,
          },
          updatePayload: (id) => {'nome': _uid('Parceiro EDIT')},
        ),
        CrudScenario(
          name: 'Empresa',
          listUrl: ApiLinks.allEmpresas,
          createUrl: ApiLinks.createEmpresa,
          updateUrl: ApiLinks.updateEmpresa,
          deleteUrl: ApiLinks.deleteEmpresa,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Empresa'),
            'razaoSocial': _uid('Razao Social'),
            'cnpj': _ts().padLeft(14, '0').substring(0, 14),
            'email': 'empresa${_ts()}@teste.com',
            'telefone': '1133334444',
          },
          updatePayload: (id) => {'nome': _uid('Empresa EDIT')},
        ),
        CrudScenario(
          name: 'Tipo Parceiro',
          listUrl: ApiLinks.allTipoParceiro,
          createUrl: ApiLinks.createTipoParceiro,
          updateUrl: ApiLinks.updateTipoParceiro,
          deleteUrl: ApiLinks.deleteTipoParceiro,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Tipo Parceiro'),
            'descricao': 'Desc tipo parceiro',
          },
          updatePayload: (id) => {'nome': _uid('Tipo Parceiro EDIT')},
        ),
        CrudScenario(
          name: 'Fornecedor',
          listUrl: ApiLinks.allFornecedores,
          createUrl: ApiLinks.createFornecedor,
          updateUrl: ApiLinks.updateFornecedor,
          deleteUrl: ApiLinks.deleteFornecedor,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Fornecedor'),
            'email': 'forn${_ts()}@teste.com',
            'telefone': '11988887777',
            'ativo': true,
          },
          updatePayload: (id) => {'nome': _uid('Fornecedor EDIT')},
        ),
      ];

      for (final s in scenarios) {
        _runCrud(s);
      }
    });

    // ─────────────────────────────────────────────────────────────────────
    // DOMÍNIO: FINANCEIRO
    // ─────────────────────────────────────────────────────────────────────

    group('💰 FINANCEIRO', () {
      final scenarios = [
        CrudScenario(
          name: 'Categoria Financeira',
          listUrl: ApiLinks.allCategoriasFinanceiras,
          createUrl: ApiLinks.createCategoriaFinanceira,
          updateUrl: ApiLinks.updateCategoriaFinanceira,
          deleteUrl: ApiLinks.deleteCategoriaFinanceira,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Categoria'),
            'tipo': 'DESPESA',
            'descricao': 'Categoria de teste',
          },
          updatePayload: (id) => {'nome': _uid('Categoria EDIT')},
        ),
        CrudScenario(
          name: 'Centro de Custo',
          listUrl: ApiLinks.allCentrosCusto,
          createUrl: ApiLinks.createCentroCusto,
          updateUrl: ApiLinks.updateCentroCusto,
          deleteUrl: ApiLinks.deleteCentroCusto,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Centro Custo'),
            'descricao': 'Centro custo teste',
            'ativo': true,
          },
          updatePayload: (id) => {'nome': _uid('Centro Custo EDIT')},
        ),
        CrudScenario(
          name: 'Forma de Pagamento',
          listUrl: ApiLinks.allFormasPagamento,
          createUrl: ApiLinks.createFormaPagamento,
          updateUrl: ApiLinks.updateFormaPagamento,
          deleteUrl: ApiLinks.deleteFormaPagamento,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Forma Pgto'),
            'descricao': 'Forma de pagamento teste',
            'tipo': 'BOLETO',
            'ativo': true,
            'status': 1, // NOT NULL no DB
          },
          updatePayload: (id) => {
            'nome': _uid('Forma Pgto EDIT'),
            'descricao': 'Forma de pagamento editada',
          },
        ),
        CrudScenario(
          name: 'Conta Bancária',
          listUrl: ApiLinks.contasBancarias,
          createUrl: ApiLinks.createContaBancaria,
          updateUrl: ApiLinks.updateContaBancaria,
          deleteUrl: ApiLinks.deleteContaBancaria,
          updateMethod: 'PUT',
          createPayload: () => {
            'nomeConta': _uid('Banco'),
            'numeroConta': _ts().substring(8),
            'agencia': '0001',
            'banco': 'Banco Teste',
            'tipo': 'CORRENTE',
            'saldo': 1000.00,
          },
          updatePayload: (id) => {'nomeConta': _uid('Banco EDIT')},
        ),
        CrudScenario(
          name: 'Conta a Pagar',
          listUrl: ApiLinks.allContasPagar,
          createUrl: ApiLinks.createContaPagar,
          updateUrl: ApiLinks.updateContaPagar,
          deleteUrl: ApiLinks.deleteContaPagar,
          updateMethod: 'PUT',
          createPayload: () => {
            'descricao': _uid('Conta Pagar'),
            'valor': 500.00,
            'dataVencimento': _isoDate(30),
            'status': 'ABERTO',
          },
          updatePayload: (id) => {'valor': 550.00},
        ),
        CrudScenario(
          name: 'Conta a Receber',
          listUrl: ApiLinks.allContasReceber,
          createUrl: ApiLinks.createContaReceber,
          updateUrl: ApiLinks.updateContaReceber,
          deleteUrl: ApiLinks.deleteContaReceber,
          updateMethod: 'PUT',
          createPayload: () => {
            'descricao': _uid('Conta Receber'),
            'valor': 750.00,
            'dataVencimento': _isoDate(30),
            'status': 'PENDENTE',
          },
          updatePayload: (id) => {'valor': 800.00},
        ),
      ];

      for (final s in scenarios) {
        _runCrud(s);
      }
    });

    // ─────────────────────────────────────────────────────────────────────
    // DOMÍNIO: COMUNICAÇÃO / SUPORTE
    // ─────────────────────────────────────────────────────────────────────

    group('💬 COMUNICAÇÃO / SUPORTE', () {
      final scenarios = [
        CrudScenario(
          name: 'Setor',
          listUrl: ApiLinks.allSetores,
          createUrl: ApiLinks.createSetor,
          updateUrl: ApiLinks.updateSetor,
          deleteUrl: ApiLinks.deleteSetor,
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Setor'),
            'descricao': 'Setor de teste',
          },
          updatePayload: (id) => {'nome': _uid('Setor EDIT')},
        ),
        CrudScenario(
          name: 'Comunicado',
          listUrl: ApiLinks.allComunicados,
          createUrl: ApiLinks.createComunicado,
          updateUrl: (id) => ApiLinks.updateComunicado(id),
          deleteUrl: (id) => ApiLinks.deleteComunicado(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'titulo': _uid('Comunicado'),
            'conteudo': 'Conteúdo de comunicado de teste',
            'dataPublicacao': _isoNow(),
            'prioridade': 'NORMAL',
          },
          updatePayload: (id) => {'titulo': _uid('Comunicado EDIT')},
        ),
        CrudScenario(
          name: 'Chamado',
          listUrl: ApiLinks.allChamados,
          createUrl: ApiLinks.createChamado,
          updateUrl: (id) => ApiLinks.updateChamado(id),
          deleteUrl: (id) => ApiLinks.deleteChamado(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'titulo': _uid('Chamado'),
            'descricao': 'Descrição do chamado de teste',
            'prioridade': 'NORMAL',
            'status': 'ABERTO',
          },
          updatePayload: (id) =>
              {'titulo': _uid('Chamado EDIT'), 'prioridade': 'ALTA'},
        ),
        CrudScenario(
          name: 'Calendário Guias',
          listUrl: ApiLinks.allCalendariosGuias,
          createUrl: ApiLinks.createCalendarioGuias,
          updateUrl: (id) => ApiLinks.updateCalendarioGuias(id),
          deleteUrl: (id) => ApiLinks.deleteCalendarioGuias(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'titulo': _uid('Calendário'),
            'descricao': 'Evento de teste',
            'dataInicio': _isoNow(),
            'dataFim': _isoFuture(2),
            'tipo': 'OBRIGACAO',
          },
          updatePayload: (id) => {'titulo': _uid('Calendário EDIT')},
        ),
        CrudScenario(
          name: 'Obrigação Fiscal',
          listUrl: ApiLinks.allObrigacaoFiscal,
          createUrl: ApiLinks.createObrigacaoFiscal,
          updateUrl: (id) => ApiLinks.updateObrigacaoFiscal(id),
          deleteUrl: (id) => ApiLinks.deleteObrigacaoFiscal(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Obrigacao Fiscal'),
            'descricao': 'Obrigação de teste',
            'dataVencimento': _isoDate(30),
            'tipo': 'FEDERAL',
            'status': 'PENDENTE',
          },
          updatePayload: (id) => {'nome': _uid('Obrigacao Fiscal EDIT')},
        ),
      ];

      for (final s in scenarios) {
        _runCrud(s);
      }
    });

    // ─────────────────────────────────────────────────────────────────────
    // DOMÍNIO: RH / DEPARTAMENTO PESSOAL
    // ─────────────────────────────────────────────────────────────────────

    group('👥 RH / DEPARTAMENTO PESSOAL', () {
      final scenarios = [
        CrudScenario(
          name: 'Cargo',
          listUrl: ApiLinks.allCargos,
          createUrl: ApiLinks.createCargo,
          updateUrl: (id) => ApiLinks.updateCargo(id),
          deleteUrl: (id) => ApiLinks.deleteCargo(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Cargo'),
            'descricao': 'Cargo de teste',
            'nivel': 'JUNIOR',
          },
          updatePayload: (id) => {'nome': _uid('Cargo EDIT')},
        ),
        CrudScenario(
          name: 'Departamento',
          listUrl: ApiLinks.allDepartamentos,
          createUrl: ApiLinks.createDepartamento,
          updateUrl: (id) => ApiLinks.updateDepartamento(id),
          deleteUrl: (id) => ApiLinks.deleteDepartamento(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Departamento'),
            'descricao': 'Departamento de teste',
          },
          updatePayload: (id) => {'nome': _uid('Departamento EDIT')},
        ),
        CrudScenario(
          name: 'Feriado',
          listUrl: ApiLinks.allFeriados,
          createUrl: ApiLinks.createFeriado,
          updateUrl: (id) => ApiLinks.updateFeriado(id),
          deleteUrl: (id) => ApiLinks.deleteFeriado(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Feriado'),
            'data': _isoDate(60),
            'tipo': 'NACIONAL',
          },
          updatePayload: (id) => {'nome': _uid('Feriado EDIT')},
        ),
        CrudScenario(
          name: 'Funcionário',
          listUrl: ApiLinks.allFuncionarios,
          createUrl: ApiLinks.createFuncionario,
          updateUrl: (id) => ApiLinks.updateFuncionario(id),
          deleteUrl: (id) => ApiLinks.deleteFuncionario(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Funcionario'),
            'cpf': '000.000.000-${_ts().substring(11, 13)}',
            'email': 'func${_ts()}@teste.com',
            'telefone': '11977776666',
            'dataAdmissao': _isoDate(),
          },
          updatePayload: (id) => {'nome': _uid('Funcionario EDIT')},
        ),
        CrudScenario(
          name: 'Horário Funcionário',
          listUrl: ApiLinks.allHorariosFunc,
          createUrl: ApiLinks.createHorarioFunc,
          updateUrl: (id) => ApiLinks.updateHorarioFunc(id),
          deleteUrl: (id) => ApiLinks.deleteHorarioFunc(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Horario'),
            'entrada': '08:00',
            'saida': '17:00',
            'intervalo': '12:00',
            'diasSemana': ['SEGUNDA', 'TERCA', 'QUARTA', 'QUINTA', 'SEXTA'],
          },
          updatePayload: (id) =>
              {'nome': _uid('Horario EDIT'), 'entrada': '09:00'},
        ),
      ];

      for (final s in scenarios) {
        _runCrud(s);
      }
    });

    // ─────────────────────────────────────────────────────────────────────
    // DOMÍNIO: CONTÁBIL
    // ─────────────────────────────────────────────────────────────────────

    group('📊 CONTÁBIL', () {
      final scenarios = [
        CrudScenario(
          name: 'Conta Contábil',
          listUrl: ApiLinks.allContasContabeis,
          createUrl: ApiLinks.createContaContabil,
          updateUrl: (id) => ApiLinks.updateContaContabil(id),
          deleteUrl: (id) => ApiLinks.deleteContaContabil(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'codigoContabil': '1.${_ts().substring(10)}',
            'nome': _uid('Conta Contábil'),
            'tipo': 'ATIVO',
            'ativa': true,
          },
          updatePayload: (id) => {'nome': _uid('Conta Contábil EDIT')},
        ),
        CrudScenario(
          name: 'Lançamento Contábil',
          listUrl:
              '${ApiLinks.createLancamentoContabil}?empresaId=1&periodo=${_isoDate().substring(0, 7)}',
          createUrl: ApiLinks.createLancamentoContabil,
          updateUrl: (id) => ApiLinks.updateLancamentoContabil(id),
          deleteUrl: (id) => ApiLinks.deleteLancamentoContabil(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'dataLancamento': _isoDate(),
            'descricao': _uid('Lançamento'),
            'valor': 1500.00,
            'periodo': _isoDate().substring(0, 7),
          },
          updatePayload: (id) =>
              {'descricao': _uid('Lançamento EDIT'), 'valor': 1600.00},
        ),
      ];

      for (final s in scenarios) {
        _runCrud(s);
      }
    });

    // ─────────────────────────────────────────────────────────────────────
    // DOMÍNIO: GED / DOCUMENTOS
    // ─────────────────────────────────────────────────────────────────────

    group('📁 GED / DOCUMENTOS', () {
      final scenarios = [
        CrudScenario(
          name: 'Diretório',
          listUrl: ApiLinks.allDiretorios,
          createUrl: ApiLinks.createDiretorio,
          updateUrl: (id) => ApiLinks.updateDiretorio(id),
          deleteUrl: (id) => ApiLinks.deleteDiretorio(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Diretório'),
            'descricao': 'Diretório de teste',
          },
          updatePayload: (id) => {'nome': _uid('Diretório EDIT')},
        ),
      ];

      for (final s in scenarios) {
        _runCrud(s);
      }
    });

    // ─────────────────────────────────────────────────────────────────────
    // DOMÍNIO: ADMIN / CONFIGURAÇÕES
    // ─────────────────────────────────────────────────────────────────────

    group('⚙️  ADMIN / CONFIGURAÇÕES', () {
      final scenarios = [
        CrudScenario(
          name: 'Role',
          listUrl: ApiLinks.allRoles,
          createUrl: ApiLinks.createRole,
          updateUrl: (id) => ApiLinks.updateRole(id),
          deleteUrl: (id) => ApiLinks.deleteRole(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('ROLE_TESTE'),
            'descricao': 'Role de teste',
          },
          updatePayload: (id) => {'descricao': _uid('Role EDIT')},
        ),
        CrudScenario(
          name: 'Aplicativo',
          listUrl: ApiLinks.allAplicativos,
          createUrl: ApiLinks.createAplicativo,
          updateUrl: (id) => ApiLinks.updateAplicativo(id),
          deleteUrl: (id) => ApiLinks.deleteAplicativo(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('App Teste'),
            'descricao': 'Aplicativo de teste',
            'ativo': true,
          },
          updatePayload: (id) => {'nome': _uid('App EDIT')},
        ),
        CrudScenario(
          name: 'Regime Tributário',
          listUrl: ApiLinks.allRegimetributario,
          createUrl: ApiLinks.createRegimetributario,
          updateUrl: (id) => ApiLinks.updateRegimetributario(id),
          deleteUrl: (id) => ApiLinks.deleteRegimetributario(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Regime'),
            'descricao': 'Regime tributário de teste',
            'codigo': 'SN',
          },
          updatePayload: (id) => {
            'nome': _uid('Regime EDIT'),
            'codigo': 'SN', // NOT NULL — backend não faz merge, precisa enviar
          },
        ),
        CrudScenario(
          name: 'Módulo Serviço',
          listUrl: ApiLinks.allModuloServico,
          createUrl: ApiLinks.createModuloServico,
          updateUrl: (id) => ApiLinks.updateModuloServico(id),
          deleteUrl: (id) => ApiLinks.deleteModuloServico(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Modulo'),
            'descricao': 'Módulo de teste',
            'ativo': true,
          },
          updatePayload: (id) => {'nome': _uid('Modulo EDIT')},
        ),
        CrudScenario(
          name: 'Serviço Contratado',
          listUrl: ApiLinks.allServicoContratado,
          createUrl: ApiLinks.createServicoContratado,
          updateUrl: (id) => ApiLinks.updateServicoContratado(id),
          deleteUrl: (id) => ApiLinks.deleteServicoContratado(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Servico'),
            'descricao': 'Serviço contratado de teste',
            'valor': 500.00,
            'ativo': true,
          },
          updatePayload: (id) =>
              {'nome': _uid('Servico EDIT'), 'valor': 550.00},
        ),
      ];

      for (final s in scenarios) {
        _runCrud(s);
      }
    });

    // ─────────────────────────────────────────────────────────────────────
    // DOMÍNIO: COMERCIAL / ESTOQUE
    // ─────────────────────────────────────────────────────────────────────

    group('🛒 COMERCIAL / ESTOQUE', () {
      final scenarios = [
        CrudScenario(
          name: 'Tipo Produto',
          listUrl: ApiLinks.allTiposProduto,
          createUrl: ApiLinks.createTipoProduto,
          updateUrl: (id) => ApiLinks.updateTipoProduto(id),
          deleteUrl: (id) => ApiLinks.deleteTipoProduto(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'tipoProduto': _uid('Tipo Produto'), // campo da entidade (não 'nome')
            'descricao': 'Tipo de produto de teste',
          },
          updatePayload: (id) => {
            'tipoProduto': _uid('Tipo Produto EDIT'),
          },
        ),
        CrudScenario(
          name: 'Orçamento Comercial',
          listUrl: ApiLinks.orcamentos,
          createUrl: ApiLinks.orcamentos,
          updateUrl: (id) => ApiLinks.orcamentoById(id),
          deleteUrl: (id) => ApiLinks.orcamentoById(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'descricao': _uid('Orcamento'),
            'dataValidade': _isoDate(30),
            'status': 'RASCUNHO',
            'itens': [],
          },
          updatePayload: (id) => {'descricao': _uid('Orcamento EDIT')},
        ),
        CrudScenario(
          name: 'Depósito Estoque',
          listUrl: ApiLinks.depositos,
          createUrl: ApiLinks.depositos,
          updateUrl: (id) => '${ApiLinks.depositos}/$id',
          deleteUrl: (id) => '${ApiLinks.depositos}/$id',
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Deposito'),
            'descricao': 'Depósito de teste',
            'ativo': true,
          },
          updatePayload: (id) => {'nome': _uid('Deposito EDIT')},
        ),
        CrudScenario(
          name: 'Cotação Frete',
          listUrl: ApiLinks.allCotacoesFrete,
          createUrl: ApiLinks.createCotacaoFrete,
          updateUrl: (id) => ApiLinks.updateCotacaoFrete(id),
          deleteUrl: (id) => ApiLinks.deleteCotacaoFrete(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'origem': _uid('Origem'),
            'destino': _uid('Destino'),
            'peso': 10.0,
            'prazoEntrega': 5,
            'valor': 45.90,
          },
          updatePayload: (id) => {'valor': 50.00},
        ),
      ];

      for (final s in scenarios) {
        _runCrud(s);
      }
    });

    // ─────────────────────────────────────────────────────────────────────
    // DOMÍNIO: TRADING / INVESTIMENTOS
    // ─────────────────────────────────────────────────────────────────────

    group('📈 TRADING / INVESTIMENTOS', () {
      final scenarios = [
        CrudScenario(
          name: 'Dividendo',
          listUrl: ApiLinks.allDividendos,
          createUrl: ApiLinks.createDividendo,
          updateUrl: (id) => ApiLinks.updateDividendo(id),
          deleteUrl: (id) => ApiLinks.deleteDividendo(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'ticker': 'PETR4',
            'valor': 1.50,
            'dataEx': _isoDate(),
            'dataPagamento': _isoDate(15),
            'tipo': 'DIVIDENDO',
          },
          updatePayload: (id) => {'valor': 1.75},
        ),
        CrudScenario(
          name: 'Trading Watchlist',
          listUrl: ApiLinks.tradingWatchlist,
          createUrl: ApiLinks.tradingWatchlist,
          updateUrl: (id) => ApiLinks.tradingWatchlistItem(id),
          deleteUrl: (id) => ApiLinks.tradingWatchlistItem(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'ticker': 'BBAS3',
            'descricao': 'Banco do Brasil',
            'precoAlvo': 55.00,
          },
          updatePayload: (id) => {'precoAlvo': 60.00},
        ),
        CrudScenario(
          name: 'Trading Alerta',
          listUrl: ApiLinks.tradingAlertas,
          createUrl: ApiLinks.tradingAlertas,
          updateUrl: (id) => ApiLinks.tradingAlerta(id),
          deleteUrl: (id) => ApiLinks.tradingAlerta(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'ticker': 'VALE3',
            'condicao': 'PRECO_ABAIXO',
            'valorReferencia': 70.00,
            'ativo': true,
          },
          updatePayload: (id) => {'valorReferencia': 65.00},
        ),
      ];

      for (final s in scenarios) {
        _runCrud(s);
      }
    });

    // ─────────────────────────────────────────────────────────────────────
    // DOMÍNIO: CRM
    // ─────────────────────────────────────────────────────────────────────

    group('🤝 CRM', () {
      final scenarios = [
        CrudScenario(
          name: 'CRM Deal',
          listUrl: ApiLinks.allCrmDeals,
          createUrl: ApiLinks.createCrmDeal,
          updateUrl: (id) => '${ApiLinks.allCrmDeals}/$id',
          deleteUrl: (id) => '${ApiLinks.allCrmDeals}/$id',
          updateMethod: 'PUT',
          createPayload: () => {
            'titulo': _uid('Deal'),
            'valor': 10000.00,
            'estagio': 'PROSPECCAO',
            'probabilidade': 30,
          },
          updatePayload: (id) =>
              {'titulo': _uid('Deal EDIT'), 'estagio': 'NEGOCIACAO'},
        ),
        CrudScenario(
          name: 'Contrato Recorrente',
          listUrl: ApiLinks.allRecurringContracts,
          createUrl: ApiLinks.createRecurringContract,
          updateUrl: (id) => '${ApiLinks.allRecurringContracts}/$id',
          deleteUrl: (id) => '${ApiLinks.allRecurringContracts}/$id',
          updateMethod: 'PUT',
          createPayload: () => {
            'descricao': _uid('Contrato'),
            'valor': 500.00,
            'periodicidade': 'MENSAL',
            'dataInicio': _isoDate(),
            'status': 'ATIVO',
          },
          updatePayload: (id) =>
              {'descricao': _uid('Contrato EDIT'), 'valor': 550.00},
        ),
      ];

      for (final s in scenarios) {
        _runCrud(s);
      }
    });

    // ─────────────────────────────────────────────────────────────────────
    // DOMÍNIO: GRIDS — ENTIDADES RESTANTES COM CRUD
    // ─────────────────────────────────────────────────────────────────────

    group('🔄 GRIDS — ENTIDADES RESTANTES', () {
      final scenarios = [
        // personal_grid_screen
        CrudScenario(
          name: 'Personal',
          listUrl: ApiLinks.allPersonais,
          createUrl: ApiLinks.createPersonal,
          updateUrl: (id) => ApiLinks.updatePersonal(id),
          deleteUrl: (id) => ApiLinks.deletePersonal(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Personal'),
            'cpf': '000.000.000-${_ts().substring(11, 13)}',
            'email': 'personal${_ts()}@teste.com',
            'telefone': '11988880000',
            'especialidades': 'Musculação',
          },
          updatePayload: (id) => {'nome': _uid('Personal EDIT')},
        ),
        // login_grid_screen
        CrudScenario(
          name: 'Login (usuário)',
          listUrl: ApiLinks.allLogins,
          createUrl: ApiLinks.createLogin,
          updateUrl: (id) => ApiLinks.updateLogin(id),
          deleteUrl: (id) => ApiLinks.deleteLogin(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'email': 'login${_ts()}@teste.com',
            'senha': 'Teste@123',
            'ativo': true,
          },
          updatePayload: (id) => {'ativo': false},
        ),
        // classificacao_grid_screen
        CrudScenario(
          name: 'Classificação',
          listUrl: ApiLinks.allClassificacoes,
          createUrl: ApiLinks.createClassificacao,
          updateUrl: (id) => ApiLinks.updateClassificacao(id),
          deleteUrl: (id) => ApiLinks.deleteClassificacao(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Classificacao'),
            'descricao': 'Desc classificação',
          },
          updatePayload: (id) => {'nome': _uid('Classificacao EDIT')},
        ),
        // noticias_grid_screen
        CrudScenario(
          name: 'Notícia',
          listUrl: ApiLinks.allNoticias,
          createUrl: ApiLinks.createNoticia,
          updateUrl: (id) => ApiLinks.updateNoticia(id),
          deleteUrl: (id) => ApiLinks.deleteNoticia(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'titulo': _uid('Noticia'),
            'conteudo': 'Conteúdo da notícia de teste',
            'publicada': false,
          },
          updatePayload: (id) =>
              {'titulo': _uid('Noticia EDIT'), 'publicada': true},
        ),
        // nfe_grid_screen
        CrudScenario(
          name: 'NF-e',
          listUrl: ApiLinks.allNfe,
          createUrl: ApiLinks.createNfe,
          updateUrl: (id) => ApiLinks.updateNfe(id),
          deleteUrl: (id) => '${ApiLinks.allNfe}/$id',
          updateMethod: 'PUT',
          createPayload: () => {
            'numero': int.parse(_ts().substring(8)),
            'serie': '1',
            'naturezaOperacao': 'VENDA',
            'dataEmissao': _isoDate(),
            'status': 'RASCUNHO',
            'itens': [],
          },
          updatePayload: (id) => {'naturezaOperacao': 'VENDA EDITADA'},
        ),
        // nota_fiscal_entrada_grid_screen
        CrudScenario(
          name: 'Nota Fiscal Entrada',
          listUrl: ApiLinks.allNotasFiscaisEntrada,
          createUrl: ApiLinks.createNotaFiscalEntrada,
          updateUrl: (id) => ApiLinks.updateNotaFiscalEntrada(id),
          deleteUrl: (id) => ApiLinks.deleteNotaFiscalEntrada(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'numero': _ts().substring(7),
            'serie': '1',
            'dataEmissao': _isoDate(),
            'dataEntrada': _isoDate(),
            'status': 'PENDENTE',
            'itens': [],
          },
          updatePayload: (id) => {'status': 'CONFERIDA'},
        ),
        // nota_fiscal_saida_grid_screen
        CrudScenario(
          name: 'Nota Fiscal Saída',
          listUrl: ApiLinks.allNotasFiscaisSaida,
          createUrl: ApiLinks.createNotaFiscalSaida,
          updateUrl: (id) => ApiLinks.updateNotaFiscalSaida(id),
          deleteUrl: (id) => ApiLinks.deleteNotaFiscalSaida(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'numero': _ts().substring(7),
            'serie': '1',
            'dataEmissao': _isoDate(),
            'status': 'RASCUNHO',
            'itens': [],
          },
          updatePayload: (id) => {'status': 'CONFERIDA'},
        ),
        // order_grid_screen
        CrudScenario(
          name: 'Order',
          listUrl: ApiLinks.allOrders,
          createUrl: ApiLinks.createOrder,
          updateUrl: (id) => ApiLinks.updateOrder(id),
          deleteUrl: (id) => ApiLinks.deleteOrder(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'descricao': _uid('Order'),
            'status': 'PENDENTE',
            'valor': 250.00,
          },
          updatePayload: (id) =>
              {'descricao': _uid('Order EDIT'), 'status': 'EM_ANDAMENTO'},
        ),
        // pedido_grid_screen
        CrudScenario(
          name: 'Pedido',
          listUrl: ApiLinks.allPedidos,
          createUrl: ApiLinks.createPedido,
          updateUrl: (id) => ApiLinks.updatePedido(id),
          deleteUrl: (id) => ApiLinks.deletePedido(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'descricao': _uid('Pedido'),
            'status': 'RASCUNHO',
            'itens': [],
          },
          updatePayload: (id) => {'descricao': _uid('Pedido EDIT')},
        ),
        // ticket_grid_screen
        CrudScenario(
          name: 'Ticket',
          listUrl: ApiLinks.allTickets,
          createUrl: ApiLinks.createTicket,
          updateUrl: (id) => ApiLinks.updateTicket(id),
          deleteUrl: (id) => ApiLinks.deleteTicket(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'titulo': _uid('Ticket'),
            'descricao': 'Ticket de suporte de teste',
            'prioridade': 'MEDIA',
            'status': 'ABERTO',
          },
          updatePayload: (id) =>
              {'titulo': _uid('Ticket EDIT'), 'prioridade': 'ALTA'},
        ),
        // produto / catalago_produto_grid_screen
        CrudScenario(
          name: 'Produto (Catálogo)',
          listUrl: ApiLinks.allVendas,
          createUrl: ApiLinks.insertProduto,
          updateUrl: (id) => '${ApiLinks.allVendas}/$id',
          deleteUrl: (id) => '${ApiLinks.allVendas}/$id',
          updateMethod: 'PUT',
          createPayload: () => {
            'nome': _uid('Produto'),
            'descricao': 'Produto de teste',
            'preco': 99.90,
            'estoque': 10,
            'ativo': true,
          },
          updatePayload: (id) =>
              {'nome': _uid('Produto EDIT'), 'preco': 109.90},
        ),
        // pedido_venda_grid_screen (cancel em vez de delete)
        CrudScenario(
          name: 'Pedido de Venda',
          listUrl: ApiLinks.pedidosVenda,
          createUrl: ApiLinks.pedidosVenda,
          updateUrl: (id) => ApiLinks.pedidoVendaById(id),
          deleteUrl: (id) => ApiLinks.cancelarPedidoVenda(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'descricao': _uid('PedidoVenda'),
            'status': 'RASCUNHO',
            'itens': [],
          },
          updatePayload: (id) => {'descricao': _uid('PedidoVenda EDIT')},
        ),
        // pedido_compra_grid_screen (cancel em vez de delete)
        CrudScenario(
          name: 'Pedido de Compra',
          listUrl: ApiLinks.pedidosCompra,
          createUrl: ApiLinks.pedidosCompra,
          updateUrl: (id) => ApiLinks.pedidoCompraById(id),
          deleteUrl: (id) => ApiLinks.cancelarPedidoCompra(id),
          updateMethod: 'PUT',
          createPayload: () => {
            'descricao': _uid('PedidoCompra'),
            'status': 'RASCUNHO',
            'itens': [],
          },
          updatePayload: (id) => {'descricao': _uid('PedidoCompra EDIT')},
        ),
      ];

      for (final s in scenarios) {
        _runCrud(s);
      }
    });

    // ─────────────────────────────────────────────────────────────────────
    // TELAS READ-ONLY (somente GET)
    // ─────────────────────────────────────────────────────────────────────

    group('📋 TELAS READ-ONLY (GET)', () {
      final getOnlyUrls = <String, String>{
        'Dashboard KPIs': ApiLinks.kpis,
        'Dashboard Finance Series': ApiLinks.getFinance,
        'Dashboard Status Counts': ApiLinks.statusCounts,
        'Dashboard Quarterly': ApiLinks.quarterlyComparison,
        'Dashboard Cliente Dist.': ApiLinks.clientDistribution,
        'Dashboard Trend': ApiLinks.trend,
        'Dashboard Tickets Trend': ApiLinks.ticketsTrend,
        'Dashboard Financeiro': ApiLinks.dashboardFinanceiro,
        'Fluxo de Caixa': ApiLinks.financeFluxoDiario,
        'Saldo Contas': ApiLinks.financeFluxoDiarioPdf,
        'Extrato Operacional': ApiLinks.financeExtratoOperacional,
        'DRE': ApiLinks.dre,
        'DRE Períodos': ApiLinks.drePeriodos,
        'Conciliação — Pendentes': ApiLinks.conciliacaoPendentes,
        'Conciliação — Listar': ApiLinks.conciliacaoListar,
        'Extrato — Importações': ApiLinks.extratoImportacoes,
        'Ponto — Listar': ApiLinks.pontoListar,
        'DP Dashboard': ApiLinks.dpDashboard,
        'DP Relatório Resumo': ApiLinks.dpRelatorioResumo,
        'Documentos': ApiLinks.fecthAllDocumentos,
        'Arquivos GED': ApiLinks.allArquivos,
        'Alertas': ApiLinks.fecthAllAlerts,
        'Cotações': ApiLinks.allCotacoes,
        'Market Overview': ApiLinks.marketOverview,
        'Países': ApiLinks.buscarPaises,
        'NF-e Tipo Operação': ApiLinks.allNfeTipoOperacao,
        'Contingência': ApiLinks.listarContingencia,
        'Rejeições': ApiLinks.listarRejeicoes,
        'Importações DFe': ApiLinks.importacoesDfe,
        'Manifestação Pendentes': ApiLinks.manifestacaoPendentes,
        'Manifestação Histórico': ApiLinks.manifestacaoHistorico,
        'Alertas Certificados': ApiLinks.alertasCertificados,
        'Automações Financeiras': ApiLinks.automacoesFinanceiras,
        'Aprovação Pagamento Fila': ApiLinks.aprovacaoPagamentoFila,
        'Aprovação Compra Fila': ApiLinks.aprovacaoCompraFila,
        'Tabelas de Preço': ApiLinks.tabelasPreco,
        'Descontos': ApiLinks.descontos,
        'Devoluções': ApiLinks.devolucoes,
        'Jobs Monitor': ApiLinks.allJobs,
        'Noticias': ApiLinks.allNoticias,
        'Cobrança Vencidos': ApiLinks.cobrancaVencidos,
        'Cobrança Regras': ApiLinks.cobrancaRegras,
        'Lançamentos Financeiros': ApiLinks.lancamentosFinanceiros,
        'Renegociação': ApiLinks.renegociacao,
        'Baixa Automática Pendentes': ApiLinks.baixaAutomaticaPendentes,
        'Banking Imports': ApiLinks.bankingImports,
        'Workflow Chamados': ApiLinks.workflowChamados,
        'Chats Usuário': ApiLinks.fecthChats,
        'Academia — Listar': ApiLinks.allAcademia,
        'Modalidade — Listar': ApiLinks.allModalidade,
      };

      getOnlyUrls.forEach((name, url) {
        test('GET $name', () async {
          try {
            final r = await http.get(Uri.parse(url), headers: _h);
            final ok = r.statusCode == 200 || r.statusCode == 204;
            _log(name, 'GET', ok, ok ? null : '${r.statusCode}');
            if (!ok) fail('$name → ${r.statusCode}');
          } catch (e) {
            _log(name, 'GET', false, e.toString());
            rethrow;
          }
        });
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // RELATÓRIO FINAL
    // ─────────────────────────────────────────────────────────────────────

    tearDownAll(() {
      const sep = '══════════════════════════════════════════════════════════';
      print('\n\n$sep');
      print('📊  RELATÓRIO — INTEGRAÇÃO SISTÊMICA COMPLETA');
      print(sep);

      var totalPass = 0;
      var totalFail = 0;

      for (final entry in _report.entries) {
        final ops = entry.value;
        final linha = ops.entries.map((e) => '${e.key}:${e.value}').join('  ');
        print('  ${entry.key.padRight(40)} $linha');
        for (final v in ops.values) {
          if (v.contains('✅')) totalPass++;
          if (v.contains('❌')) totalFail++;
        }
      }

      print(sep);
      print('  ✅ Passed: $totalPass   ❌ Failed: $totalFail');
      print('$sep\n');
    });
  });
}
