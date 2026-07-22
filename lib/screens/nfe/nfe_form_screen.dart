import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/models/nfe/nfe_item_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_tomador_model.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_items_table.dart';
import 'package:task_manager_flutter/widgets/nfe/responsive_scaffold.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Tela de criação/edição de NFe com layout responsivo
///
/// Layouts:
/// - Mobile (<600px): 1 coluna, campos apilados
/// - Tablet (600-1024px): 2 colunas (cliente esquerda, itens direita)
/// - Desktop (≥1024px): 3 colunas (dados, itens expandíveis, resumo)
class NfeFormScreen extends StatefulWidget {
  const NfeFormScreen({super.key});

  @override
  State<NfeFormScreen> createState() => _NfeFormScreenState();
}

class _NfeFormScreenState extends State<NfeFormScreen> {
  late GlobalKey<FormState> _formKey;
  late TextEditingController _clienteCnpjController;
  late TextEditingController _clienteRazaoSocialController;
  late TextEditingController _naturezaController;
  late TextEditingController _observacoesController;
  late TextEditingController _serieController;

  // Estado local dos itens
  final List<NfeItemModel> _items = [];

  // Valores calculados
  double _subtotal = 0.0;
  double _icms = 0.0;
  double _pis = 0.0;
  double _cofins = 0.0;
  double _desconto = 0.0;
  double _total = 0.0;

  // Estados
  bool _isSubmitting = false;
  String? _validationError;

  // Cliente selecionado
  NfeTomadorModel? _clienteSelecionado;

  // Natureza selecionada
  String? _naturezaSelecionada;

  // Lista de clientes mock (em produção viria de API)
  final List<NfeTomadorModel> _clientes = [
    NfeTomadorModel(
      cnpjCpf: '11222333000181',
      razaoSocial: 'Cliente A Comércio Ltda',
      endereco: 'Rua A',
      numero: '100',
      bairro: 'Centro',
      cep: '01310100',
      uf: 'SP',
      municipio: 'São Paulo',
      email: 'contato@clientea.com',
      telefone: '1133334444',
    ),
    NfeTomadorModel(
      cnpjCpf: '44555666000102',
      razaoSocial: 'Cliente B Indústria Ltda',
      endereco: 'Avenida B',
      numero: '200',
      bairro: 'Industrial',
      cep: '01310200',
      uf: 'SP',
      municipio: 'São Paulo',
      email: 'contato@clienteb.com',
      telefone: '1144445555',
    ),
  ];

