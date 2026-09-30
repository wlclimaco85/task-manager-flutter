import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/network_caller.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/grid_colors.dart';
import '../windows/dialogs/fornecedor_form_dialog.dart';
import 'nfce/nfce_notice_banner.dart';

/// Rotulo legivel da origem do arquivo (BOLETO/SPED/SINTEGRA), como vem do
/// backend em AutomacaoFiscalLogDTO.origem. Funcao pura (fora da classe)
/// pra ser testavel sem depender de rede -- mesmo padrao ja estabelecido em
/// produto_impostos_tab.dart (ver comentario em
/// test/widgets/produto_impostos_tab_test.dart).
String origemLabel(String? origem) {
  switch (origem) {
    case 'BOLETO':
      return 'Boletos';
    case 'SPED':
      return 'SPED';
    case 'SINTEGRA':
      return 'Sintegra';
    case 'XML':
      return 'XML';
    default:
      return origem ?? '-';
  }
}

/// Rotulo legivel do tipo de documento (BoletoTipoDocumento.name() ou tipo XML do
/// backend). Funcao pura, mesmo motivo de origemLabel acima.
String tipoDocumentoLabel(String? tipo) {
  switch (tipo) {
    case 'BOLETO_FORNECEDOR':
      return 'Boleto Fornecedor';
    case 'FGTS':
      return 'FGTS';
    case 'DAE_ICMS':
      return 'DAE ICMS';
    case 'DARF_FEDERAL':
      return 'DARF Federal';
    case 'GUIA_ISS_MUNICIPAL':
      return 'Guia ISS';
    case 'COMPROVANTE_PAGAMENTO':
      return 'Comprovante de Pagamento';
    case 'CTE':
      return 'CT-e (Transporte)';
    case 'NFE':
      return 'NF-e (Entrada)';
    case 'NFCE':
      return 'NFC-e (Consumidor)';
    case 'NFSE':
      return 'NFS-e (Serviço)';
    case null:
      return '-';
    default:
      return 'Não identificado';
  }
}

/// Extrai o primeiro CNPJ (formatado ou 14 dígitos consecutivos) encontrado em um texto/motivo de erro.
/// Funcao pura para facilitar testes automatizados.
String? extrairCnpj(String? texto) {
  if (texto == null || texto.isEmpty) return null;
  final matchFmt = RegExp(r'\b\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}\b').firstMatch(texto);
  if (matchFmt != null) return matchFmt.group(0);
  final matchDigits = RegExp(r'\b\d{14}\b').firstMatch(texto);
  if (matchDigits != null) return matchDigits.group(0);
  return null;
}

/// Gera texto formatado e consolidado contendo todas as exceptions e erros da automação fiscal
/// para cópia direta na área de transferência (Clipboard). Função pura para ser testável.
String formatarRelatorioErrosParaClipboard({
  required List<Map<String, dynamic>> logs,
  DateTime? dataHora,
  String? pastaRaiz,
  String? ultimoResultado,
}) {
  final erros = logs.where((l) => l['status'] == 'ERRO').toList();
  if (erros.isEmpty) {
    if (ultimoResultado != null && ultimoResultado.trim().isNotEmpty) {
      return 'Última execução: $ultimoResultado';
    }
    return 'Nenhum erro registrado na importação fiscal.';
  }

  final buffer = StringBuffer();
  buffer.writeln('====================================================');
  buffer.writeln('RELATÓRIO DE ERROS / EXCEPTIONS - AUTOMAÇÃO FISCAL');
  buffer.writeln('====================================================');
  if (dataHora != null) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm:ss');
    buffer.writeln('Data/Hora: ${fmt.format(dataHora)}');
  }
  if (pastaRaiz != null && pastaRaiz.trim().isNotEmpty) {
    buffer.writeln('Pasta Raiz: ${pastaRaiz.trim()}');
  }
  if (ultimoResultado != null && ultimoResultado.trim().isNotEmpty) {
    buffer.writeln('Resultado: ${ultimoResultado.trim()}');
  }
  buffer.writeln('Total de arquivos com erro: ${erros.length}');
  buffer.writeln('----------------------------------------------------');

  for (int i = 0; i < erros.length; i++) {
    final item = erros[i];
    final arquivo = item['arquivo'] ?? 'Desconhecido';
    final origem = origemLabel(item['origem']?.toString());
    final tipo = tipoDocumentoLabel(item['tipoDocumento']?.toString());
    final msg = item['mensagem'] ?? 'Sem detalhes';
    final dh = item['dhCreatedAt'] != null ? item['dhCreatedAt'].toString() : '';

    buffer.writeln('[${i + 1}] Arquivo: $arquivo');
    buffer.writeln('    Origem: $origem | Tipo: $tipo${dh.isNotEmpty ? " | Data: $dh" : ""}');
    buffer.writeln('    Erro / Exception:');
    buffer.writeln('    $msg');
    buffer.writeln('');
  }
  buffer.writeln('====================================================');

  return buffer.toString();
}

