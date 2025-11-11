import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart';

// Helper grande (já existente, NÃO alterado)
import 'package:task_manager_flutter/ui/widgets/edit_form_helpers.dart';
// Model de regime (seu arquivo)
import 'package:task_manager_flutter/data/models/regime_tributario_model.dart';

class EmpresaEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EmpresaEditScreen({super.key, required this.initialData});

  @override
  State<EmpresaEditScreen> createState() => _EmpresaEditScreenState();
}

class _EmpresaEditScreenState extends State<EmpresaEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Imagem
  File? _logo;
  String? _logoBase64;
  bool _imageTooLarge = false;

  // Controllers
  late TextEditingController _nome;
  late TextEditingController _razaoSocial;
  late TextEditingController _email;
  late TextEditingController _site;
  late TextEditingController _contato;
  late TextEditingController _emailContato;
  late TextEditingController _telefoneContato;
  late TextEditingController _telefone;
  late TextEditingController _rua;
  late TextEditingController _numero;
  late TextEditingController _cidadeTxt; // texto livre (mantido)
  late TextEditingController _cep;
  late TextEditingController _cnpj;
  late TextEditingController _ie;

  // Ambientes
  static const _ambientes = ['HOMOLOGACAO', 'PRODUCAO'];
  String? _ambiente;

  // Regime
  List<RegimeTributario> _regimes = [];
  RegimeTributario? _regimeSelecionado;

  // Localização
  List<PaisModel> _paises = [];
  List<EstadoModel> _estados = [];
  List<CidadeModel> _cidades = [];
  PaisModel? _paisSelecionado;
  EstadoModel? _estadoSelecionado;
  CidadeModel? _cidadeSelecionada;

  // Carregando dropdowns
  bool _loadingEstados = false;
  bool _loadingCidades = false;

  // Aplicativo em cache (simulado; pegue do seu cache real)
  Map<String, dynamic>? _appCache;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;

    _nome = TextEditingController(text: safeToString(d['nome']));
    _razaoSocial = TextEditingController(text: safeToString(d['razaoSocial']));
    _email = TextEditingController(text: safeToString(d['email']));
    _site = TextEditingController(text: safeToString(d['site']));
    _contato = TextEditingController(text: safeToString(d['contato']));
    _emailContato =
        TextEditingController(text: safeToString(d['emailContato']));
    _telefoneContato =
        TextEditingController(text: safeToString(d['telefoneContato']));
    _telefone = TextEditingController(text: safeToString(d['telefone']));
    _rua = TextEditingController(text: safeToString(d['rua']));
    _numero = TextEditingController(text: safeToString(d['numero']));
    _cidadeTxt = TextEditingController(text: safeToString(d['cidade']));
    _cep = TextEditingController(text: safeToString(d['cep']));
    _cnpj = TextEditingController(text: safeToString(d['cnpj']));
    _ie = TextEditingController(text: safeToString(d['ie']));

    _ambiente = safeToString(d['ambiente']).isNotEmpty ? d['ambiente'] : null;

    // App do login (ajuste para pegar do seu cache real)
    _appCache = {'id': 1, 'nome': 'AppAcademia'};

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Países
    _paises = await fetchPaises();

    // Pré-seleção (se vierem IDs)
    final paisId = safeToInt(widget.initialData['paisId']);
    final estadoId = safeToInt(widget.initialData['estadoId']);
    final cidadeId = safeToInt(widget.initialData['cidadeId']);

    if (paisId != null) {
      _paisSelecionado = _paises.firstWhere(
        (p) => p.id == paisId,
        orElse: () => PaisModel(id: 0, nome: ''),
      );
      if (_paisSelecionado!.id != 0) {
        _loadingEstados = true;
        setState(() {});
        _estados = await fetchEstados(_paisSelecionado!.id);
        _loadingEstados = false;

        if (estadoId != null) {
          _estadoSelecionado = _estados.firstWhere(
            (e) => e.id == estadoId,
            orElse: () => EstadoModel(id: 0, nome: '', paisId: 0),
          );
          if (_estadoSelecionado!.id != 0) {
            _loadingCidades = true;
            setState(() {});
            _cidades = await fetchCidades(_estadoSelecionado!.id);
            _loadingCidades = false;

            if (cidadeId != null) {
              _cidadeSelecionada = _cidades.firstWhere(
                (c) => c.id == cidadeId,
                orElse: () => CidadeModel(id: 0, nome: '', estadoId: 0),
              );
            }
          }
        }
      }
    }

    // Regimes
    await _loadRegimes();

    setState(() {});
  }

  Future<void> _loadRegimes() async {
    try {
      final List<Map<String, dynamic>> items =
          await RegimeTributario.loadDropdownData();
      _regimes = items
          .map((m) => RegimeTributario(
                id: int.tryParse(m['value']?.toString() ?? ''),
                descricao: m['label']?.toString(),
              ))
          .where((r) => r.id != null)
          .cast<RegimeTributario>()
          .toList();

      final regimeId = safeToInt(widget.initialData['regimeId']);
      if (regimeId != null) {
        _regimeSelecionado = _regimes.firstWhere((r) => r.id == regimeId,
            orElse: () => RegimeTributario());
      }
    } catch (e) {
      debugPrint('Erro carregar regimes: $e');
    }
  }

  Future<void> _pickLogo(ImageSource src) async {
    final (file, base64Str) = await pickImageWithValidation(src);
    if (base64Str == 'LIMITE_EXCEDIDO') {
      setState(() => _imageTooLarge = true);
      return;
    }
    if (file != null) {
      setState(() {
        _logo = file;
        _logoBase64 = base64Str;
        _imageTooLarge = false;
      });
    }
  }

  InputDecoration _dec(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: GridColors.inputBorder),
      suffixIcon: suffix,
      filled: true,
      fillColor: GridColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: GridColors.inputBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: GridColors.inputBorder, width: 1.6),
      ),
    );
  }

  Future<void> _onPaisChanged(PaisModel? v) async {
    setState(() {
      _paisSelecionado = v;
      _estadoSelecionado = null;
      _cidadeSelecionada = null;
      _estados = [];
      _cidades = [];
      _loadingEstados = v != null;
      _loadingCidades = false;
    });
    if (v != null) {
      _estados = await fetchEstados(v.id);
    }
    setState(() => _loadingEstados = false);
  }

  Future<void> _onEstadoChanged(EstadoModel? v) async {
    setState(() {
      _estadoSelecionado = v;
      _cidadeSelecionada = null;
      _cidades = [];
      _loadingCidades = v != null;
    });
    if (v != null) {
      _cidades = await fetchCidades(v.id);
    }
    setState(() => _loadingCidades = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(GridColors.primary),
        ),
      ),
    );

    try {
      // Monte o body mantendo tipos corretos (texto como String, IDs como int)
      final Map<String, dynamic> body = {
        'id': safeToInt(widget.initialData['id']),
        'nome': _nome.text.trim(),
        'razaoSocial': _razaoSocial.text.trim(),
        'email': _email.text.trim(),
        'site': _site.text.trim(),
        'contato': _contato.text.trim(),
        'emailContato': _emailContato.text.trim(),
        'telefoneContato': _telefoneContato.text.trim(),
        'telefone': _telefone.text.trim(),
        'rua': _rua.text.trim(),
        'numero': _numero.text.trim(), // String no entity
        'cidade': _cidadeTxt.text.trim(), // String no entity (campo livre)
        'cep': _cep.text.trim(),
        'cnpj': _cnpj.text.trim(),
        'ie': _ie.text.trim(),
        'ambiente': _ambiente, // enum como String
        'regimeId': _regimeSelecionado?.id, // inteiro (relacionamento)
        'aplicativoId': _appCache?['id'], // inteiro (cache do login)
        // Caso seu backend aceite estes campos para endereçamento
        'paisId': _paisSelecionado?.id,
        'estadoId': _estadoSelecionado?.id,
        'cidadeId': _cidadeSelecionada?.id,
        'logoBase64': _logoBase64 ?? '',
      };

      // LOG detalhado: JSON + tipos
      debugPrint('--- EMPRESA SAVE BODY (JSON) ---');
      debugPrint(const JsonEncoder.withIndent('  ').convert(body));
      debugPrint('--- EMPRESA SAVE BODY (TYPES) ---');
      body.forEach((k, v) {
        debugPrint('$k => ${v == null ? "null" : v.runtimeType}');
      });

      debugPrint('--- ------------- ---');
      debugPrint(ApiLinks.updateEmpresa(widget.initialData['id'].toString()));
      debugPrint('--- ------------- ---');

      final resp = await NetworkCaller().postRequest(
          ApiLinks.updateEmpresa(widget.initialData['id'].toString()), body);

      if (!mounted) return;
      Navigator.pop(context);

      if (resp.isSuccess) {
        if (mounted) {
          Navigator.pop(context, body);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Empresa atualizada com sucesso!'),
            backgroundColor: GridColors.success,
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: ${resp.body ?? "Falha ao atualizar"}'),
          backgroundColor: GridColors.error,
        ));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao salvar: $e'),
        backgroundColor: GridColors.error,
      ));
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _razaoSocial.dispose();
    _email.dispose();
    _site.dispose();
    _contato.dispose();
    _emailContato.dispose();
    _telefoneContato.dispose();
    _telefone.dispose();
    _rua.dispose();
    _numero.dispose();
    _cidadeTxt.dispose();
    _cep.dispose();
    _cnpj.dispose();
    _ie.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        title: const Text(
          'Editar Empresa',
          style: TextStyle(
              color: GridColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: GridColors.primary,
        iconTheme: const IconThemeData(color: GridColors.textPrimary),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Card(
            color: GridColors.card,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  EditableImageCircle(
                    file: _logo,
                    imageUrl: widget.initialData['logo'],
                    placeholderIcon: Icons.apartment,
                    onTap: () => showImageSourceDialog(context, _pickLogo),
                  ),
                  if (_imageTooLarge)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '⚠️ A imagem deve ter no máximo 2MB',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Dados da empresa
                  buildTextField('Nome *', _nome, required: true),
                  buildTextField('Razão Social', _razaoSocial),
                  buildTextFieldMasked('CNPJ', _cnpj,
                      mask: MaskedInputFormatter('00.000.000/0000-00'),
                      required: true,
                      type: TextInputType.number),
                  buildTextFieldMasked('IE', _ie,
                      mask: MaskedInputFormatter('000.000.000.000'),
                      type: TextInputType.number),
                  buildTextField('Email', _email,
                      type: TextInputType.emailAddress),
                  buildTextField('Site', _site),
                  buildTextField('Contato', _contato),
                  buildTextField('Email do Contato', _emailContato,
                      type: TextInputType.emailAddress),
                  buildTextFieldMasked('Telefone do Contato', _telefoneContato,
                      mask: MaskedInputFormatter('(00) 00000-0000'),
                      type: TextInputType.phone),
                  buildTextFieldMasked('Telefone', _telefone,
                      mask: MaskedInputFormatter('(00) 00000-0000'),
                      type: TextInputType.phone),

                  const SizedBox(height: 16),

                  // Regime Tributário
                  DropdownSearch<RegimeTributario>(
                    items: _regimes,
                    selectedItem: _regimeSelecionado,
                    itemAsString: (r) => r.descricao ?? '',
                    onChanged: (v) => setState(() => _regimeSelecionado = v),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration:
                          _dec('Regime Tributário', Icons.account_balance),
                    ),
                    validator: (v) =>
                        v == null ? 'Selecione um regime tributário' : null,
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration:
                            InputDecoration(hintText: 'Pesquisar regime...'),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Ambiente
                  DropdownSearch<String>(
                    items: _ambientes,
                    selectedItem: _ambiente,
                    onChanged: (v) => setState(() => _ambiente = v),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration:
                          _dec('Ambiente', Icons.settings),
                    ),
                    validator: (v) => v == null ? 'Selecione o ambiente' : null,
                    popupProps: const PopupProps.menu(showSearchBox: false),
                  ),

                  const SizedBox(height: 24),

                  // Endereço
                  buildTextField('Rua', _rua),
                  Row(
                    children: [
                      Expanded(child: buildTextField('Número', _numero)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildTextFieldMasked('CEP', _cep,
                            mask: MaskedInputFormatter('00000-000'),
                            type: TextInputType.number),
                      ),
                    ],
                  ),
                  buildTextField('Cidade (texto livre)', _cidadeTxt),

                  const SizedBox(height: 16),

                  // País
                  DropdownSearch<PaisModel>(
                    items: _paises,
                    selectedItem: _paisSelecionado,
                    itemAsString: (p) => p.nome,
                    onChanged: _onPaisChanged,
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: _dec('País', Icons.flag),
                    ),
                    validator: (v) => v == null ? 'Selecione o país' : null,
                    popupProps: const PopupProps.menu(showSearchBox: true),
                  ),

                  const SizedBox(height: 16),

                  // Estado (com loading)
                  DropdownSearch<EstadoModel>(
                    items: _estados,
                    selectedItem: _estadoSelecionado,
                    itemAsString: (e) => e.nome,
                    onChanged: _onEstadoChanged,
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: _dec(
                        _loadingEstados ? 'Estado (carregando...)' : 'Estado',
                        Icons.map_outlined,
                        suffix: _loadingEstados
                            ? const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                    ),
                    validator: (v) => v == null ? 'Selecione o estado' : null,
                    popupProps: const PopupProps.menu(showSearchBox: true),
                  ),

                  const SizedBox(height: 16),

                  // Cidade (com loading)
                  DropdownSearch<CidadeModel>(
                    items: _cidades,
                    selectedItem: _cidadeSelecionada,
                    itemAsString: (c) => c.nome,
                    onChanged: (v) => setState(() => _cidadeSelecionada = v),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: _dec(
                        _loadingCidades ? 'Cidade (carregando...)' : 'Cidade',
                        Icons.location_city,
                        suffix: _loadingCidades
                            ? const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                    ),
                    validator: (v) => v == null ? 'Selecione a cidade' : null,
                    popupProps: const PopupProps.menu(showSearchBox: true),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.buttonBackground,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text(
                      'SALVAR ALTERAÇÕES',
                      style: TextStyle(
                        color: GridColors.buttonText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
