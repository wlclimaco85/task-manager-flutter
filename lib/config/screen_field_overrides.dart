import '../widgets/generic_grid_windows_screen.dart' show FieldConfigWindows;

/// Mapa centralizado de field overrides por tela.
///
/// Chave = widget.telaNome (ex: 'conta_pagar', 'conta_receber').
/// Valor = lista de FieldConfigWindows — mesma semântica do fieldOverrides inline.
///
/// Regra de prioridade:
///   - Se a tela passou fieldOverrides explicitamente → usa os da tela (ignora este mapa)
///   - Se fieldOverrides == null → usa a entrada deste mapa (se existir)
///   - Se não há entrada → nenhum override aplicado (comportamento original)
///
/// Como usar durante sessão de validação:
///   Adicione uma entrada com o telaNome e liste apenas os campos que precisam mudar.
///   Exemplos de operações comuns:
///
///   Sumir do form:       FieldConfigWindows(fieldName: 'campo', label: '', isInForm: false, isInGrid: false, isVisibleByDefault: false)
///   Mudar label:         FieldConfigWindows(fieldName: 'campo', label: 'Novo Label', isInForm: true)
///   Desabilitar:         FieldConfigWindows(fieldName: 'campo', label: 'Label', isInForm: true, enabled: false)
///   Sumir da grid:       FieldConfigWindows(fieldName: 'campo', label: '', isInGrid: false, isVisibleByDefault: false)

const Map<String, List<FieldConfigWindows>> kScreenFieldOverrides = {
  // Adicione entradas abaixo durante a sessão de validação tela a tela.
  // Formato:
  //
  // 'nome_da_tela': [
  //   FieldConfigWindows(fieldName: 'campo', label: '', isInForm: false, isInGrid: false, isVisibleByDefault: false),
  // ],

  'conta_pagar': [
    // Oculta o campo legado 'parceiro' do form e da grid (substituído por parceiroDev/parceiroRec)
    FieldConfigWindows(fieldName: 'parceiro', label: '', isInForm: false, isInGrid: false, isVisibleByDefault: false),
    // parceiroDev: override já definido inline na tela (dropdown enum); não duplicar aqui
    // parceiroRec: requer TenantContext em runtime, não pode ser const; definido na tela
  ],
};