/// Papel de cadastro identificado nos erros de automação fiscal
enum PapelCadastro {
  sacado, // Cliente / Parceiro
  fornecedor, // Fornecedor / Recebedor
}

/// Representa um CNPJ pendente de aprovação de cadastro extraído dos logs de erro.
class PendenciaCadastro {
  final String cnpj;
  final PapelCadastro papel;
  final String arquivo;
  final String? tipoDocumento;
  final String? origem;
  final String? motivo;

  const PendenciaCadastro({
    required this.cnpj,
    required this.papel,
    required this.arquivo,
    this.tipoDocumento,
    this.origem,
    this.motivo,
  });

  String get papelTitulo => papel == PapelCadastro.sacado
      ? 'Sacado (Parceiro / Cliente)'
      : 'Recebedor (Fornecedor)';

  String get papelBadge => papel == PapelCadastro.sacado ? 'SACADO' : 'RECEBEDOR';

  Color get papelColor => papel == PapelCadastro.sacado ? GridColors.secondary : GridColors.warning;

  String get cnpjFormatado {
    final digitos = cnpj.replaceAll(RegExp(r'\D'), '');
    if (digitos.length == 14) {
      return '${digitos.substring(0, 2)}.${digitos.substring(2, 5)}.${digitos.substring(5, 8)}/${digitos.substring(8, 12)}-${digitos.substring(12, 14)}';
    }
    return cnpj;
  }
}

/// Extrai a lista consolidada e desduplicada de pendências de cadastro de Parceiro (Sacado)
/// e Fornecedor (Recebedor) a partir dos logs de erro da automação fiscal.
/// Função pura para garantir 100% de testabilidade unitária sem efeitos colaterais.
List<PendenciaCadastro> extrairPendenciasCadastro(List<Map<String, dynamic>> logs) {
  final pendencias = <PendenciaCadastro>[];
  final chavesVistas = <String>{};

  final erros = logs.where((l) => l['status'] == 'ERRO').toList();

  for (final l in erros) {
    final msg = (l['mensagem'] ?? '').toString();
    final arquivo = (l['arquivo'] ?? 'Arquivo').toString();
    final tipoDoc = l['tipoDocumento']?.toString();
    final origem = l['origem']?.toString();

    // 1. Tags explícitas geradas pelo backend: [FORNECEDOR: cnpj] e [SACADO: cnpj]
    final matchForn = RegExp(r'\[FORNECEDOR:\s*([^\]]+)\]', caseSensitive: false).firstMatch(msg);
    final matchSac = RegExp(r'\[SACADO:\s*([^\]]+)\]', caseSensitive: false).firstMatch(msg);

    bool achouTag = false;
    if (matchForn != null) {
      achouTag = true;
      final raw = matchForn.group(1)?.trim() ?? '';
      final limpo = raw.replaceAll(RegExp(r'\D'), '');
      if (limpo.length >= 11) {
        final chave = 'FORNECEDOR_$limpo';
        if (chavesVistas.add(chave)) {
          pendencias.add(PendenciaCadastro(
            cnpj: limpo,
            papel: PapelCadastro.fornecedor,
            arquivo: arquivo,
            tipoDocumento: tipoDoc,
            origem: origem,
            motivo: msg,
          ));
        }
      }
    }

    if (matchSac != null) {
      achouTag = true;
      final raw = matchSac.group(1)?.trim() ?? '';
      final limpo = raw.replaceAll(RegExp(r'\D'), '');
      if (limpo.length >= 11) {
        final chave = 'SACADO_$limpo';
        if (chavesVistas.add(chave)) {
          pendencias.add(PendenciaCadastro(
            cnpj: limpo,
            papel: PapelCadastro.sacado,
            arquivo: arquivo,
            tipoDocumento: tipoDoc,
            origem: origem,
            motivo: msg,
          ));
        }
      }
    }

    // 2. Se não achou tags estruturadas, verifica padrões textuais ou CNPJ avulso
    if (!achouTag) {
      final cnpjAvulso = extrairCnpj(msg);
      if (cnpjAvulso != null) {
        final limpo = cnpjAvulso.replaceAll(RegExp(r'\D'), '');
        final lower = msg.toLowerCase();
        final ehSacado = lower.contains('sacado') ||
            lower.contains('parceiro') ||
            lower.contains('destinatário') ||
            lower.contains('destinatario') ||
            lower.contains('tomador');
        final papel = ehSacado ? PapelCadastro.sacado : PapelCadastro.fornecedor;
        final chave = '${papel.name.toUpperCase()}_$limpo';
        if (chavesVistas.add(chave)) {
          pendencias.add(PendenciaCadastro(
            cnpj: limpo,
            papel: papel,
            arquivo: arquivo,
            tipoDocumento: tipoDoc,
            origem: origem,
            motivo: msg,
          ));
        }
      }
    }
  }

  return pendencias;
}

