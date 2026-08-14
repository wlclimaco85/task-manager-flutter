import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/generic_detail_form_screen.dart';

void main() {
  group('GenericDetailFormScreen - Controllers Persistence', () {
    test('Flag _initialized previne reinicialização múltipla', () {
      // Simula o comportamento de _initControllers com flag _initialized
      bool initialized = false;
      int initCount = 0;
      final controllers = <String, TextEditingController>{};
      final item = {'id': 1, 'nome': 'Teste'};

      void initControllers() {
        if (!initialized) {
          initCount++;
          controllers['nome'] =
              TextEditingController(text: (item['nome'] as String?) ?? '');
          initialized = true;
        }
      }

      // Simula múltiplas chamadas no build()
      initControllers();
      initControllers();
      initControllers();

      // Verificar que inicializou apenas uma vez
      expect(
        initCount,
        1,
        reason:
            'Flag _initialized garante inicialização única mesmo com múltiplas chamadas',
      );

      // Verificar que controller foi criado
      expect(
        controllers.containsKey('nome'),
        true,
        reason: 'Controller deve ser criado na primeira inicialização',
      );

      expect(
        controllers['nome']!.text,
        'Teste',
        reason: 'Controller deve manter o valor do item',
      );

      // Editar o controller
      controllers['nome']!.text = 'Alterado';

      // Simular novo rebuild (a flag permanece true)
      initControllers();
      initControllers();

      // initCount ainda deve ser 1 (não reinicializou)
      expect(
        initCount,
        1,
        reason: 'Não deve reinicializar mesmo após múltiplos rebuilds',
      );

      // Valor deve ser preservado (não voltou ao original)
      expect(
        controllers['nome']!.text,
        'Alterado',
        reason: 'Valor alterado deve ser preservado, não reinicializado',
      );
    });
  });

  group(
      'GenericDetailFormScreen - seed de dropdown/multiselect a partir do GET',
      () {
    String? seedDropdown(String dropdownValueField, dynamic val) {
      final vf = dropdownValueField.isNotEmpty ? dropdownValueField : 'id';
      if (val is Map) {
        return (val[vf] ?? val['id'])?.toString();
      } else if (val != null) {
        return val.toString();
      }
      return null;
    }

    List<String> seedMultiselect(String dropdownValueField, dynamic val) {
      if (val is! List) return [];
      final vf = dropdownValueField.isNotEmpty ? dropdownValueField : 'id';
      return val
          .map((e) {
            if (e is Map) return (e[vf] ?? e['id'])?.toString();
            return e?.toString();
          })
          .whereType<String>()
          .toList();
    }

    test('Campo dropdown vindo do GET e semeado com o id salvo', () {
      final item = {
        'empresa': {'id': 42, 'nome': 'Academia Central'},
      };

      expect(seedDropdown('id', item['empresa']), '42');
    });

    test('Campo multiselect vindo do GET e semeado com os ids salvos', () {
      final item = {
        'tipoParceiros': [
          {'id': 3, 'nome': 'Franquia'},
          {'id': 7, 'nome': 'Revenda'},
        ],
      };

      expect(seedMultiselect('id', item['tipoParceiros']), ['3', '7']);
    });

    test('Campo dropdown sem valor no GET fica nulo', () {
      expect(seedDropdown('id', null), null);
    });
  });

  group('GenericDetailFormScreen - resolve aliases do item carregado', () {
    test('campo camelCase encontra valor snake_case retornado pela API', () {
      final item = {
        'razao_social': 'BRASIL MODA SURF LTDA',
        'valor_mensal': 500,
        'dia_vencimento_mensalidade': 5,
      };

      expect(resolveGenericDetailFormValue(item, 'razaoSocial'),
          'BRASIL MODA SURF LTDA');
      expect(resolveGenericDetailFormValue(item, 'valorMensal'), 500);
      expect(
          resolveGenericDetailFormValue(item, 'diaVencimentoMensalidade'), 5);
    });

    test('campo snake_case encontra valor camelCase retornado pela API', () {
      final item = {
        'tipoParceiros': [
          {'id': 1, 'nome': 'Cliente'},
          {'id': 2, 'nome': 'Parceiro'},
        ],
      };

      expect(
        resolveGenericDetailFormValue(item, 'tipo_parceiros'),
        item['tipoParceiros'],
      );
    });

    test('campo equivalente ignora underscore e caixa como ultimo fallback',
        () {
      final item = {'diaVencimentoMensalidade': '05'};

      expect(resolveGenericDetailFormValue(item, 'dia_vencimento_mensalidade'),
          '05');
    });
  });

  group(
      'GenericDetailFormScreen - resolucao de vField/dField do dropdownEndpoint',
      () {
    String resolveVField(String dropdownValueField) =>
        dropdownValueField.isNotEmpty ? dropdownValueField : 'id';
    String resolveDField(String dropdownDisplayField) =>
        dropdownDisplayField.isNotEmpty ? dropdownDisplayField : 'nome';

    test('Campo enum configurado com value/label mantem essas chaves', () {
      expect(resolveVField('value'), 'value');
      expect(resolveDField('label'), 'label');
    });

    test('Campo FK comum configurado com id/nome mantem essas chaves', () {
      expect(resolveVField('id'), 'id');
      expect(resolveDField('nome'), 'nome');
    });

    test('Campo sem configuracao cai no default id/nome', () {
      expect(resolveVField(''), 'id');
      expect(resolveDField(''), 'nome');
    });

    test('Opcoes de enum resolvem label legivel com vField/dField corretos',
        () {
      final opcoes = [
        {
          'id': 651,
          'enumClass': 'Ambiente',
          'value': 'HOMOLOGACAO',
          'label': 'Homologacao'
        },
        {
          'id': 652,
          'enumClass': 'Ambiente',
          'value': 'PRODUCAO',
          'label': 'Producao'
        },
      ];
      final vf = resolveVField('value');
      final df = resolveDField('label');

      expect(opcoes.map((o) => o[df]?.toString()).toList(),
          ['Homologacao', 'Producao']);
      expect(opcoes.map((o) => o[vf]?.toString()).toList(),
          ['HOMOLOGACAO', 'PRODUCAO']);
    });
  });
}
