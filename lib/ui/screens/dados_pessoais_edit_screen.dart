import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/edit_form_helpers.dart';

class DadosPessoaisEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const DadosPessoaisEditScreen({super.key, required this.initialData});

  @override
  State<DadosPessoaisEditScreen> createState() =>
      _DadosPessoaisEditScreenState();
}

class _DadosPessoaisEditScreenState extends State<DadosPessoaisEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomColors _colors = CustomColors();

  File? _photo;
  String? _photoBase64;
  bool _imageTooLarge = false;

  late TextEditingController _nome;
  late TextEditingController _cpf;
  late TextEditingController _telefone1;
  late TextEditingController _telefone2;
  late TextEditingController _email;
  late TextEditingController _logradouro;
  late TextEditingController _numero;
  late TextEditingController _cep;
  late TextEditingController _bairro;

  List<PaisModel> _paises = [];
  List<EstadoModel> _estados = [];
  List<CidadeModel> _cidades = [];
  PaisModel? _paisSelecionado;
  EstadoModel? _estadoSelecionado;
  CidadeModel? _cidadeSelecionada;

  bool _isLoadingEstados = false;
  bool _isLoadingCidades = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nome = TextEditingController(text: safeToString(d['nome']));
    _cpf = TextEditingController(text: safeToString(d['cpf']));
    _telefone1 = TextEditingController(text: safeToString(d['telefone1']));
    _telefone2 = TextEditingController(text: safeToString(d['telefone2']));
    _email = TextEditingController(text: safeToString(d['email']));
    _logradouro = TextEditingController(text: safeToString(d['logradouro']));
    _numero = TextEditingController(text: safeToString(d['numero']));
    _cep = TextEditingController(text: safeToString(d['cep']));
    _bairro = TextEditingController(text: safeToString(d['bairro']));
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _paises = await fetchPaises();
    if (mounted) setState(() {});
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

  Future<void> _pickPhoto(ImageSource src) async {
    final (file, base64Str) = await pickImageWithValidation(src);
    if (base64Str == 'LIMITE_EXCEDIDO') {
      setState(() => _imageTooLarge = true);
      return;
    }
    if (file != null) {
      setState(() {
        _photo = file;
        _photoBase64 = base64Str;
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
      final body = {
        'id': safeToString(widget.initialData['id']),
        'nome': _nome.text.trim(),
        'cpf': _cpf.text.trim(),
        'telefone1': _telefone1.text.trim(),
        'telefone2': _telefone2.text.trim(),
        'email': _email.text.trim(),
        'logradouro': _logradouro.text.trim(),
        'numero': _numero.text.trim(),
        'cep': _cep.text.trim(),
        'bairro': _bairro.text.trim(),
        'paisId': _paisSelecionado?.id,
        'estadoId': _estadoSelecionado?.id,
        'cidadeId': _cidadeSelecionada?.id,
        'photoBase64': _photoBase64 ?? '',
      };

      final resp = await NetworkCaller().putRequest(
          ApiLinks.atualizarDadosPessoais(widget.initialData['id']), body);
      if (!mounted) return;
      Navigator.pop(context);
      if (resp.isSuccess) {
        Navigator.pop(context, body);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dados pessoais atualizados com sucesso!'),
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
        title: const Text('Editar Dados Pessoais',
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
                    file: _photo,
                    imageUrl: widget.initialData['photo'],
                    placeholderIcon: Icons.person,
                    onTap: () => showImageSourceDialog(context, _pickPhoto),
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
                  buildTextFieldMasked('Telefone 1', _telefone1,
                      mask: MaskedInputFormatter('(00) 00000-0000'),
                      type: TextInputType.phone),
                  buildTextFieldMasked('Telefone 2', _telefone2,
                      mask: MaskedInputFormatter('(00) 00000-0000'),
                      type: TextInputType.phone),
                  buildTextField('Email', _email,
                      type: TextInputType.emailAddress),
                  const SizedBox(height: 16),
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