/// Tela Sistema > Automacao Fiscal (card automacao-fiscal-pastas,
/// 2026-09-10). Configura a pasta raiz + intervalo de execucao da
/// automacao que escaneia boletos/speds/sintegra (cada uma com
/// sucesso/erro) e cria titulos a pagar automaticamente.
///
/// Compartilhada entre Web, Windows e Mobile (layout responsivo via
/// LayoutBuilder, mesmo padrao de outras telas em lib/widgets/).
class AutomacaoFiscalScreen extends StatefulWidget {
  /// false quando embutida como aba dentro de outra tela (ex.: Config.
  /// Sistema do admin_panel, que ja tem seu proprio AppBar/TabBar) -- evita
  /// Scaffold/AppBar duplicado.
  final bool showAppBar;

  const AutomacaoFiscalScreen({super.key, this.showAppBar = true});

  @override
  State<AutomacaoFiscalScreen> createState() => _AutomacaoFiscalScreenState();
}

class _AutomacaoFiscalScreenState extends State<AutomacaoFiscalScreen> {
  static const _kCompactoBreakpoint = 760.0;

  final _formKey = GlobalKey<FormState>();
  final _pastaRaizCtrl = TextEditingController();
  final _intervaloValorCtrl = TextEditingController(text: '1');

  String _intervaloUnidade = 'DIAS';
  bool _ativo = true;

  bool _carregando = true;
  bool _salvando = false;
  bool _executando = false;
  String? _erroCarregamento;

  DateTime? _ultimaExecucao;
  String? _ultimoResultado;

  List<Map<String, dynamic>> _logs = [];
  bool _carregandoLogs = false;

