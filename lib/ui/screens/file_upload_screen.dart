import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:task_manager_flutter/data/services/file_caller.dart';
import 'package:task_manager_flutter/data/services/diretorio_caller.dart';
import 'package:task_manager_flutter/data/services/parceiro_caller.dart';
import 'package:task_manager_flutter/data/utils/utils.dart';
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
    setState(() => _arquivos[diretorioId] = arquivos);
  }

  Future<void> _marcarComoLido(int id, int dirId) async {
    await _caller.marcarComoLido(id);
    _loadArquivos(dirId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Arquivo marcado como lido.'),
          backgroundColor: Colors.green),
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
              child: const Text("Cancelar",
                  style: TextStyle(color: Colors.green))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _caller.deleteArquivo(id);
              _loadArquivos(dirId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    backgroundColor: Colors.green,
                    content: Text("Arquivo excluído com sucesso!")),
              );
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<File> _writeTempFile(Uint8List bytes) async {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/preview.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _showUploadDialog() async {
    final _formKey = GlobalKey<FormState>();
    final diretorioCaller = DiretorioCaller();
    final parceiroCaller = ParceiroCaller();

    final diretorios = await diretorioCaller.fetchDiretoriosDropdown();
    final parceiros = await parceiroCaller.fetchParceiross();
    final empresa = await pegarEmpresaLogada();

    int? diretorioSelecionado;
    int? parceiroSelecionado;
    Uint8List? fileBytes;
    String? fileName;
    String? fileType;

    final TextEditingController nomeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Enviar Arquivo",
              style:
                  TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
                  OutlinedButton.icon(
                    icon: const Icon(Icons.attach_file, color: Colors.green),
                    label: const Text("Selecionar Arquivo",
                        style: TextStyle(color: Colors.green)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red)),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles();
                      if (result != null) {
                        final file = result.files.first;
                        fileBytes =
                            file.bytes ?? await File(file.path!).readAsBytes();
                        fileName = file.name;
                        fileType = ".${file.name.split('.').last}";
                        setStateDialog(() => nomeController.text = fileName!);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  if (fileName != null)
                    Text("Selecionado: $fileName",
                        style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: "Nome do Arquivo",
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2)),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? "Informe o nome do arquivo"
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: "Diretório",
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2)),
                    ),
                    items: diretorios
                        .map((e) => DropdownMenuItem<int>(
                              value: e['value'],
                              child: Text(e['label']),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setStateDialog(() => diretorioSelecionado = v),
                    validator: (v) =>
                        v == null ? "Selecione um diretório" : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: "Parceiro",
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2)),
                    ),
                    items: parceiros
                        .map((p) => DropdownMenuItem<int>(
                              value: p.id,
                              child: Text(p.nome ?? 'Sem nome'),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setStateDialog(() => parceiroSelecionado = v),
                    validator: (v) =>
                        v == null ? "Selecione um parceiro" : null,
                  ),
                  const SizedBox(height: 12),
                  if (fileType != null)
                    Text("Tipo detectado: $fileType",
                        style: const TextStyle(color: Colors.black54)),
                  if (fileBytes != null) ...[
                    const SizedBox(height: 16),
                    const Text("Pré-visualização:",
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (fileType!.contains("jpg") ||
                        fileType!.contains("png") ||
                        fileType!.contains("jpeg"))
                      Image.memory(fileBytes!, height: 150),
                    if (fileType!.contains("pdf"))
                      SizedBox(
                        height: 200,
                        child: FutureBuilder<File>(
                          future: _writeTempFile(fileBytes!),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            return PDFView(filePath: snapshot.data!.path);
                          },
                        ),
                      ),
                    if (fileType!.contains("txt"))
                      SizedBox(
                        height: 100,
                        child: SingleChildScrollView(
                          child: Text(
                            String.fromCharCodes(fileBytes!),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar",
                    style: TextStyle(color: Colors.red))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (fileBytes == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          backgroundColor: Colors.red,
                          content:
                              Text("Selecione um arquivo antes de enviar.")),
                    );
                    return;
                  }

                  final ok = await _caller.insertFileAttachment(
                    fileBytes: fileBytes!,
                    fileName: nomeController.text,
                    fileType: fileType ?? "unknown",
                    diretorioId: diretorioSelecionado!,
                    parceiroId: parceiroSelecionado!,
                  );

                  if (ok) {
                    Navigator.pop(context);
                    _loadDiretorios();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          backgroundColor: Colors.green,
                          content: Text("Arquivo enviado com sucesso!")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          backgroundColor: Colors.red,
                          content: Text("Erro ao enviar arquivo!")),
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
            subtitle: Text(lido ? "Lido" : "Não lido",
                style: TextStyle(color: lido ? Colors.green : Colors.red)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: const Icon(Icons.download, color: Colors.green),
                    onPressed: () => _marcarComoLido(arq['id'], diretorioId)),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(arq['id'], diretorioId)),
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
            Text(nome,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(children: [
              if (naoLidos > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text("$naoLidos não lidos",
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12)),
                child: Text("$total docs",
                    style: const TextStyle(color: Colors.black, fontSize: 12)),
              ),
            ]),
          ],
        ),
        children: [
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildArquivosList(id)),
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
                  child: Text("Nenhum diretório disponível",
                      style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  itemCount: _diretorios.length,
                  itemBuilder: (context, i) =>
                      _buildDiretorioBox(_diretorios[i])),
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
                    spreadRadius: 2)
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
                    spreadRadius: 2)
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
