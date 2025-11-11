import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart';
import 'package:task_manager_flutter/ui/widgets/edit_form_helpers.dart';

class ParceiroEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const ParceiroEditScreen({super.key, required this.initialData});

  @override
  State<ParceiroEditScreen> createState() => _ParceiroEditScreenState();
}

class _ParceiroEditScreenState extends State<ParceiroEditScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _logo;
  String? _logoBase64;
  bool _imageTooLarge = false;

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

  List<PaisModel> _paises = [];
  List<EstadoModel> _estados = [];
  List<CidadeModel> _cidades = [];

  int? _paisId;
  int? _estadoId;
  int? _cidadeId;

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

    final end = (d['endereco'] is Map<String, dynamic>)
        ? d['endereco'] as Map<String, dynamic>
        : <String, dynamic>{};

    _logradouro = TextEditingController(text: safeToString(end['logradouro']));
    _numero = TextEditingController(text: safeToString(end['numero']));
    _cep = TextEditingController(text: safeToString(end['cep']));
    _bairro = TextEditingController(text: safeToString(end['bairro']));

    _paisId = safeToInt(end['paisId'] ?? d['paisId']);
    _estadoId = safeToInt(end['estadoId'] ?? d['estadoId']);
    _cidadeId = safeToInt(end['cidadeId'] ?? d['cidadeId']);

    _bootstrapCombos();
  }

  Future<void> _bootstrapCombos() async {
    _paises = await fetchPaises();
    if (_paisId != null) {
      _estados = await fetchEstados(_paisId!);
    }
    if (_estadoId != null) {
      _cidades = await fetchCidades(_estadoId!);
    }
    setState(() {});
  }

  Future<void> _onPaisChanged(int? id) async {
    setState(() {
      _paisId = id;
      _estadoId = null;
      _cidadeId = null;
      _estados = [];
      _cidades = [];
    });
    if (id != null) {
      _estados = await fetchEstados(id);
      setState(() {});
    }
  }

  Future<void> _onEstadoChanged(int? id) async {
    setState(() {
      _estadoId = id;
      _cidadeId = null;
      _cidades = [];
    });
    if (id != null) {
      _cidades = await fetchCidades(id);
      setState(() {});
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
        'paisId': _paisId,
        'estadoId': _estadoId,
        'cidadeId': _cidadeId,
      };

      final req = {
        'id': safeToString(widget.initialData['id']),
        'nome': _nome.text.trim(),
        'cpf': _cpf.text.trim(),
        'telefone1': _telefone1.text.trim(),
        'email': _email.text.trim(),
        'razaoSocial': _razaoSocial.text.trim(),
        'incrMun': _incrMun.text.trim(),
        'observacao': _observacao.text.trim(),
        'valorMensal': safeToString(_valorMensal.text.trim()),
        'ie': _ie.text.trim(),
        'endereco': endereco,
        'logoBase64': _logoBase64 ?? '',
      };

      final resp = await NetworkCaller()
          .postRequest(ApiLinks.updateParceiro(widget.initialData['id']), req);
      if (!mounted) return;
      Navigator.pop(context);

      if (resp.isSuccess) {
        Navigator.pop(context, req);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Parceiro atualizado!'),
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
  void dispose() {
    _nome.dispose();
    _cpf.dispose();
    _telefone1.dispose();
    _email.dispose();
    _razaoSocial.dispose();
    _incrMun.dispose();
    _observacao.dispose();
    _valorMensal.dispose();
    _ie.dispose();
    _logradouro.dispose();
    _numero.dispose();
    _cep.dispose();
    _bairro.dispose();
    super.dispose();
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
              child: Column(children: [
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
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Dados do Parceiro',
                      style: TextStyle(
                          color: GridColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
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
                Row(
                  children: [
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
                  ],
                ),
                buildTextField('Bairro', _bairro),
                buildDropdown<PaisModel>(
                  label: 'País',
                  value: _paises.firstWhere((p) => p.id == _paisId,
                      orElse: () => PaisModel(id: 0, nome: '')),
                  items: _paises,
                  labelBuilder: (p) => p.nome,
                  onChanged: (v) {
                    _onPaisChanged(v?.id);
                    setState(() => _paisId = v?.id);
                  },
                ),
                buildDropdown<EstadoModel>(
                  label: 'Estado',
                  value: _estados.firstWhere((e) => e.id == _estadoId,
                      orElse: () => EstadoModel(id: 0, nome: '', paisId: 0)),
                  items: _estados,
                  labelBuilder: (e) => e.nome,
                  onChanged: (v) {
                    _onEstadoChanged(v?.id);
                    setState(() => _estadoId = v?.id);
                  },
                ),
                buildDropdown<CidadeModel>(
                  label: 'Cidade',
                  value: _cidades.firstWhere((c) => c.id == _cidadeId,
                      orElse: () => CidadeModel(id: 0, nome: '', estadoId: 0)),
                  items: _cidades,
                  labelBuilder: (c) => c.nome,
                  onChanged: (v) => setState(() => _cidadeId = v?.id),
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
