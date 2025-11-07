import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart'; // ★ adicionado para aplicar o tema

class EmpresaEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EmpresaEditScreen({super.key, required this.initialData});

  @override
  State<EmpresaEditScreen> createState() => _EmpresaEditScreenState();
}

class _EmpresaEditScreenState extends State<EmpresaEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedLogo;

  late TextEditingController _nome;
  late TextEditingController _razaoSocial;
  late TextEditingController _email;
  late TextEditingController _site;
  late TextEditingController _telefone;
  late TextEditingController _rua;
  late TextEditingController _numero;
  late TextEditingController _cidade;
  late TextEditingController _cep;
  late TextEditingController _cnpj;
  late TextEditingController _ie;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nome = TextEditingController(text: d['nome'] ?? '');
    _razaoSocial = TextEditingController(text: d['razaoSocial'] ?? '');
    _email = TextEditingController(text: d['email'] ?? '');
    _site = TextEditingController(text: d['site'] ?? '');
    _telefone = TextEditingController(text: d['telefone'] ?? '');
    _rua = TextEditingController(text: d['rua'] ?? '');
    _numero = TextEditingController(text: d['numero'] ?? '');
    _cidade = TextEditingController(text: d['cidade'] ?? '');
    _cep = TextEditingController(text: d['cep'] ?? '');
    _cnpj = TextEditingController(text: d['cnpj'] ?? '');
    _ie = TextEditingController(text: d['ie'] ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _razaoSocial.dispose();
    _email.dispose();
    _site.dispose();
    _telefone.dispose();
    _rua.dispose();
    _numero.dispose();
    _cidade.dispose();
    _cep.dispose();
    _cnpj.dispose();
    _ie.dispose();
    super.dispose();
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final XFile? f = await _imagePicker.pickImage(
          source: source, maxWidth: 800, maxHeight: 800, imageQuality: 80);
      if (f == null) return;
      final file = File(f.path);
      if (await file.length() > 2 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('A imagem deve ter no máximo 2MB'),
          backgroundColor: GridColors.error,
        ));
        return;
      }
      setState(() => _selectedLogo = file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao selecionar imagem: $e'),
        backgroundColor: GridColors.error,
      ));
    }
  }

  void _showImageSourceDialog() {
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

  Widget _buildLogo() {
    final String? logoUrl = widget.initialData['logo'];
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: GridColors.inputBackground,
          borderRadius: BorderRadius.circular(60),
          border: Border.all(color: GridColors.inputBorder, width: 2),
        ),
        child: Stack(
          children: [
            if (_selectedLogo != null)
              ClipOval(
                  child: Image.file(_selectedLogo!,
                      width: 116, height: 116, fit: BoxFit.cover))
            else if (logoUrl != null && logoUrl.isNotEmpty)
              ClipOval(
                  child: Image.network(
                logoUrl,
                width: 116,
                height: 116,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.apartment,
                    size: 50, color: GridColors.primary),
              ))
            else
              const Icon(Icons.apartment, size: 50, color: GridColors.primary),
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
            )
          ],
        ),
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
      final body = {
        'id': widget.initialData['id'],
        'nome': _nome.text.trim(),
        'razaoSocial': _razaoSocial.text.trim(),
        'email': _email.text.trim(),
        'site': _site.text.trim(),
        'telefone': _telefone.text.trim(),
        'rua': _rua.text.trim(),
        'numero': _numero.text.trim(),
        'cidade': _cidade.text.trim(),
        'cep': _cep.text.trim(),
        'cnpj': _cnpj.text.trim(),
        'ie': _ie.text.trim(),
        'logo': _selectedLogo != null
            ? _selectedLogo!.path
            : widget.initialData['logo'],
      };

      final resp = await NetworkCaller()
          .postRequest(ApiLinks.updateEmpresa(widget.initialData['id']), body);
      Navigator.pop(context); // fecha loading

      if (resp.isSuccess) {
        Navigator.pop(context, body);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Empresa atualizada!'),
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
          title: const Text('Editar Empresa',
              style: TextStyle(
                  color: GridColors.textPrimary, fontWeight: FontWeight.bold)),
          backgroundColor: GridColors.primary,
          iconTheme: const IconThemeData(color: GridColors.textPrimary),
          actions: [
            IconButton(icon: const Icon(Icons.save), onPressed: _save)
          ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            _buildLogo(),
            const SizedBox(height: 12),
            const Text('Clique na logo para alterar',
                style: TextStyle(color: GridColors.textPrimary, fontSize: 12)),
            const SizedBox(height: 24),
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
                      child: Text('Dados da Empresa',
                          style: TextStyle(
                              color: GridColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  _field('Nome *', _nome, required: true),
                  const SizedBox(height: 12),
                  _field('Razão Social', _razaoSocial),
                  const SizedBox(height: 12),
                  _field('CNPJ', _cnpj),
                  const SizedBox(height: 12),
                  _field('IE', _ie),
                  const SizedBox(height: 12),
                  _field('Email', _email, type: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _field('Site', _site),
                  const SizedBox(height: 12),
                  _field('Telefone', _telefone, type: TextInputType.phone),
                  const SizedBox(height: 24),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Endereço',
                          style: TextStyle(
                              color: GridColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  _field('Rua', _rua),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _field('Número', _numero)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field('CEP', _cep, type: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  _field('Cidade', _cidade),
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
