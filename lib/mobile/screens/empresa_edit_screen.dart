import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/empresa_model.dart';
import 'package:task_manager_flutter/models/regime_tributario_model.dart';
import 'package:task_manager_flutter/services/network_caller.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';
import 'package:task_manager_flutter/widgets/edit_form_helpers.dart';

class EmpresaEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EmpresaEditScreen({super.key, required this.initialData});

  @override
  State<EmpresaEditScreen> createState() => _EmpresaEditScreenState();
}

class _EmpresaEditScreenState extends State<EmpresaEditScreen> {
  final _formKey = GlobalKey<FormState>();

  File? _logo;
  bool _imageTooLarge = false;

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
  late TextEditingController _cep;
  late TextEditingController _cnpj;
  late TextEditingController _ie;

  static const _ambientes = ['HOMOLOGACAO', 'PRODUCAO'];
  String? _ambiente;
  RegimeTributario? _regimeSelecionado;
  List<RegimeTributario> _regimes = [];

  List<PaisModel> _paises = [];
  List<EstadoModel> _estados = [];
  List<CidadeModel> _cidades = [];
  PaisModel? _paisSelecionado;
  EstadoModel? _estadoSelecionado;
  CidadeModel? _cidadeSelecionada;

  bool _loadingEstados = false;
  bool _loadingCidades = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nome = TextEditingController(text: safeToString(d['nome']));
    _razaoSocial = TextEditingController(text: safeToString(d['razaoSocial']));
    _email = TextEditingController(text: safeToString(d['email']));
    _site = TextEditingController(text: safeToString(d['site']));
    _contato = TextEditingController(text: safeToString(d['contato']));
    _emailContato = TextEditingController(text: safeToString(d['emailContato']));
    _telefoneContato = TextEditingController(text: safeToString(d['telefoneContato']));
    _telefone = TextEditingController(text: safeToString(d['telefone']));
    _rua = TextEditingController(text: safeToString(d['rua']));
    _numero = TextEditingController(text: safeToString(d['numero']));
    _cep = TextEditingController(text: safeToString(d['cep']));
    _cnpj = TextEditingController(text: safeToString(d['cnpj']));
    _ie = TextEditingController(text: safeToString(d['ie']));
    _ambiente = safeToString(d['ambiente']).isNotEmpty ? d['ambiente'] : null;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _paises = await fetchPaises();
    final cachedPaisId = prefs.getInt('cachedPaisId');
    _paisSelecionado = cachedPaisId != null
        ? _paises.firstWhere((p) => p.id == cachedPaisId,
            orElse: () => _paises.firstWhere(
                (p) => p.nome.toLowerCase().contains('brasil'),
                orElse: () => _paises.isNotEmpty ? _paises.first : PaisModel(id: 0, nome: '')))
        : _paises.firstWhere((p) => p.nome.toLowerCase().contains('brasil'),
            orElse: () => _paises.isNotEmpty ? _paises.first : PaisModel(id: 0, nome: ''));