  final _dataFmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _pastaRaizCtrl.dispose();
    _intervaloValorCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erroCarregamento = null;
    });
    try {
      final resp =
          await NetworkCaller().getRequest('${ApiLinks.baseUrl}/api/automacao-fiscal/config');
      final rawBody = resp.body;
      if (resp.isSuccess && rawBody != null) {
        final body = Map<String, dynamic>.from(rawBody);
        _pastaRaizCtrl.text = (body['pastaRaiz'] ?? '').toString();
        _intervaloValorCtrl.text = (body['intervaloValor'] ?? 1).toString();
        _intervaloUnidade = (body['intervaloUnidade'] ?? 'DIAS').toString();
        _ativo = body['ativo'] == true;
        final ultimaExecucaoStr = body['ultimaExecucao']?.toString();
        _ultimaExecucao =
            ultimaExecucaoStr != null ? DateTime.tryParse(ultimaExecucaoStr) : null;
        _ultimoResultado = body['ultimoResultado']?.toString();
        if (body['ultimosLogs'] != null && body['ultimosLogs'] is List) {
          _logs = List<Map<String, dynamic>>.from(
              (body['ultimosLogs'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
        }
      } else if (!resp.isSuccess && resp.statusCode != 200) {
        _erroCarregamento = 'Erro ao carregar configuração (status ${resp.statusCode}).';
        AppLogger.i.warn(
            '[AutomacaoFiscal] Erro ao carregar config (status ${resp.statusCode})');
      }
    } catch (e, st) {
      _erroCarregamento = 'Erro ao carregar configuração: $e';
      AppLogger.i.error('[AutomacaoFiscal] Erro ao carregar config: $e', st);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
    await _carregarLogs();
  }

  Future<void> _carregarLogs() async {
    setState(() => _carregandoLogs = true);
    try {
      final resp =
          await NetworkCaller().getRequest('${ApiLinks.baseUrl}/api/automacao-fiscal/logs');
      if (resp.isSuccess) {
        List? lista;
        final dynamic raw = resp.body;
        if (raw is List) {
          lista = raw;
        } else if (raw is Map && raw['data'] is List) {
          lista = raw['data'] as List;
        }
        if (lista != null) {
          setState(() {
            _logs = List<Map<String, dynamic>>.from(
                lista!.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
          });
        }
      } else {
        AppLogger.i.warn('[AutomacaoFiscal] Falha ao carregar logs (status ${resp.statusCode})');
      }
    } catch (e, st) {
      // Historico e' informativo -- nao trava o resto da tela se falhar,
      // mas precisa registrar pro Console de Logs (regra de monitoramento).
      AppLogger.i.error('[AutomacaoFiscal] Erro ao carregar histórico: $e', st);
    } finally {
      if (mounted) setState(() => _carregandoLogs = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    try {
      final body = {
        'pastaRaiz': _pastaRaizCtrl.text.trim(),
        'intervaloValor': int.tryParse(_intervaloValorCtrl.text.trim()) ?? 1,
        'intervaloUnidade': _intervaloUnidade,
        'ativo': _ativo,
      };
      final resp = await NetworkCaller()
          .putRequest('${ApiLinks.baseUrl}/api/automacao-fiscal/config', body);

      if (!mounted) return;
      if (resp.isSuccess) {
        _snack('Configuração salva.');
        await _carregar();
      } else {
        _snack('Erro ao salvar (status ${resp.statusCode}).', error: true);
        AppLogger.i.warn('[AutomacaoFiscal] Erro ao salvar config (status ${resp.statusCode})');
      }
    } catch (e, st) {
      if (mounted) _snack('Erro ao salvar: $e', error: true);
      AppLogger.i.error('[AutomacaoFiscal] Erro ao salvar config: $e', st);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _executarAgora() async {
    setState(() => _executando = true);
    try {
      final resp = await NetworkCaller()
          .postRequest('${ApiLinks.baseUrl}/api/automacao-fiscal/executar-agora', {});
      if (!mounted) return;
      final Map<String, dynamic>? body = resp.body is Map ? Map<String, dynamic>.from(resp.body as Map) : null;
      if (resp.isSuccess) {
        String mensagem = 'Execução concluída.';
        if (body != null) {
          if (body['ultimoResultado'] != null) {
            final res = body['ultimoResultado'].toString().trim();
            if (res.isNotEmpty) {
              mensagem = 'Execução concluída ($res).';
              _ultimoResultado = res;
            }
          }
          if (body['ultimaExecucao'] != null) {
            _ultimaExecucao = DateTime.tryParse(body['ultimaExecucao'].toString());
          }
          if (body['ultimosLogs'] != null && body['ultimosLogs'] is List) {
            _logs = List<Map<String, dynamic>>.from(
                (body['ultimosLogs'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
          }
        }
        _snack(mensagem);
        await _carregar();
      } else {
        String msg = 'Erro ao executar (status ${resp.statusCode}).';
        if (body != null && body['message'] != null && body['message'].toString().isNotEmpty) {
          msg = body['message'].toString();
        } else if (body != null && body['erro'] != null && body['erro'].toString().isNotEmpty) {
          msg = body['erro'].toString();
        }
        _snack(msg, error: true);
        AppLogger.i.warn('[AutomacaoFiscal] Erro ao executar agora (status ${resp.statusCode}): $msg');
      }
    } catch (e, st) {
      if (mounted) _snack('Erro ao executar: $e', error: true);
      AppLogger.i.error('[AutomacaoFiscal] Erro ao executar agora: $e', st);
    } finally {
      if (mounted) setState(() => _executando = false);
    }
  }

  void _copiarTodosOsErros() {
    final texto = formatarRelatorioErrosParaClipboard(
      logs: _logs,
      dataHora: _ultimaExecucao,
      pastaRaiz: _pastaRaizCtrl.text,
      ultimoResultado: _ultimoResultado,
    );
    Clipboard.setData(ClipboardData(text: texto));
    final qtdErros = _logs.where((l) => l['status'] == 'ERRO').length;
    _snack(qtdErros > 0
        ? '$qtdErros erros/exceptions copiados para a área de transferência!'
        : 'Resultado copiado para a área de transferência!');
  }

  void _copiarErroIndividual(Map<String, dynamic> log) {
    final arquivo = log['arquivo'] ?? 'Arquivo';
    final msg = log['mensagem'] ?? 'Sem detalhes';
    final origem = origemLabel(log['origem']?.toString());
    final tipo = tipoDocumentoLabel(log['tipoDocumento']?.toString());
    final texto = 'Arquivo: $arquivo\nOrigem: $origem | Tipo: $tipo\nErro / Exception: $msg';
    Clipboard.setData(ClipboardData(text: texto));
    _snack('Erro de $arquivo copiado!');
  }

  Future<void> _cadastrarParceiroReceitaWs(String cnpjRaw) async {
    await _abrirAprovacaoCadastro(PendenciaCadastro(
      cnpj: cnpjRaw,
      papel: PapelCadastro.sacado,
      arquivo: 'Arquivo',
    ));
  }

  Future<void> _abrirAprovacaoCadastro(PendenciaCadastro pendencia) async {
    final cnpj = pendencia.cnpj.replaceAll(RegExp(r'\D'), '');
    if (cnpj.length < 11) {
      _snack('Documento inválido (${pendencia.cnpj})', error: true);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text('Consultando dados na ReceitaWS para ${pendencia.papelTitulo} ($cnpj)...'),
            ),
          ],
        ),
      ),
    );

    Map<String, dynamic>? dadosReceita;
    try {
      // 1. Tenta endpoint backend /api/receitaws/cnpj/{cnpj}
      var resp = await NetworkCaller().getRequest('${ApiLinks.baseUrl}/api/receitaws/cnpj/$cnpj');
      if (resp.isSuccess && resp.body != null && resp.body is Map) {
        dadosReceita = Map<String, dynamic>.from(resp.body as Map);
      } else {
        // 2. Fallback: /api/parceiro/consulta-cnpj/{cnpj}
        resp = await NetworkCaller().getRequest('${ApiLinks.baseUrl}/api/parceiro/consulta-cnpj/$cnpj');
        if (resp.isSuccess && resp.body != null && resp.body is Map) {
          final b = resp.body as Map;
          if (b['data'] != null && b['data'] is Map) {
            dadosReceita = Map<String, dynamic>.from(b['data'] as Map);
          }
        }
      }

      // 3. Fallback direto se chamadas locais falharem
      if (dadosReceita == null && cnpj.length == 14) {
        final directResp = await NetworkCaller().getRequest('https://www.receitaws.com.br/v1/cnpj/$cnpj');
        if (directResp.isSuccess && directResp.body != null && directResp.body is Map) {
          final b = directResp.body as Map;
          if (b['status'] == 'OK' || b['nome'] != null) {
            dadosReceita = {
              'nome': b['nome'],
              'nomeFantasia': b['fantasia'],
              'logradouro': b['logradouro'],
              'numero': b['numero'],
              'complemento': b['complemento'],
              'bairro': b['bairro'],
              'municipio': b['municipio'],
              'uf': b['uf'],
              'cep': b['cep'],
              'telefone': b['telefone'],
              'email': b['email'],
            };
          }
        }
      }
    } catch (e) {
      AppLogger.i.warn('[AutomacaoFiscal] Erro ao consultar ReceitaWS: $e');
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted) return;

    final initialData = <String, dynamic>{
      'nome': (dadosReceita?['nomeFantasia'] ?? dadosReceita?['nome'] ?? '').toString().trim(),
      'razaoSocial': (dadosReceita?['nome'] ?? '').toString().trim(),
      'cpf': cnpj,
      'cnpj': cnpj,
      'ie': '',
      'incrMun': '',
      'email': (dadosReceita?['email'] ?? '').toString().trim(),
      'telefone1': (dadosReceita?['telefone'] ?? '').toString().trim(),
      'telefone2': '',
      'cep': (dadosReceita?['cep'] ?? '').toString().trim(),
      'rua': (dadosReceita?['logradouro'] ?? '').toString().trim(),
      'numero': (dadosReceita?['numero'] ?? '').toString().trim(),
      'complemento': (dadosReceita?['complemento'] ?? '').toString().trim(),
      'bairro': (dadosReceita?['bairro'] ?? '').toString().trim(),
      'cidade': (dadosReceita?['municipio'] ?? '').toString().trim(),
      'estado': (dadosReceita?['uf'] ?? '').toString().trim(),
      'status': 'ATIVO',
      'observacao': 'Cadastrado via Automação Fiscal (${pendencia.papelBadge} - ReceitaWS)',
    };

    if (dadosReceita == null) {
      _snack('Não foi possível obter dados na ReceitaWS. Preencha os campos no formulário.', error: true);
    } else {
      _snack('Dados de ${pendencia.papelBadge} carregados da ReceitaWS com sucesso!');
    }

    final ehSacado = pendencia.papel == PapelCadastro.sacado;
    final titulo = ehSacado
        ? 'Aprovar Cadastro de Parceiro (Sacado)'
        : 'Aprovar Cadastro de Fornecedor (Recebedor)';

    await showDialog(
      context: context,
      builder: (ctx) => FornecedorFormDialog(
        item: initialData,
        tituloOverride: titulo,
        customSaveHandler: ehSacado
            ? (payload) async {
                final parceiroPayload = Map<String, dynamic>.from(payload);
                parceiroPayload['tipoEstabelecimento'] = 'MATRIZ';
                parceiroPayload['endereco'] = {
                  'logradouro': payload['rua'],
                  'numero': payload['numero'],
                  'complemento': payload['complemento'],
                  'bairro': payload['bairro'],
                  'cidade': payload['cidade'],
                  'estado': payload['estado'],
                  'cep': payload['cep'],
                };
                final resp = await NetworkCaller().postRequest(
                  ApiLinks.insertParceiro,
                  parceiroPayload,
                );
                return resp.isSuccess;
              }
            : null,
        onSaved: () async {
          _snack(
            '${ehSacado ? "Parceiro" : "Fornecedor"} cadastrado e aprovado com sucesso! '
            'Agora clique em "Executar agora" para reprocessar os arquivos.',
          );
          await _carregarLogs();
        },
      ),
    );
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? GridColors.error : GridColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final corpo = _carregando
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_erroCarregamento != null) _erroBanner(),
                    _configCard(),
                    const SizedBox(height: 16),
                    _statusBanner(),
                    const SizedBox(height: 16),
                    _pendenciasCadastroCard(),
                    const SizedBox(height: 16),
                    _historicoCard(),
                  ],
                ),
              ),
            ),
          );

    if (!widget.showAppBar) {
      return Container(color: GridColors.pageBackground, child: corpo);
    }

    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      appBar: AppBar(
        title: const Text('Automação Fiscal'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: corpo,
    );
  }

  Widget _erroBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NfceNoticeBanner(
        icon: Icons.error_outline,
        backgroundColor: GridColors.errorLight,
        borderColor: GridColors.error,
        textColor: GridColors.errorDark,
        title: 'Erro',
        message: _erroCarregamento!,
      ),
    );
  }

  /// Observação com a hierarquia exata de pastas esperada, pra tirar
  /// qualquer dúvida de nome/estrutura antes de configurar a pasta raiz.
  /// Pedido do usuário (2026-09-10): deixar claro nome e nível de cada
  /// subpasta -- boletos/speds/sintegra são criadas automaticamente pelo
  /// backend, junto com sucesso/erro dentro de cada uma; o usuário só
  /// precisa soltar os arquivos direto em boletos/, speds/ ou sintegra/.
  Widget _hierarquiaObservacao() {
    const monoStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12.5,
      color: GridColors.textSecondary,
      height: 1.5,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GridColors.filterBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Observação: hierarquia de pastas esperada',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: GridColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '<pasta raiz>\n'
            '├── boletos\\      (PDFs: boletos, guias de tributo, comprovantes)\n'
            '│    ├── sucesso\n'
            '│    └── erro       (com relatorio_erros.txt e detalhe de cada falha)\n'
            '├── speds\\        (arquivos .txt de SPED)\n'
            '│    ├── sucesso\n'
            '│    └── erro       (com relatorio_erros.txt)\n'
            '├── sintegra\\     (arquivos .txt de SINTEGRA)\n'
            '│    ├── sucesso\n'
            '│    └── erro       (com relatorio_erros.txt)\n'
            '└── xmls\\         (arquivos .xml: NF-e, NFC-e, CT-e, NFS-e)\n'
            '     ├── sucesso\n'
            '     └── erro       (com relatorio_erros.txt)',
            style: monoStyle,
          ),
          const SizedBox(height: 6),
          const Text(
            'Os nomes "boletos", "speds", "sintegra", "xmls", "sucesso" e "erro" são fixos '
            '(minúsculo, sem acento) e criados automaticamente pelo sistema dentro da '
            'pasta raiz. A configuração é individual por usuário. '
            'Caso algum arquivo não seja importado, o sistema grava o motivo em "relatorio_erros.txt" '
            'dentro da pasta "erro" correspondente.',
            style: TextStyle(fontSize: 12, color: GridColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ── Card de configuração ─────────────────────────────────────────────

  Widget _configCard() {
    return Card(
      elevation: 0,
      color: GridColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: GridColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configuração',
                style: TextStyle(
                  color: GridColors.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pastaRaizCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pasta raiz',
                  hintText: r'Ex.: C:\AutomacaoFiscal',
                  helperText:
                      'Pasta no servidor/máquina do usuário. Dentro dela serão lidas as '
                      'subpastas "boletos", "speds", "sintegra" e "xmls".',
                  helperMaxLines: 2,
                  prefixIcon: Icon(Icons.folder_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o caminho da pasta raiz.' : null,
              ),
              const SizedBox(height: 10),
              _hierarquiaObservacao(),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, constraints) {
                final compacto = constraints.maxWidth < _kCompactoBreakpoint;
                final campos = [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _intervaloValorCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'A cada',
                        helperText: 'Intervalo entre uma varredura e outra.',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) return 'Informe um número maior que zero.';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: compacto ? 0 : 12, height: compacto ? 12 : 0),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _intervaloUnidade,
                      decoration: const InputDecoration(
                        labelText: 'Unidade',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'HORAS', child: Text('Horas')),
                        DropdownMenuItem(value: 'DIAS', child: Text('Dias')),
                        DropdownMenuItem(value: 'MESES', child: Text('Meses')),
                      ],
                      onChanged: (v) => setState(() => _intervaloUnidade = v ?? 'DIAS'),
                    ),
                  ),
                ];
                return compacto
                    ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: campos)
                    : Row(crossAxisAlignment: CrossAxisAlignment.start, children: campos);
              }),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _ativo,
                activeColor: GridColors.secondary,
                title: const Text('Automação ativa'),
                subtitle: Text(_ativo
                    ? 'Ligada — a próxima varredura ocorre conforme o intervalo configurado.'
                    : 'Desligada — a configuração é mantida, mas nenhuma varredura automática '
                        'será executada.'),
                onChanged: (v) => setState(() => _ativo = v),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(builder: (context, constraints) {
                final compacto = constraints.maxWidth < _kCompactoBreakpoint;
                final salvar = ElevatedButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_salvando ? 'Salvando...' : 'Salvar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                );
                final executar = OutlinedButton.icon(
                  onPressed: _executando ? null : _executarAgora,
                  icon: _executando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.bolt_outlined),
                  label: Text(_executando ? 'Executando...' : 'Executar agora'),
                  style: OutlinedButton.styleFrom(foregroundColor: GridColors.info),
                );
                return compacto
                    ? Column(children: [
                        SizedBox(width: double.infinity, child: salvar),
                        const SizedBox(height: 8),
                        SizedBox(width: double.infinity, child: executar),
                      ])
                    : Wrap(spacing: 12, children: [salvar, executar]);
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Faixa de status ──────────────────────────────────────────────────

  Widget _statusBanner() {
    if (_ultimaExecucao == null) {
      return const NfceNoticeBanner(
        icon: Icons.info_outline,
        backgroundColor: GridColors.filterBackground,
        borderColor: GridColors.divider,
        textColor: GridColors.textSecondary,
        title: 'Última execução',
        message: 'Ainda não houve nenhuma execução. Use "Executar agora" para testar a '
            'configuração.',
      );
    }

    final houveErro = (_ultimoResultado ?? '').contains(RegExp(r'[1-9]\d* erro')) ||
        _logs.any((l) => l['status'] == 'ERRO');
    return NfceNoticeBanner(
      icon: houveErro ? Icons.error_outline : Icons.check_circle_outline,
      backgroundColor: houveErro ? GridColors.errorLight : GridColors.filterBackground,
      borderColor: houveErro ? GridColors.error : GridColors.divider,
      textColor: houveErro ? GridColors.errorDark : GridColors.textSecondary,
      title: 'Última execução',
      message: '${_dataFmt.format(_ultimaExecucao!)} — ${_ultimoResultado ?? ''}'
          '${houveErro ? '. Verifique os erros detalhados abaixo.' : ''}',
      trailing: houveErro
          ? ElevatedButton.icon(
              key: const Key('btn_copiar_erros_banner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.copy_all, size: 16),
              label: const Text('Copiar Erros (Exceptions)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: _copiarTodosOsErros,
            )
          : null,
    );
  }

  // ── Pendências de Aprovação de Parceiros e Fornecedores ─────────────

  Widget _pendenciasCadastroCard() {
    final pendencias = extrairPendenciasCadastro(_logs);
    if (pendencias.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: GridColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: GridColors.warning, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, color: GridColors.warning, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Aprovação de Parceiros e Fornecedores (ReceitaWS)',
                    style: TextStyle(
                      color: GridColors.secondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: GridColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pendencias.length} pendência${pendencias.length > 1 ? "s" : ""}',
                    style: const TextStyle(
                      color: GridColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Identificamos CNPJs de Sacado (Cliente) ou Recebedor (Fornecedor) pendentes nos arquivos com erro. '
              'Clique em "Ver / Aprovar Cadastro" para buscar os dados na ReceitaWS, conferir e aprovar. '
              'Após salvar, clique em "Executar agora" para reprocessar.',
              style: TextStyle(color: GridColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ...pendencias.map(_itemPendenciaWidget),
          ],
        ),
      ),
    );
  }

  Widget _itemPendenciaWidget(PendenciaCadastro p) {
    final ehSacado = p.papel == PapelCadastro.sacado;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GridColors.filterBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ehSacado ? GridColors.secondary : GridColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              p.papelBadge,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      p.cnpjFormatado,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: GridColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${p.papelTitulo}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: GridColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Origem: ${p.arquivo} (${tipoDocumentoLabel(p.tipoDocumento)})',
                  style: const TextStyle(fontSize: 12, color: GridColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            key: Key('btn_aprovar_${p.papelBadge.toLowerCase()}_${p.cnpj}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ehSacado ? GridColors.secondary : GridColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('Ver / Aprovar Cadastro'),
            onPressed: () => _abrirAprovacaoCadastro(p),
          ),
        ],
      ),
    );
  }

  // ── Histórico ────────────────────────────────────────────────────────

  Widget _historicoCard() {
    final errosCount = _logs.where((l) => l['status'] == 'ERRO').length;
    return Card(
      elevation: 0,
      color: GridColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: GridColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Histórico de execuções',
                  style: TextStyle(
                    color: GridColors.secondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (errosCount > 0)
                  OutlinedButton.icon(
                    key: const Key('btn_copiar_erros_historico'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GridColors.error,
                      side: const BorderSide(color: GridColors.error),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.copy_all, size: 16),
                    label: Text(
                      'Copiar Erros ($errosCount)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _copiarTodosOsErros,
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Recarregar histórico',
                  onPressed: _carregarLogs,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_carregandoLogs)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_logs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('Nenhuma execução registrada ainda.',
                      style: TextStyle(color: GridColors.textMuted)),
                ),
              )
            else
              LayoutBuilder(builder: (context, constraints) {
                return constraints.maxWidth < _kCompactoBreakpoint
                    ? Column(children: _logs.map(_logCard).toList())
                    : _logTable();
              }),
          ],
        ),
      ),
    );
  }

  Widget _logTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(GridColors.gridHeader),
        columns: const [
          DataColumn(label: Text('Origem')),
          DataColumn(label: Text('Arquivo')),
          DataColumn(label: Text('Tipo')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Mensagem / Exception')),
          DataColumn(label: Text('Ações')),
        ],
        rows: _logs.map((log) {
          final sucesso = log['status'] == 'SUCESSO';
          final cnpj = extrairCnpj(log['mensagem']?.toString());
          return DataRow(cells: [
            DataCell(Text(origemLabel(log['origem']?.toString()))),
            DataCell(Text(log['arquivo']?.toString() ?? '')),
            DataCell(_tipoChip(log['tipoDocumento']?.toString())),
            DataCell(_statusChip(sucesso)),
            DataCell(SizedBox(
              width: 300,
              child: Text(
                log['mensagem']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: sucesso ? GridColors.textSecondary : GridColors.error, fontSize: 12),
              ),
            )),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!sucesso)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16, color: GridColors.error),
                    tooltip: 'Copiar mensagem/exception deste erro',
                    onPressed: () => _copiarErroIndividual(log),
                  ),
                if (!sucesso && cnpj != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.verified_user_outlined, size: 14),
                    label: const Text('Aprovar (ReceitaWS)'),
                    onPressed: () {
                      final ehSac = (log['mensagem']?.toString().toLowerCase().contains('sacado') == true ||
                          log['mensagem']?.toString().toLowerCase().contains('parceiro') == true ||
                          log['mensagem']?.toString().toLowerCase().contains('destinatario') == true);
                      _abrirAprovacaoCadastro(PendenciaCadastro(
                        cnpj: cnpj,
                        papel: ehSac ? PapelCadastro.sacado : PapelCadastro.fornecedor,
                        arquivo: log['arquivo']?.toString() ?? 'Arquivo',
                        tipoDocumento: log['tipoDocumento']?.toString(),
                        origem: log['origem']?.toString(),
                        motivo: log['mensagem']?.toString(),
                      ));
                    },
                  ),
                if (sucesso) const Text('-'),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _logCard(Map<String, dynamic> log) {
    final sucesso = log['status'] == 'SUCESSO';
    final cnpj = extrairCnpj(log['mensagem']?.toString());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_outlined, size: 18, color: GridColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${origemLabel(log['origem']?.toString())} · ${log['arquivo'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              _statusChip(sucesso),
            ],
          ),
          if (log['tipoDocumento'] != null) ...[
            const SizedBox(height: 6),
            _tipoChip(log['tipoDocumento']?.toString()),
          ],
          if (!sucesso && (log['mensagem'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GridColors.errorLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: GridColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      log['mensagem'].toString(),
                      style: const TextStyle(color: GridColors.errorDark, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16, color: GridColors.errorDark),
                    tooltip: 'Copiar exception',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _copiarErroIndividual(log),
                  ),
                ],
              ),
            ),
          ],
          if (!sucesso && cnpj != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.verified_user_outlined, size: 16),
                label: Text('Aprovar Cadastro CNPJ $cnpj (ReceitaWS)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  final ehSac = (log['mensagem']?.toString().toLowerCase().contains('sacado') == true ||
                      log['mensagem']?.toString().toLowerCase().contains('parceiro') == true ||
                      log['mensagem']?.toString().toLowerCase().contains('destinatario') == true);
                  _abrirAprovacaoCadastro(PendenciaCadastro(
                    cnpj: cnpj,
                    papel: ehSac ? PapelCadastro.sacado : PapelCadastro.fornecedor,
                    arquivo: log['arquivo']?.toString() ?? 'Arquivo',
                    tipoDocumento: log['tipoDocumento']?.toString(),
                    origem: log['origem']?.toString(),
                    motivo: log['mensagem']?.toString(),
                  ));
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(bool sucesso) {
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: sucesso ? GridColors.successLight : GridColors.errorLight,
      label: Text(
        sucesso ? 'Sucesso' : 'Erro',
        style: TextStyle(
          color: sucesso ? GridColors.successDark : GridColors.errorDark,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _tipoChip(String? tipo) {
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: GridColors.surfaceMuted,
      label: Text(
        tipoDocumentoLabel(tipo),
        style: const TextStyle(color: GridColors.textSecondary, fontSize: 11),
      ),
    );
  }

}
