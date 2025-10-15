import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/services/file_caller.dart';
import 'package:task_manager_flutter/data/services/diretorio_caller.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  final FileCaller _caller = FileCaller();
  List<Map<String, dynamic>> _diretorios = [];
  Map<int, List<Map<String, dynamic>>> _arquivos = {};
  bool _isLoading = false;
  Set<int> _expandedTiles = {};

  @override
  void initState() {
    super.initState();
    _loadDiretorios();
  }

  Future<void> _loadDiretorios() async {
    setState(() => _isLoading = true);
    _diretorios = await _caller.fetchDiretorios();
    setState(() => _isLoading = false);
  }

  Future<void> _loadArquivos(int diretorioId) async {
    final arquivos = await _caller.fetchArquivosPorDiretorio(diretorioId);
    setState(() {
      _arquivos[diretorioId] = arquivos;
    });
  }

  Future<void> _marcarComoLido(int id, int dirId) async {
    await _caller.marcarComoLido(id);
    _loadArquivos(dirId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Arquivo marcado como lido.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _confirmDelete(int id, int dirId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir Documento"),
        content: const Text("Deseja realmente excluir este documento?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Cancelar", style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _caller.deleteArquivo(id);
              _loadArquivos(dirId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.green,
                  content: Text("Arquivo excluído com sucesso!"),
                ),
              );
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showUploadDialog() async {
    final _formKey = GlobalKey<FormState>();
    final diretorioCaller = DiretorioCaller();
    final diretorios = await diretorioCaller.fetchDiretoriosDropdown();
    int? diretorioSelecionado;
    String? fileType;
    Uint8List? fileBytes;
    FilePickerResult? result;
    final TextEditingController nomeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text(
            "Enviar Arquivo",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.red, width: 2),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botão para selecionar arquivo
                  OutlinedButton.icon(
                    icon: const Icon(Icons.attach_file, color: Colors.green),
                    label: const Text("Selecionar Arquivo",
                        style: TextStyle(color: Colors.green)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () async {
                      result = await FilePicker.platform.pickFiles();
                      if (result != null) {
                        final file = result!.files.first;
                        fileBytes = file.bytes;
                        if (fileBytes == null && file.path != null) {
                          fileBytes = await File(file.path!).readAsBytes();
                        }
                        final ext = file.name.split('.').last;
                        setStateDialog(() {
                          fileType = ".$ext";
                          nomeController.text = file.name;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  if (nomeController.text.isNotEmpty)
                    Text(
                      "Arquivo selecionado: ${nomeController.text}",
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  const SizedBox(height: 16),

                  // Campo nome
                  TextFormField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: "Nome do Arquivo",
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? "Informe o nome do arquivo"
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Dropdown de diretório
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: "Diretório",
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    items: diretorios
                        .map((e) => DropdownMenuItem<int>(
                              value: e['value'],
                              child: Text(e['label']),
                            ))
                        .toList(),
                    onChanged: (v) => setStateDialog(() {
                      diretorioSelecionado = v;
                    }),
                    validator: (v) =>
                        v == null ? "Selecione um diretório" : null,
                  ),
                  const SizedBox(height: 12),

                  // Campo tipo de arquivo (automático)
                  TextFormField(
                    readOnly: true,
                    controller:
                        TextEditingController(text: fileType ?? "(nenhum)"),
                    decoration: const InputDecoration(
                      labelText: "Tipo de Arquivo (automático)",
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Cancelar", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (fileBytes == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.red,
                        content: Text("Selecione um arquivo antes de enviar."),
                      ),
                    );
                    return;
                  }

                  final success = await _caller.uploadArquivo(
                    bytes: fileBytes!,
                    fileName: nomeController.text,
                    diretorioId: diretorioSelecionado!,
                    empresaId: 1,
                  );

                  if (success) {
                    Navigator.pop(context);
                    _loadDiretorios();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text("Arquivo enviado com sucesso!"),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.red,
                        content: Text("Erro ao enviar arquivo!"),
                      ),
                    );
                  }
                }
              },
              child: const Text("Enviar"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArquivosList(int diretorioId) {
    final arquivos = _arquivos[diretorioId] ?? [];

    if (arquivos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text("Nenhum arquivo disponível",
            style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: arquivos.map((arq) {
        final lido = arq['lido'] == true;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.red, width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            title: Text(arq['nome'] ?? "Sem nome"),
            subtitle: Text(
              lido ? "Lido" : "Não lido",
              style: TextStyle(color: lido ? Colors.green : Colors.red),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.green),
                  onPressed: () => _marcarComoLido(arq['id'], diretorioId),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(arq['id'], diretorioId),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDiretorioBox(Map<String, dynamic> dir) {
    final id = dir['id'];
    final nome = dir['nome'] ?? 'Sem nome';
    final total = dir['totalArquivos'] ?? 0;
    final naoLidos = dir['naoLidos'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedTiles.add(id);
              _loadArquivos(id);
            } else {
              _expandedTiles.remove(id);
            }
          });
        },
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              nome,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              children: [
                if (naoLidos > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text("$naoLidos não lidos",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text("$total docs",
                      style:
                          const TextStyle(color: Colors.black, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildArquivosList(id),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[900],
      appBar: UserBannerAppBar(
        screenTitle: "Gerenciador de Arquivos",
        isLoading: _isLoading,
        showFilterButton: false,
        onRefresh: _loadDiretorios,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _diretorios.isEmpty
              ? const Center(
                  child: Text(
                    "Nenhum diretório disponível",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  itemCount: _diretorios.length,
                  itemBuilder: (context, i) =>
                      _buildDiretorioBox(_diretorios[i]),
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.red, width: 2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: "refresh",
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              elevation: 0,
              onPressed: _loadDiretorios,
              child: const Icon(Icons.refresh),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.red, width: 2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: "add",
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              elevation: 0,
              onPressed: _showUploadDialog,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
