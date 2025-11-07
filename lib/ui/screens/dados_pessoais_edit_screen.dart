import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart'; // ★ adicionado para aplicar o tema

class PaisModel {
  final int id;
  final String nome;

  PaisModel({required this.id, required this.nome});

  factory PaisModel.fromJson(Map<String, dynamic> json) {
    return PaisModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nome: json['nome'] ?? '',
    );
  }
}

class EstadoModel {
  final int id;
  final String nome;
  final int paisId;

  EstadoModel({required this.id, required this.nome, required this.paisId});

  factory EstadoModel.fromJson(Map<String, dynamic> json) {
    return EstadoModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nome: json['nome'] ?? '',
      paisId: (json['paisId'] as num?)?.toInt() ?? 0,
    );
  }
}

class CidadeModel {
  final int id;
  final String nome;
  final int estadoId;

  CidadeModel({required this.id, required this.nome, required this.estadoId});

  factory CidadeModel.fromJson(Map<String, dynamic> json) {
    return CidadeModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nome: json['nome'] ?? '',
      estadoId: (json['estadoId'] as num?)?.toInt() ?? 0,
    );
  }
}

class DadosPessoaisEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const DadosPessoaisEditScreen({super.key, required this.initialData});

  @override
  State<DadosPessoaisEditScreen> createState() =>
      _DadosPessoaisEditScreenState();
}

