import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/generic_detail_form_screen.dart';
import 'package:task_manager_flutter/widgets/generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType;

/// Bug de produção real (2026-08-26, login damiaojuniorcontador@gmail.com,
/// "Abraco Contabilidade", card repetido "3 bilhões de vezes"):
///
/// 1) Um campo "fantasma" (ex.: "Setores" solto, sem uso real) que o
///    backend expõe como `isInForm:true` continuava aparecendo na aba
///    Cadastro mesmo com um `FieldConfigWindows(fieldName: 'setores',
///    isInForm: false)` explicitamente escondendo ele -- o gate de
///    `_buildFormTab` só olhava o `isInForm` do BACKEND, nunca o do
///    override. Bug SISTÊMICO: afeta qualquer tela que use
///    `fieldOverrides` pra esconder um campo já visível no backend.
/// 2) O multiselect "Roles" abria "Selecione..." (nada aparecia) mesmo o
///    registro tendo `roles: [{"id":"21"}]` salvo de verdade -- porque a
///    lista de opções disponíveis (busca assíncrona) não devolvia esse
///    id de volta, e o widget só desenhava chip pra quem batia com uma
///    opção carregada.
///
/// Este teste exercita as DUAS funções puras reais extraídas do widget
/// (`resolveFieldVisibility` e `resolveMultiSelectChipLabel`) -- não uma
/// cópia da lógica -- reproduzindo com os valores exatos do payload real
/// reportado (GET /api/telas/login, PUT /api/login/254).
void main() {
  group('Bug real: campo "Setores" fantasma continuava visível no Cadastro',
      () {
    test(
        'override isInForm:false esconde o campo mesmo com o backend '
        'mandando isInForm:true para esse mesmo campo', () {
      // Reprodução exata: backend (TelaGeneratorServiceImpl) expõe
      // 'setores' com isInForm=true; a tela de detalhe do Login declara um
      // override pra esconder esse campo fantasma (setores.py real é
      // "setors", ver comentário no login_detail_screen.dart).
      const override = FieldConfigWindows(
        fieldName: 'setores',
        label: 'Setores',
        isInForm: false,
      );

      final deveExibir = resolveFieldVisibility(
        backendIsInForm: true, // como o backend realmente manda pra esse campo
        override: override,
      );

      expect(deveExibir, isFalse,
          reason: 'o override isInForm:false precisa ganhar do isInForm:true '
              'do backend -- antes do fix, o campo continuava aparecendo');
    });

    test('sem override, o isInForm do backend continua valendo normalmente',
        () {
      expect(
        resolveFieldVisibility(backendIsInForm: true, override: null),
        isTrue,
      );
      expect(
        resolveFieldVisibility(backendIsInForm: false, override: null),
        isFalse,
      );
    });

    test(
        'override com isInForm:true também tem prioridade -- consegue MOSTRAR '
        'um campo que o backend mandaria isInForm:false', () {
      const override = FieldConfigWindows(
        fieldName: 'foto',
        label: 'Foto',
        fieldType: FieldType.file,
        isInForm: true,
      );

      expect(
        resolveFieldVisibility(backendIsInForm: false, override: override),
        isTrue,
      );
    });
  });

  group(
      'Bug real: multiselect "Roles" ficava "Selecione..." mesmo com role '
      'ja atribuida ao login', () {
    test(
        'role selecionada (id=21) some da lista de opcoes disponiveis -- '
        'chip usa o rotulo capturado do proprio registro, nao fica vazio',
        () {
      // Reprodução exata do payload real:
      // PUT /api/login/254 -> "roles":[{"id":"21"}]
      // GET /api/role/disponiveis?empresaId=20001 (fallback "sempre
      // disponível", sem a role 21 contratada/liberada nesse momento).
      final opcoesDisponiveis = <Map<String, dynamic>>[
        {'id': 1, 'description': 'ROLE_ADMIN'},
        {'id': 2, 'description': 'ROLE_EDITOR'},
        // id 21 (a role real do login) NAO esta nessa lista.
      ];
      final rotulosSalvosDoRegistro = {'21': 'ROLE_CONTABILIDADE_FISCAL'};

      final rotulo = resolveMultiSelectChipLabel(
        selectedId: '21',
        loadedOptions: opcoesDisponiveis,
        valueField: 'id',
        displayField: 'description',
        savedLabels: rotulosSalvosDoRegistro,
      );

      expect(rotulo, 'ROLE_CONTABILIDADE_FISCAL',
          reason: 'antes do fix, nenhum chip aparecia pra essa role -- o '
              'campo parecia vazio mesmo com o dado real salvo');
    });

    test('role selecionada que ESTA na lista de opcoes usa o rotulo real '
        '(atualizado), nao o capturado na inicializacao', () {
      final opcoesDisponiveis = <Map<String, dynamic>>[
        {'id': 21, 'description': 'ROLE_CONTABILIDADE_FISCAL (renomeada)'},
      ];
      final rotulosSalvosDoRegistro = {'21': 'ROLE_CONTABILIDADE_FISCAL'};

      final rotulo = resolveMultiSelectChipLabel(
        selectedId: '21',
        loadedOptions: opcoesDisponiveis,
        valueField: 'id',
        displayField: 'description',
        savedLabels: rotulosSalvosDoRegistro,
      );

      expect(rotulo, 'ROLE_CONTABILIDADE_FISCAL (renomeada)');
    });

    test(
        'sem opcao carregada E sem rotulo salvo (caso raro), cai pro id bruto '
        '-- nunca mais "some" silenciosamente', () {
      final rotulo = resolveMultiSelectChipLabel(
        selectedId: '99',
        loadedOptions: const [],
        valueField: 'id',
        displayField: 'description',
        savedLabels: const {},
      );

      expect(rotulo, '#99');
    });
  });
}
