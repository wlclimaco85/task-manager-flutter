import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/edit_form_helpers.dart';
import 'package:task_manager_flutter/data/models/regime_tributario_model.dart';

class EmpresaEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EmpresaEditScreen({super.key, required this.initialData});

  @override
  State<EmpresaEditScreen> createState() => _EmpresaEditScreenState();
}

class _EmpresaEditScreenState extends State<EmpresaEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomColors _colors = CustomColors();

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
  late TextEditingController _cidade;
  late TextEditingController _cep;
  late TextEditingController _cnpj;
  late TextEditingController _ie;

  String? _ambiente;
  RegimeTributario? _regimeSelecionado;
  List<RegimeTributario> _regimes = [];

  // Localização
  List<PaisModel> _paises = [];
  List<EstadoModel> _estados = [];
  List<CidadeModel> _cidades = [];
  PaisModel? _paisSelecionado;
  EstadoModel? _estadoSelecionado;
  CidadeModel? _cidadeSelecionada;

  bool _isLoadingEstados = false;
  bool _isLoadingCidades = false;

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
    _cidade = TextEditingController(text: safeToString(d['cidade']));
    _cep = TextEditingController(text: safeToString(d['cep']));
    _cnpj = TextEditingController(text: safeToString(d['cnpj']));
    _ie = TextEditingController(text: safeToString(d['ie']));
    _ambiente = safeToString(d['ambiente']).isNotEmpty ? d['ambiente'] : null;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _paises = await fetchPaises();
    _appCache = {'id': 1, 'nome': 'AppAcademia'};
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

  Future<void> _loadEstados(PaisModel pais) async {
    setState(() => _isLoadingEstados = true);
    _estados = await fetchEstados(pais.id);
    setState(() => _isLoadingEstados = false);
  }

  Future<void> _loadCidades(EstadoModel estado) async {
    setState(() => _isLoadingCidades = true);
    _cidades = await fetchCidades(estado.id);
    setState(() => _isLoadingCidades = false);
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
      final rawBody = {
        'id': widget.initialData['id'],
        'nome': _nome.text.trim(),
        'razaoSocial': _razaoSocial.text.trim(),
        'email': _email.text.trim(),
        'site': _site.text.trim(),
        'contato': _contato.text.trim(),
        'emailContato': _emailContato.text.trim(),
        'telefoneContato': _telefoneContato.text.trim(),
        'telefone': _telefone.text.trim(),
        'rua': _rua.text.trim(),
        'numero': _numero.text.trim(),
        'cidade': _cidade.text.trim(),
        'cep': _cep.text.trim(),
        'cnpj': _cnpj.text.trim(),
        'ie': _ie.text.trim(),
        'ambiente': _ambiente ?? '',
        'paisId': _paisSelecionado?.id,
        'estadoId': _estadoSelecionado?.id,
        'cidadeId': _cidadeSelecionada?.id,
        'regimeId': _regimeSelecionado?.id,
        'aplicativoId': _appCache?['id'],
        'logoBase64': _logoBase64 ?? '',
      };

      final body = rawBody.map((k, v) => MapEntry(k, v?.toString() ?? ''));

      print('Body para salvar empresa: $body');
      print(ApiLinks.updateEmpresa(widget.initialData['id']));
      final resp = await NetworkCaller()
          .postRequest(ApiLinks.updateEmpresa(widget.initialData['id']), body);

      if (!mounted) return;
      Navigator.pop(context);

      if (resp.isSuccess) {
        Navigator.pop(context, body);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Empresa atualizada com sucesso!'),
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
        title: const Text('Editar Empresa',
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
              child: Column(children: [
                EditableImageCircle(
                  file: _logo,
                  imageUrl: widget.initialData['logo'],
                  placeholderIcon: Icons.apartment,
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
                const SizedBox(height: 16),
                DropdownSearch<RegimeTributario>(
                  items: _regimes,
                  selectedItem: _regimeSelecionado,
                  itemAsString: (item) => item.descricao ?? '',
                  onChanged: (v) => setState(() => _regimeSelecionado = v),
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration:
                        _inputStyle('Regime Tributário', Icons.account_balance),
                  ),
                  validator: (v) => v == null ? 'Selecione o regime' : null,
                  popupProps: const PopupProps.menu(showSearchBox: true),
                ),
                const SizedBox(height: 16),
                DropdownSearch<String>(
                  items: const ['HOMOLOGACAO', 'PRODUCAO'],
                  selectedItem: _ambiente,
                  onChanged: (v) => setState(() => _ambiente = v),
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration:
                        _inputStyle('Ambiente', Icons.settings),
                  ),
                  validator: (v) => v == null ? 'Selecione o ambiente' : null,
                ),
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
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
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
                        popupProps: const PopupProps.menu(showSearchBox: true),
                      ),
                const SizedBox(height: 16),
                _isLoadingCidades
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
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
                      minimumSize: const Size(double.infinity, 56)),
                  child: const Text('SALVAR ALTERAÇÕES',
                      style: TextStyle(
                          color: GridColors.buttonText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
