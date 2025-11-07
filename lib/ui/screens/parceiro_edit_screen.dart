import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart'; // ★ adicionado para aplicar o tema

class ParceiroEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const ParceiroEditScreen({super.key, required this.initialData});

  @override
  State<ParceiroEditScreen> createState() => _ParceiroEditScreenState();
}

class _ParceiroEditScreenState extends State<ParceiroEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  File? _logo;

  // Campos básicos (espelhe o DTO que você já tem)
  late TextEditingController _nome;
  late TextEditingController _cpf;
  late TextEditingController _telefone1;
  late TextEditingController _email;
  late TextEditingController _razaoSocial;
  late TextEditingController _incrMun;

  // Endereço
  late TextEditingController _logradouro;
  late TextEditingController _numero;
  late TextEditingController _cep;
  late TextEditingController _bairro;
  late TextEditingController _cidade;
  late TextEditingController _estado;
  late TextEditingController _pais;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nome = TextEditingController(text: d['nome'] ?? '');
    _cpf = TextEditingController(text: d['cpf'] ?? '');
    _telefone1 = TextEditingController(text: d['telefone1'] ?? '');
    _email = TextEditingController(text: d['email'] ?? '');
    _razaoSocial = TextEditingController(text: d['razaoSocial'] ?? '');
    _incrMun = TextEditingController(text: d['incrMun'] ?? '');

    final end = d['endereco'] ?? {};
    _logradouro = TextEditingController(text: end['logradouro'] ?? '');
    _numero = TextEditingController(text: end['numero'] ?? '');
    _cep = TextEditingController(text: end['cep'] ?? '');
    _bairro = TextEditingController(text: end['bairro'] ?? '');
    _cidade = TextEditingController(
        text: (end['cidade'] is Map)
            ? end['cidade']['nome']
            : end['cidade'] ?? '');
    _estado = TextEditingController(
        text: (end['estado'] is Map)
            ? end['estado']['nome']
            : end['estado'] ?? '');
    _pais = TextEditingController(
        text: (end['pais'] is Map) ? end['pais']['nome'] : end['pais'] ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _cpf.dispose();
    _telefone1.dispose();
    _email.dispose();
    _razaoSocial.dispose();
    _incrMun.dispose();
    _logradouro.dispose();
    _numero.dispose();
    _cep.dispose();
    _bairro.dispose();
    _cidade.dispose();
    _estado.dispose();
    _pais.dispose();
    super.dispose();
  }

  Future<void> _pickLogo(ImageSource src) async {
    final x = await _imagePicker.pickImage(
        source: src, maxWidth: 800, maxHeight: 800, imageQuality: 80);
    if (x == null) return;
    final file = File(x.path);
    if (await file.length() > 2 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Logo até 2MB'), backgroundColor: GridColors.error));
      return;
    }
    setState(() => _logo = file);
  }

  void _chooseLogo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GridColors.dialogBackground,
        title: const Text('Selecionar logo',
            style: TextStyle(color: GridColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickLogo(ImageSource.camera);
              },
              child: const Text('Câmera',
                  style: TextStyle(color: GridColors.primary))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickLogo(ImageSource.gallery);
              },
              child: const Text('Galeria',
                  style: TextStyle(color: GridColors.primary))),
        ],
      ),
    );
  }

  Widget _logoWidget() {
    final url = widget.initialData['logo'];
    return GestureDetector(
      onTap: _chooseLogo,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: GridColors.inputBackground,
          borderRadius: BorderRadius.circular(60),
          border: Border.all(color: GridColors.inputBorder, width: 2),
        ),
        child: Stack(children: [
          if (_logo != null)
            ClipOval(
                child: Image.file(_logo!,
                    width: 116, height: 116, fit: BoxFit.cover))
          else if (url != null && url.toString().isNotEmpty)
            ClipOval(
                child: Image.network(
              url,
              width: 116,
              height: 116,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.business,
                  size: 50, color: GridColors.primary),
            ))
          else
            const Icon(Icons.business, size: 50, color: GridColors.primary),
          Positioned(
            right: 0,
            bottom: 0,
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
          )
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(GridColors.primary))));
    try {
      final endereco = {
        'logradouro': _logradouro.text.trim(),
        'numero': _numero.text.trim(),
        'cep': _cep.text.trim(),
        'bairro': _bairro.text.trim(),
        'cidade': {'nome': _cidade.text.trim()},
        'estado': {'nome': _estado.text.trim()},
        'pais': {'nome': _pais.text.trim()},
      };

      final req = {
        'id': widget.initialData['id'],
        'nome': _nome.text.trim(),
        'cpf': _cpf.text.trim(),
        'telefone1': _telefone1.text.trim(),
        'email': _email.text.trim(),
        'razaoSocial': _razaoSocial.text.trim(),
        'incrMun': _incrMun.text.trim(),
        'endereco': endereco,
        // se backend usa fileAttachmentId, envie aqui também se tiver
        'logo': _logo != null ? _logo!.path : widget.initialData['logo'],
      };

      final resp = await NetworkCaller()
          .postRequest(ApiLinks.updateParceiro(widget.initialData['id']), req);
      Navigator.pop(context);

      if (resp.isSuccess) {
        Navigator.pop(context, req);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Parceiro atualizado!'),
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
          child: Column(children: [
            _logoWidget(),
            const SizedBox(height: 8),
            const Text('Clique na logo para alterar',
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
                      child: Text('Dados do Parceiro',
                          style: TextStyle(
                              color: GridColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  _field('Nome *', _nome, required: true),
                  const SizedBox(height: 12),
                  _field('CPF', _cpf, type: TextInputType.number),
                  const SizedBox(height: 12),
                  _field('Telefone', _telefone1, type: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field('Email', _email, type: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _field('Razão Social', _razaoSocial),
                  const SizedBox(height: 12),
                  _field('Inscrição Municipal', _incrMun),
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
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _field('Cidade', _cidade)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Estado', _estado)),
                  ]),
                  const SizedBox(height: 12),
                  _field('País', _pais),
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