class _DadosPessoaisEditScreenState extends State<DadosPessoaisEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  File? _photo;

  // controllers
  late TextEditingController _nome;
  late TextEditingController _cpf;
  late TextEditingController _telefone1;
  late TextEditingController _telefone2;
  late TextEditingController _email;
  late TextEditingController _logradouro;
  late TextEditingController _numero;
  late TextEditingController _cep;
  late TextEditingController _bairro;

  // dropdowns
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
    _nome = TextEditingController(text: d['nome'] ?? '');
    _cpf = TextEditingController(text: d['cpf'] ?? '');
    _telefone1 = TextEditingController(text: d['telefone1'] ?? '');
    _telefone2 = TextEditingController(text: d['telefone2'] ?? '');
    _email = TextEditingController(text: d['email'] ?? '');
    _logradouro = TextEditingController(text: d['logradouro'] ?? '');
    _numero = TextEditingController(text: d['numero'] ?? '');
    _cep = TextEditingController(text: d['cep'] ?? '');
    _bairro = TextEditingController(text: d['bairro'] ?? '');

    // ids vindos do backend (Long no backend; aqui use int)
    _paisId =
        (d['paisId'] is int) ? d['paisId'] : (d['paisId'] as num?)?.toInt();
    _estadoId = (d['estadoId'] is int)
        ? d['estadoId']
        : (d['estadoId'] as num?)?.toInt();
    _cidadeId = (d['cidadeId'] is int)
        ? d['cidadeId']
        : (d['cidadeId'] as num?)?.toInt();

    _loadPaisesEstadosCidades();
  }

  @override
  void dispose() {
    _nome.dispose();
    _cpf.dispose();
    _telefone1.dispose();
    _telefone2.dispose();
    _email.dispose();
    _logradouro.dispose();
    _numero.dispose();
    _cep.dispose();
    _bairro.dispose();
    super.dispose();
  }

  Future<void> _loadPaisesEstadosCidades() async {
    try {
      // ---- Buscar Países ----
      final paisesResp =
          await NetworkCaller().getRequest(ApiLinks.buscarPaises);

      if (paisesResp.isSuccess && paisesResp.body is List) {
        final List<dynamic> jsonList = paisesResp.body as List<dynamic>;
        setState(() {
          _paises = jsonList.map((e) => PaisModel.fromJson(e)).toList();
        });
      }

      // ---- Buscar Estados ----
      if (_paisId != null) {
        final estResp = await NetworkCaller()
            .getRequest(ApiLinks.buscarEstados(_paisId!.toString()));

        if (estResp.isSuccess && estResp.body is List) {
          final List<dynamic> jsonList = estResp.body as List<dynamic>;
          setState(() {
            _estados = jsonList.map((e) => EstadoModel.fromJson(e)).toList();
          });
        }
      }

      // ---- Buscar Cidades ----
      if (_estadoId != null) {
        final cidResp = await NetworkCaller()
            .getRequest(ApiLinks.buscarCidades(_estadoId!.toString()));

        if (cidResp.isSuccess && cidResp.body is List) {
          final List<dynamic> jsonList = cidResp.body as List<dynamic>;
          setState(() {
            _cidades = jsonList.map((e) => CidadeModel.fromJson(e)).toList();
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar países/estados/cidades: $e');
    }
  }

  Future<void> _onPaisChanged(int? id) async {
    setState(() {
      _paisId = id;
      _estadoId = null;
      _cidadeId = null;
      _estados = [];
      _cidades = [];
    });

    if (id == null) return;

    try {
      final estResp = await NetworkCaller()
          .getRequest(ApiLinks.buscarEstados(id.toString()));

      if (estResp.isSuccess && estResp.body is List) {
        final List<dynamic> jsonList = estResp.body as List<dynamic>;
        setState(() {
          _estados = jsonList.map((e) => EstadoModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      print('Erro ao carregar estados: $e');
    }
  }

  Future<void> _onEstadoChanged(int? id) async {
    setState(() {
      _estadoId = id;
      _cidadeId = null;
      _cidades = [];
    });

    if (id == null) return;

    try {
      final cidResp = await NetworkCaller()
          .getRequest(ApiLinks.buscarCidades(id.toString()));

      if (cidResp.isSuccess && cidResp.body is List) {
        final List<dynamic> jsonList = cidResp.body as List<dynamic>;
        setState(() {
          _cidades = jsonList.map((e) => CidadeModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      print('Erro ao carregar cidades: $e');
    }
  }

  Future<void> _pickPhoto(ImageSource src) async {
    final x = await _picker.pickImage(
        source: src, maxWidth: 800, maxHeight: 800, imageQuality: 80);
    if (x == null) return;
    final file = File(x.path);
    if (await file.length() > 2 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Foto até 2MB'), backgroundColor: GridColors.error));
      return;
    }
    setState(() => _photo = file);
  }

  void _choosePhoto() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GridColors.dialogBackground,
        title: const Text('Selecionar foto',
            style: TextStyle(color: GridColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
              child: const Text('Câmera',
                  style: TextStyle(color: GridColors.primary))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
              child: const Text('Galeria',
                  style: TextStyle(color: GridColors.primary))),
        ],
      ),
    );
  }

  Widget _avatar() {
    final url = widget.initialData['photo'];
    return GestureDetector(
      onTap: _choosePhoto,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: GridColors.inputBackground,
          borderRadius: BorderRadius.circular(60),
          border: Border.all(color: GridColors.inputBorder, width: 2),
        ),
        child: Stack(children: [
          if (_photo != null)
            ClipOval(
                child: Image.file(_photo!,
                    width: 116, height: 116, fit: BoxFit.cover))
          else if (url != null && url.toString().isNotEmpty)
            ClipOval(
                child: Image.network(
              url,
              width: 116,
              height: 116,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.person, size: 50, color: GridColors.primary),
            ))
          else
            const Icon(Icons.person, size: 50, color: GridColors.primary),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: GridColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2)),
              child:
                  const Icon(Icons.camera_alt, size: 18, color: Colors.white),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {TextInputType type = TextInputType.text, bool required = false}) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      style: const TextStyle(color: GridColors.textSecondary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: GridColors.textSecondary),
        filled: true,
        fillColor: GridColors.inputBackground,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: GridColors.inputBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: GridColors.primary, width: 2)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: GridColors.inputBorder)),
      ),
      validator: (v) {
        if (required && (v == null || v.isEmpty)) return 'Obrigatório';
        return null;
      },
    );
  }

  DropdownMenuItem<int> _opt(Map<String, dynamic> item) =>
      DropdownMenuItem<int>(
          value: (item['id'] as num).toInt(),
          child: Text(item['nome'] ?? item['name'] ?? '—'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(GridColors.primary))));
    try {
      final req = {
        'id': widget.initialData['id'],
        'nome': _nome.text.trim(),
        'cpf': _cpf.text.trim(),
        'telefone1': _telefone1.text.trim(),
        'telefone2': _telefone2.text.trim(),
        'email': _email.text.trim(),
        'logradouro': _logradouro.text.trim(),
        'numero': _numero.text.trim(),
        'cep': _cep.text.trim(),
        'bairro': _bairro.text.trim(),
        'paisId': _paisId,
        'estadoId': _estadoId,
        'cidadeId': _cidadeId,
        'photo': _photo != null ? _photo!.path : widget.initialData['photo'],
      };

      final resp = await NetworkCaller().putRequest(
          ApiLinks.atualizarDadosPessoais(widget.initialData['id']), req);
      Navigator.pop(context);

      if (resp.isSuccess) {
        Navigator.pop(context, req);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Dados pessoais atualizados!'),
            backgroundColor: GridColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $resp'), backgroundColor: GridColors.error));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: $e'), backgroundColor: GridColors.error));
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
          child: Column(children: [
            _avatar(),
            const SizedBox(height: 8),
            const Text('Clique na foto para alterar',
                style: TextStyle(color: GridColors.textPrimary, fontSize: 12)),
            const SizedBox(height: 16),
            Card(
              color: GridColors.card,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Dados',
                          style: TextStyle(
                              color: GridColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  _field('Nome *', _nome, required: true),
                  const SizedBox(height: 12),
                  _field('CPF', _cpf, type: TextInputType.number),
                  const SizedBox(height: 12),
                  _field('Telefone 1', _telefone1, type: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field('Telefone 2', _telefone2, type: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field('Email', _email, type: TextInputType.emailAddress),
                  const SizedBox(height: 24),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Endereço',
                          style: TextStyle(
                              color: GridColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  _field('Logradouro', _logradouro),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _field('Número', _numero)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field('CEP', _cep, type: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  _field('Bairro', _bairro),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _paisId,
                    items: _paises
                        .map((p) => DropdownMenuItem<int>(
                              value: p.id,
                              child: Text(p.nome),
                            ))
                        .toList(),
                    onChanged: _onPaisChanged,
                    decoration: const InputDecoration(labelText: 'País'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _estadoId,
                    items: _estados
                        .map((e) => DropdownMenuItem<int>(
                              value: e.id,
                              child: Text(e.nome),
                            ))
                        .toList(),
                    onChanged: _onEstadoChanged,
                    decoration: const InputDecoration(labelText: 'Estado'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _cidadeId,
                    items: _cidades
                        .map((c) => DropdownMenuItem<int>(
                              value: c.id,
                              child: Text(c.nome),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _cidadeId = v),
                    decoration: const InputDecoration(labelText: 'Cidade'),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.buttonBackground,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2),
                child: const Text('SALVAR ALTERAÇÕES',
                    style: TextStyle(
                        color: GridColors.buttonText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