  // Naturezas operação mock
  final List<String> _naturezas = [
    'Venda',
    'Devolução',
    'Transferência',
    'Serviço',
  ];

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _clienteCnpjController = TextEditingController();
    _clienteRazaoSocialController = TextEditingController();
    _naturezaController = TextEditingController();
    _observacoesController = TextEditingController();
    _serieController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _clienteCnpjController.dispose();
    _clienteRazaoSocialController.dispose();
    _naturezaController.dispose();
    _observacoesController.dispose();
    _serieController.dispose();
    super.dispose();
  }

  /// Valida CNPJ/CPF formato básico
  bool _validarCnpjCpf(String cnpjCpf) {
    final clean = cnpjCpf.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 11) {
      // CPF: validação básica (length)
      return clean.length == 11;
    } else if (clean.length == 14) {
      // CNPJ: validação básica (length) + mod 11
      return _validarCnpjMod11(clean);
    }
    return false;
  }

  /// Algoritmo de validação CNPJ Mod 11
  bool _validarCnpjMod11(String cnpj) {
    if (cnpj.length != 14) return false;

    // Primeiro dígito verificador
    int sum = 0;
    int multiplier = 5;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(cnpj[i]) * multiplier;
      multiplier = multiplier == 2 ? 9 : multiplier - 1;
    }
    int remainder = sum % 11;
    int digit1 = remainder < 2 ? 0 : 11 - remainder;

    // Segundo dígito verificador
    sum = 0;
    multiplier = 6;
    for (int i = 0; i < 13; i++) {
      sum += int.parse(cnpj[i]) * multiplier;
      multiplier = multiplier == 2 ? 9 : multiplier - 1;
    }
    remainder = sum % 11;
    int digit2 = remainder < 2 ? 0 : 11 - remainder;

    return digit1 == int.parse(cnpj[12]) && digit2 == int.parse(cnpj[13]);
  }

  /// Recalcula totais com base nos itens
  void _recalcularTotais() {
    _subtotal = 0.0;
    for (final item in _items) {
      _subtotal += item.precoTotal;
    }

    // Cálculos baseados em impostos dos itens (real)
    _icms = 0.0;
    _pis = 0.0;
    _cofins = 0.0;
    for (final item in _items) {
      _icms += item.vlIcms;
      _pis += item.vlPis;
      _cofins += item.vlCofins;
    }
    _desconto = 0.0; // sem desconto por enquanto

    _total = _subtotal + _icms + _pis + _cofins - _desconto;

    setState(() {});
  }

  /// Adiciona novo item vazio
  void _adicionarItem() {
    setState(() {
      _items.add(
        NfeItemModel(
          sequencial: _items.length + 1,
          codigoProduto: '',
          descricao: 'Novo Item',
          ncm: '',
          quantidade: 1.0,
          unidade: 'UN',
          precoUnitario: 0.0,
          precoTotal: 0.0,
          cfop: '5102',
          cstIcms: '00',
          aliqIcms: 0.18,
          vlIcms: 0.0,
          aliqPis: 0.0165,
          vlPis: 0.0,
          aliqCofins: 0.076,
          vlCofins: 0.0,
        ),
      );
    });
  }

  /// Remove item pelo índice
  void _removerItem(int index) {
    if (index >= 0 && index < _items.length) {
      setState(() {
        _items.removeAt(index);
      });
      _recalcularTotais();
    }
  }

  /// Edita item (atualiza no estado local)
  void _editarItem(int index, NfeItemModel item) {
    if (index >= 0 && index < _items.length) {
      setState(() {
        _items[index] = item;
      });
      _recalcularTotais();
    }
  }

  /// Seleciona cliente
  void _selecionarCliente(NfeTomadorModel cliente) {
    setState(() {
      _clienteSelecionado = cliente;
      _clienteCnpjController.text = cliente.cnpjCpfFormatado;
      _clienteRazaoSocialController.text = cliente.razaoSocial;
    });
  }

  /// Submete o formulário
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos obrigatórios corretamente')),
      );
      return;
    }

    if (_clienteSelecionado == null) {
      setState(() => _validationError = 'Selecione um cliente');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente')),
      );
      return;
    }

    if (_items.isEmpty) {
      setState(() => _validationError = 'Adicione pelo menos 1 item');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos 1 item')),
      );
      return;
    }

    if (_naturezaSelecionada == null || _naturezaSelecionada!.isEmpty) {
      setState(() => _validationError = 'Selecione a natureza da operação');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a natureza da operação')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _validationError = null;
    });

    try {
      // Prepara dados
      final dados = {
        'tomadorCnpjCpf': _clienteSelecionado!.cnpjCpf,
        'naturezaOperacao': _naturezaSelecionada,
        'serie': int.tryParse(_serieController.text) ?? 1,
        'observacoes': _observacoesController.text.isNotEmpty ? _observacoesController.text : null,
        'itens': _items.map((item) => {
          'codigoProduto': item.codigoProduto,
          'descricao': item.descricao,
          'ncm': item.ncm,
          'quantidade': item.quantidade,
          'unidade': item.unidade,
          'precoUnitario': item.precoUnitario,
          'cfop': item.cfop,
          'cstIcms': item.cstIcms,
          'aliqIcms': item.aliqIcms,
          'vlIcms': item.vlIcms,
          'aliqPis': item.aliqPis,
          'vlPis': item.vlPis,
          'aliqCofins': item.aliqCofins,
          'vlCofins': item.vlCofins,
        }).toList(),
      };

      L.d('[NfeFormScreen] Enviando dados: $dados');

      // Chama notifier para criar NFe
      final nfeNotifier = context.read<NfeNotifier>();
      await nfeNotifier.criarNfe(dados);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NFe #${nfeNotifier.state.selected?.numero ?? ''} criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navega para detail screen
        if (nfeNotifier.state.selected != null) {
          Navigator.of(context).pushReplacementNamed(
            '/nfe/detail',
            arguments: nfeNotifier.state.selected!.id,
          );
        }
      }
    } catch (e) {
      L.e('[NfeFormScreen] Erro ao criar NFe: $e');
      if (mounted) {
        setState(() => _validationError = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar NFe: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Retorna widget baseado no breakpoint
  Widget _buildForm(Breakpoint breakpoint) {
    return switch (breakpoint) {
      Breakpoint.mobile => _buildMobileLayout(),
      Breakpoint.tablet => _buildTabletLayout(),
      Breakpoint.desktop => _buildDesktopLayout(),
    };
  }

  /// Layout mobile (1 coluna)
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingSm),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClienteSection(),
              const SizedBox(height: DesignTokens.spacingMd),
              _buildNaturezaSection(),
              const SizedBox(height: DesignTokens.spacingMd),
              _buildSerieSection(),
              const SizedBox(height: DesignTokens.spacingMd),
              _buildObservacoesSection(),
              const SizedBox(height: DesignTokens.spacingMd),
              _buildItemsSection(),
              const SizedBox(height: DesignTokens.spacingMd),
              _buildTotaisSection(),
              const SizedBox(height: DesignTokens.spacingLg),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Layout tablet (2 colunas)
  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coluna esquerda: dados gerais
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClienteSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildNaturezaSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildSerieSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildObservacoesSection(),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.spacingMd),
              // Coluna direita: itens
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildItemsSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildTotaisSection(),
                    const SizedBox(height: DesignTokens.spacingLg),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Layout desktop (3 colunas)
  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coluna 1: Dados gerais
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClienteSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildNaturezaSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildSerieSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildObservacoesSection(),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.spacingLg),
              // Coluna 2: Itens expandíveis
              Expanded(
                flex: 2,
                child: _buildItemsSection(),
              ),
              const SizedBox(width: DesignTokens.spacingLg),
              // Coluna 3: Resumo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTotaisSection(),
                    const SizedBox(height: DesignTokens.spacingLg),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Seção de seleção de cliente
  Widget _buildClienteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cliente *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        // Dropdown de clientes
        DropdownButtonFormField<NfeTomadorModel>(
          value: _clienteSelecionado,
          hint: const Text('Selecione um cliente'),
          items: _clientes.map((cliente) {
            return DropdownMenuItem(
              value: cliente,
              child: Text('${cliente.razaoSocial} (${cliente.cnpjCpfFormatado})'),
            );
          }).toList(),
          onChanged: (cliente) {
            if (cliente != null) {
              _selecionarCliente(cliente);
            }
          },
          validator: (value) => value == null ? 'Cliente obrigatório' : null,
          decoration: InputDecoration(
            hintText: 'Selecione um cliente',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        // CNPJ/CPF do cliente
        TextFormField(
          controller: _clienteCnpjController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'CNPJ/CPF',
            hintText: '00.000.000/0000-00',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        // Razão social
        TextFormField(
          controller: _clienteRazaoSocialController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Razão Social',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// Seção de natureza da operação
  Widget _buildNaturezaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Natureza da Operação *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _naturezaSelecionada,
          hint: const Text('Selecione a natureza'),
          items: _naturezas.map((natureza) {
            return DropdownMenuItem(value: natureza, child: Text(natureza));
          }).toList(),
          onChanged: (natureza) {
            setState(() => _naturezaSelecionada = natureza);
          },
          validator: (value) => value == null ? 'Natureza obrigatória' : null,
          decoration: InputDecoration(
            hintText: 'Selecione a natureza',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// Seção de série
  Widget _buildSerieSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Série',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _serieController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1',
            helperText: 'Deixe em branco para auto-incrementar',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// Seção de observações
  Widget _buildObservacoesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observações',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _observacoesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Adicione observações se necessário',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// Seção de itens (tabela/cards)
  Widget _buildItemsSection() {
    final width = MediaQuery.of(context).size.width;
    final breakpoint = width < 600
        ? Breakpoint.mobile
        : width < 1024
            ? Breakpoint.tablet
            : Breakpoint.desktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Itens *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            ElevatedButton.icon(
              onPressed: _adicionarItem,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Item'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('Nenhum item adicionado. Clique em "Adicionar Item"'),
            ),
          )
        else
          NfeItemsTable(
            items: _items,
            breakpoint: breakpoint,
            editable: true,
            onEdit: (index) => _editarItem(index, _items[index]),
            onDelete: _removerItem,
          ),
      ],
    );
  }

  /// Seção de totais (read-only)
  Widget _buildTotaisSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo de Totais',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Divider(),
          _buildTotalRow('Subtotal', _subtotal),
          _buildTotalRow('ICMS (18%)', _icms),
          _buildTotalRow('PIS (1,65%)', _pis),
          _buildTotalRow('COFINS (7,6%)', _cofins),
          _buildTotalRow('Desconto', -_desconto, isDiscount: true),
          const Divider(),
          _buildTotalRow('TOTAL', _total, isTotal: true),
        ],
      ),
    );
  }

  /// Row de total formatado
  Widget _buildTotalRow(String label, double value, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isDiscount || isTotal ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Botão de submissão
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          disabledBackgroundColor: Colors.grey[400],
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Criar NFe',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final breakpoint = width < 600
        ? Breakpoint.mobile
        : width < 1024
            ? Breakpoint.tablet
            : Breakpoint.desktop;

    return ResponsiveScaffold(
      title: 'Nova Nota Fiscal Eletrônica',
      breakpoint: breakpoint,
      body: _buildForm(breakpoint),
    );
  }
}