    if (_paisSelecionado != null && _paisSelecionado!.id != 0) {
      setState(() => _loadingEstados = true);
      _estados = await fetchEstados(_paisSelecionado!.id);
      setState(() => _loadingEstados = false);
      final cachedEstadoId = prefs.getInt('cachedEstadoId');
      _estadoSelecionado = cachedEstadoId != null
          ? _estados.firstWhere((e) => e.id == cachedEstadoId,
              orElse: () => _estados.isNotEmpty ? _estados.first : EstadoModel(id: 0, nome: '', paisId: 0))
          : _estados.firstWhere((e) => e.nome.toLowerCase().contains('minas'),
              orElse: () => _estados.isNotEmpty ? _estados.first : EstadoModel(id: 0, nome: '', paisId: 0));

      if (_estadoSelecionado != null && _estadoSelecionado!.id != 0) {
        setState(() => _loadingCidades = true);
        _cidades = await fetchCidades(_estadoSelecionado!.id);
        setState(() => _loadingCidades = false);
      }
    }
    await _loadRegimes();
    if (mounted) setState(() {});
  }

  Future<void> _loadRegimes() async {
    try {
      final items = await RegimeTributario.loadDropdownData();
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

  Future<void> _pickLogo(dynamic src) async {
    final (file, base64Str) = await pickImageWithValidation(src);
    if (base64Str == 'LIMITE_EXCEDIDO') {
      setState(() => _imageTooLarge = true);
      return;
    }
    if (file != null) setState(() { _logo = file; _imageTooLarge = false; });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      if (_logo != null) {
        // Upload de logo não disponível nesta versão — ignorado
        debugPrint('Upload de logo: funcionalidade pendente de integração');
      }

      final body = {
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
        'numero': _numero.text.trim(),
        'cep': _cep.text.trim(),
        'cnpj': _cnpj.text.trim(),
        'ie': _ie.text.trim(),
        'ambiente': _ambiente,
        'regime': {'id': _regimeSelecionado?.id},
        'pais': {'id': _paisSelecionado?.id},
        'estado': {'id': _estadoSelecionado?.id},
        'cidade': {'id': _cidadeSelecionada?.id},
      };

      final resp = await NetworkCaller().putRequest(
        ApiLinks.updateEmpresa(widget.initialData['id'].toString()),
        body,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (resp.isSuccess) {
        final refreshed = await NetworkCaller()
            .getRequest(ApiLinks.empresaById(widget.initialData['id'].toString()));
        if (refreshed.isSuccess && refreshed.body != null && mounted) {
          final empresaAtualizada = Empresa.fromJson(refreshed.body!);
          if (AuthUtility.userInfo?.login != null) {
            AuthUtility.userInfo!.login!.empresa = empresaAtualizada;
            await AuthUtility.setUserInfo(AuthUtility.userInfo!);
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Empresa atualizada com sucesso!'),
            backgroundColor: GridColors.success,
          ));
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: ${resp.body ?? "Falha ao atualizar"}'),
          backgroundColor: GridColors.error,
        ));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao salvar: $e'),
        backgroundColor: GridColors.error,
      ));
    }
  }

  @override
  void dispose() {
    _nome.dispose(); _razaoSocial.dispose(); _email.dispose(); _site.dispose();
    _contato.dispose(); _emailContato.dispose(); _telefoneContato.dispose();
    _telefone.dispose(); _rua.dispose(); _numero.dispose(); _cep.dispose();
    _cnpj.dispose(); _ie.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        title: const Text('Editar Empresa',
            style: TextStyle(color: GridColors.textPrimary, fontWeight: FontWeight.bold)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      child: Text('⚠️ A imagem deve ter no máximo 2MB',
                          style: TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  const SizedBox(height: 24),
                  buildTextField('Nome *', _nome, required: true),
                  buildTextField('Razão Social', _razaoSocial),
                  buildTextField('CNPJ', _cnpj, type: TextInputType.number),
                  buildTextField('IE', _ie, type: TextInputType.number),
                  buildTextField('Email', _email, type: TextInputType.emailAddress),
                  buildTextField('Site', _site),
                  buildTextField('Contato', _contato),
                  buildTextField('Email do Contato', _emailContato, type: TextInputType.emailAddress),
                  buildTextField('Telefone do Contato', _telefoneContato, type: TextInputType.phone),
                  buildTextField('Telefone', _telefone, type: TextInputType.phone),
                  buildTextField('Rua', _rua),
                  Row(children: [
                    Expanded(child: buildTextField('Número', _numero)),
                    const SizedBox(width: 12),
                    Expanded(child: buildTextField('CEP', _cep, type: TextInputType.number)),
                  ]),
                  const SizedBox(height: 16),
                  _buildPaisDropdown(),
                  const SizedBox(height: 12),
                  _buildEstadoDropdown(),
                  const SizedBox(height: 12),
                  _buildCidadeDropdown(),
                  const SizedBox(height: 16),
                  _buildRegimeDropdown(),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _ambientes.contains(_ambiente) ? _ambiente : null,
                    items: _ambientes.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    decoration: InputDecoration(
                      labelText: 'Ambiente',
                      filled: true,
                      fillColor: GridColors.inputBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setState(() => _ambiente = v),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.buttonBackground,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text('SALVAR ALTERAÇÕES',
                        style: TextStyle(color: GridColors.buttonText, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaisDropdown() {
    return DropdownButtonFormField<PaisModel>(
      initialValue: _paises.contains(_paisSelecionado) ? _paisSelecionado : null,
      items: _paises.map((p) => DropdownMenuItem(value: p, child: Text(p.nome))).toList(),
      decoration: InputDecoration(labelText: 'País', filled: true, fillColor: GridColors.inputBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      onChanged: (v) async {
        setState(() { _paisSelecionado = v; _estadoSelecionado = null; _cidadeSelecionada = null; _estados = []; _cidades = []; _loadingEstados = v != null; });
        if (v != null) { _estados = await fetchEstados(v.id); }
        if (mounted) setState(() => _loadingEstados = false);
      },
    );
  }

  Widget _buildEstadoDropdown() {
    return DropdownButtonFormField<EstadoModel>(
      initialValue: _estados.contains(_estadoSelecionado) ? _estadoSelecionado : null,
      items: _estados.map((e) => DropdownMenuItem(value: e, child: Text(e.nome))).toList(),
      decoration: InputDecoration(labelText: _loadingEstados ? 'Estado (carregando...)' : 'Estado', filled: true, fillColor: GridColors.inputBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      onChanged: (v) async {
        setState(() { _estadoSelecionado = v; _cidadeSelecionada = null; _cidades = []; _loadingCidades = v != null; });
        if (v != null) { _cidades = await fetchCidades(v.id); }
        if (mounted) setState(() => _loadingCidades = false);
      },
    );
  }

  Widget _buildCidadeDropdown() {
    return DropdownButtonFormField<CidadeModel>(
      initialValue: _cidades.contains(_cidadeSelecionada) ? _cidadeSelecionada : null,
      items: _cidades.map((c) => DropdownMenuItem(value: c, child: Text(c.nome))).toList(),
      decoration: InputDecoration(labelText: _loadingCidades ? 'Cidade (carregando...)' : 'Cidade', filled: true, fillColor: GridColors.inputBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      onChanged: (v) => setState(() => _cidadeSelecionada = v),
    );
  }

  Widget _buildRegimeDropdown() {
    return DropdownButtonFormField<RegimeTributario>(
      initialValue: _regimes.contains(_regimeSelecionado) ? _regimeSelecionado : null,
      items: _regimes.map((r) => DropdownMenuItem(value: r, child: Text(r.descricao ?? ''))).toList(),
      decoration: InputDecoration(labelText: 'Regime Tributário', filled: true, fillColor: GridColors.inputBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      onChanged: (v) => setState(() => _regimeSelecionado = v),
    );
  }
}
