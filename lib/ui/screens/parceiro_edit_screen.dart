import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/edit_form_helpers.dart';
import 'package:task_manager_flutter/data/models/regime_tributario_model.dart';

class ParceiroEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const ParceiroEditScreen({super.key, required this.initialData});

  @override
  State<ParceiroEditScreen> createState() => _ParceiroEditScreenState();
}

class _ParceiroEditScreenState extends State<ParceiroEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomColors _colors = CustomColors();

  File? _logo;
  String? _logoBase64;
  bool _imageTooLarge = false;

  // Controllers
  late TextEditingController _nome;
  late TextEditingController _cpf;
  late TextEditingController _telefone1;
  late TextEditingController _email;
  late TextEditingController _razaoSocial;
  late TextEditingController _incrMun;
  late TextEditingController _observacao;
  late TextEditingController _valorMensal;
  late TextEditingController _ie;
  late TextEditingController _logradouro;
  late TextEditingController _numero;
  late TextEditingController _cep;
  late TextEditingController _bairro;

  // Dropdowns
  List<PaisModel> _paises = [];
  List<EstadoModel> _estados = [];
  List<CidadeModel> _cidades = [];
  PaisModel? _paisSelecionado;
  EstadoModel? _estadoSelecionado;
  CidadeModel? _cidadeSelecionada;

  List<RegimeTributario> _regimes = [];
  RegimeTributario? _regimeSelecionado;

  bool _isLoadingEstados = false;
  bool _isLoadingCidades = false;

  Map<String, dynamic>? _appCache;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nome = TextEditingController(text: safeToString(d['nome']));
    _cpf = TextEditingController(text: safeToString(d['cpf']));
    _telefone1 = TextEditingController(text: safeToString(d['telefone1']));
    _email = TextEditingController(text: safeToString(d['email']));
    _razaoSocial = TextEditingController(text: safeToString(d['razaoSocial']));
    _incrMun = TextEditingController(text: safeToString(d['incrMun']));
    _observacao = TextEditingController(text: safeToString(d['observacao']));
    _valorMensal = TextEditingController(text: safeToString(d['valorMensal']));
    _ie = TextEditingController(text: safeToString(d['ie']));
    _logradouro = TextEditingController(text: safeToString(d['logradouro']));
    _numero = TextEditingController(text: safeToString(d['numero']));
    _cep = TextEditingController(text: safeToString(d['cep']));
    _bairro = TextEditingController(text: safeToString(d['bairro']));

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _paises = await fetchPaises();
    _appCache = {'id': 1, 'nome': 'AppAcademia'};
    final dropdownData = await RegimeTributario.loadDropdownData();
    _regimes = dropdownData
        .map((e) => RegimeTributario(
              id: int.tryParse(e['value'].toString()),
              descricao: e['label'],
            ))
        .toList();
    setState(() {});
  }

  Future<void> _loadEstados(PaisModel pais) async {
    setState(() => _isLoadingEstados = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Carregando estados...')),
    );
    _estados = await fetchEstados(pais.id);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _isLoadingEstados = false);
  }

  Future<void> _loadCidades(EstadoModel estado) async {
    setState(() => _isLoadingCidades = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Carregando cidades...')),
    );
    _cidades = await fetchCidades(estado.id);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _isLoadingCidades = false);
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: GridColors.inputBorder),
      filled: true,
      fillColor: GridColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _colors.getBorderInput(), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _colors.getBorderInput(), width: 1.6),
      ),
    );
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
      final endereco = {
        'logradouro': _logradouro.text.trim(),
        'numero': _numero.text.trim(),
        'cep': _cep.text.trim(),
        'bairro': _bairro.text.trim(),
        'paisId': _paisSelecionado?.id,
        'estadoId': _estadoSelecionado?.id,
        'cidadeId': _cidadeSelecionada?.id,
      };

      final body = {
        'id': safeToString(widget.initialData['id']),
        'nome': _nome.text.trim(),
        'cpf': _cpf.text.trim(),
        'telefone1': _telefone1.text.trim(),
        'email': _email.text.trim(),
        'razaoSocial': _razaoSocial.text.trim(),
        'incrMun': _incrMun.text.trim(),
        'observacao': _observacao.text.trim(),
        'valorMensal': _valorMensal.text.trim(),
        'ie': _ie.text.trim(),
        'endereco': endereco,
        'regimeId': _regimeSelecionado?.id,
        'empresaId': _appCache?['id'],
        'logoBase64': _logoBase64 ?? '',
      };

      final resp = await NetworkCaller()
          .postRequest(ApiLinks.updateParceiro(widget.initialData['id']), body);

      if (!mounted) return;
      Navigator.pop(context);

      if (resp.isSuccess) {
        Navigator.pop(context, body);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Parceiro atualizado com sucesso!'),
          backgroundColor: GridColors.success,
        ));
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        title: const Text('Editar Parceiro',
            style: TextStyle(
                color: GridColors.textPrimary, fontWeight: FontWeight.bold)),
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
                    placeholderIcon: Icons.business,
                    onTap: () => showImageSourceDialog(context, _pickLogo),
                  ),
                  if (_imageTooLarge)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('⚠️ A imagem deve ter no máximo 2MB',
                          style: TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  const SizedBox(height: 24),
                  buildTextField('Nome *', _nome, required: true),
                  buildTextFieldMasked('CPF', _cpf,
                      mask: MaskedInputFormatter('000.000.000-00'),
                      required: true,
                      type: TextInputType.number),
                  buildTextFieldMasked('Telefone', _telefone1,
                      mask: MaskedInputFormatter('(00) 00000-0000'),
                      type: TextInputType.phone),
                  buildTextField('Email', _email,
                      type: TextInputType.emailAddress),
                  buildTextField('Razão Social', _razaoSocial),
                  buildTextField('Inscrição Municipal', _incrMun),
                  buildTextFieldMasked('IE', _ie,
                      mask: MaskedInputFormatter('000.000.000.000'),
                      type: TextInputType.number),
                  buildTextFieldMasked('Valor Mensal', _valorMensal,
                      mask: MaskedInputFormatter('000000'),
                      type: TextInputType.number),
                  buildTextField('Observação', _observacao),
                  const SizedBox(height: 16),
                  DropdownSearch<RegimeTributario>(
                    items: _regimes,
                    itemAsString: (r) => r.descricao ?? '',
                    selectedItem: _regimeSelecionado,
                    onChanged: (v) => setState(() => _regimeSelecionado = v),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: _inputStyle(
                        'Regime Tributário',
                        Icons.account_balance,
                      ),
                    ),
                    validator: (v) =>
                        v == null ? 'Selecione um regime tributário' : null,
                    popupProps: const PopupProps.menu(showSearchBox: true),
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Endereço',
                        style: TextStyle(
                            color: GridColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  buildTextField('Logradouro', _logradouro),
                  Row(children: [
                    Expanded(child: buildTextField('Número', _numero)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildTextFieldMasked(
                        'CEP',
                        _cep,
                        mask: MaskedInputFormatter('00000-000'),
                        type: TextInputType.number,
                      ),
                    ),
                  ]),
                  buildTextField('Bairro', _bairro),
                  const SizedBox(height: 16),
                  DropdownSearch<PaisModel>(
                    items: _paises,
                    itemAsString: (p) => p.nome,
                    selectedItem: _paisSelecionado,
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() {
                        _paisSelecionado = v;
                        _estadoSelecionado = null;
                        _cidadeSelecionada = null;
                        _estados = [];
                        _cidades = [];
                      });
                      await _loadEstados(v);
                    },
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: _inputStyle('País', Icons.flag),
                    ),
                    validator: (v) => v == null ? 'Selecione o país' : null,
                    popupProps: const PopupProps.menu(showSearchBox: true),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingEstados
                      ? const CircularProgressIndicator()
                      : DropdownSearch<EstadoModel>(
                          items: _estados,
                          itemAsString: (e) => e.nome,
                          selectedItem: _estadoSelecionado,
                          onChanged: (v) async {
                            if (v == null) return;
                            setState(() {
                              _estadoSelecionado = v;
                              _cidadeSelecionada = null;
                              _cidades = [];
                            });
                            await _loadCidades(v);
                          },
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration:
                                _inputStyle('Estado', Icons.map_outlined),
                          ),
                          validator: (v) =>
                              v == null ? 'Selecione o estado' : null,
                          popupProps:
                              const PopupProps.menu(showSearchBox: true),
                        ),
                  const SizedBox(height: 16),
                  _isLoadingCidades
                      ? const CircularProgressIndicator()
                      : DropdownSearch<CidadeModel>(
                          items: _cidades,
                          itemAsString: (c) => c.nome,
                          selectedItem: _cidadeSelecionada,
                          onChanged: (v) =>
                              setState(() => _cidadeSelecionada = v),
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration:
                                _inputStyle('Cidade', Icons.location_city),
                          ),
                          validator: (v) =>
                              v == null ? 'Selecione a cidade' : null,
                          popupProps:
                              const PopupProps.menu(showSearchBox: true),
                        ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: GridColors.buttonBackground,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        minimumSize: const Size(double.infinity, 56)),
                    child: const Text('SALVAR ALTERAÇÕES',
                        style: TextStyle(
                            color: GridColors.buttonText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
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
