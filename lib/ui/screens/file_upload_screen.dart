import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:task_manager_flutter/data/utils/utils.dart';
import 'package:task_manager_flutter/data/services/file_caller.dart';
import 'package:task_manager_flutter/data/services/diretorio_caller.dart';
import 'package:task_manager_flutter/data/services/parceiro_caller.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';

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

  /// controla quais diretórios estão abertos
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
    _showSnackBar(
        "Arquivo marcado como lido.", GridColors.success, Icons.check_circle);
  }

  void _confirmDelete(int id, int dirId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GridColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: GridColors.primary, width: 2),
        ),
        title: const Text("Excluir Documento",
            style: TextStyle(
                color: GridColors.primary, fontWeight: FontWeight.bold)),
        content: const Text("Deseja realmente excluir este documento?",
            style: TextStyle(color: GridColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar",
                style: TextStyle(color: GridColors.secondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _caller.deleteArquivo(id);
              _loadArquivos(dirId);
              _showSnackBar("Arquivo excluído com sucesso!", GridColors.success,
                  Icons.delete_forever);
            },
            child: const Text("Excluir",
                style: TextStyle(color: GridColors.error)),
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
          backgroundColor: GridColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: GridColors.primary, width: 2),
          ),
          title: const Text(
            "Enviar Arquivo",
            style: TextStyle(
              color: GridColors.secondary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.attach_file,
                        color: GridColors.secondary),
                    label: const Text("Selecionar Arquivo",
                        style: TextStyle(color: GridColors.secondary)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: GridColors.primary)),
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
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: "Nome do Arquivo",
                      labelStyle: TextStyle(color: GridColors.textSecondary),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: GridColors.primary)),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: GridColors.primary, width: 2)),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Informe o nome" : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: "Diretório",
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: GridColors.primary)),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: GridColors.primary, width: 2)),
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
                          borderSide: BorderSide(color: GridColors.primary)),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: GridColors.primary, width: 2)),
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
                    Text("Tipo: $fileType",
                        style: const TextStyle(color: GridColors.primaryLight)),
                  if (fileBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: fileType!.contains("pdf")
                            ? SizedBox(
                                height: 200,
                                child: FutureBuilder<File>(
                                  future: _writeTempFile(fileBytes!),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Center(
                                          child: CircularProgressIndicator(
                                              color: GridColors.secondary));
                                    }
                                    return PDFView(
                                        filePath: snapshot.data!.path);
                                  },
                                ),
                              )
                            : (fileType!.contains("jpg") ||
                                    fileType!.contains("png"))
                                ? Image.memory(fileBytes!, height: 150)
                                : const SizedBox.shrink(),
                      ),
                    ),
                  if (fileType?.contains("txt") ?? false)
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
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar",
                  style: TextStyle(color: GridColors.error)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload, color: GridColors.textPrimary),
              label: const Text("Enviar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.success,
                foregroundColor: GridColors.textPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (fileBytes == null) {
                    _showSnackBar("Selecione um arquivo antes de enviar.",
                        GridColors.warning, Icons.warning_amber);
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
                    _showSnackBar("Arquivo enviado com sucesso!",
                        GridColors.success, Icons.check_circle);
                  } else {
                    _showSnackBar("Erro ao enviar arquivo!", GridColors.error,
                        Icons.error);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(icon, color: GridColors.textPrimary),
            const SizedBox(width: 8),
            Text(msg, style: const TextStyle(color: GridColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildDiretorioBox(Map<String, dynamic> dir) {
    final id = dir['id'];
    final nome = dir['nome'] ?? 'Sem nome';
    final total = dir['totalArquivos'] ?? 0;
    final naoLidos = dir['naoLidos'] ?? 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: GridColors.shadow, blurRadius: 6, offset: Offset(0, 2))
        ],
        border: Border.all(color: GridColors.primary, width: 1.5),
      ),
      child: ExpansionTile(
        key: PageStorageKey<int>(id),
        initiallyExpanded: _expandedTiles.contains(id),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedTiles.clear(); // accordion: fecha outros
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
            Row(
              children: [
                const Icon(Icons.folder, color: GridColors.secondary),
                const SizedBox(width: 8),
                Text(nome,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: GridColors.textSecondary)),
              ],
            ),
            Row(
              children: [
                if (naoLidos > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: GridColors.error,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text("$naoLidos não lidos",
                        style: const TextStyle(
                            color: GridColors.textPrimary, fontSize: 12)),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: GridColors.warning,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text("$total docs",
                      style: const TextStyle(
                          color: GridColors.textSecondary, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: _buildArquivosList(id),
          ),
        ],
      ),
    );
  }

  Widget _buildArquivosList(int diretorioId) {
    final arquivos = _arquivos[diretorioId] ?? [];
    if (arquivos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text("Nenhum arquivo disponível",
            style: TextStyle(color: GridColors.textSecondary)),
      );
    }
    return Column(
      children: arquivos.map((arq) {
        final lido = arq['lido'] == true;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: GridColors.card,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: GridColors.shadow, blurRadius: 4)
            ],
          ),
          child: ListTile(
            leading: Icon(
              lido ? Icons.check_circle : Icons.description,
              color: lido ? GridColors.success : GridColors.primary,
            ),
            title: Text(arq['nome'] ?? "Sem nome",
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(lido ? "Lido" : "Não lido",
                style: TextStyle(
                    color: lido ? GridColors.success : GridColors.error)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon:
                        const Icon(Icons.download, color: GridColors.secondary),
                    onPressed: () => _marcarComoLido(arq['id'], diretorioId)),
                IconButton(
                    icon: const Icon(Icons.delete, color: GridColors.error),
                    onPressed: () => _confirmDelete(arq['id'], diretorioId)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: UserBannerAppBar(
        screenTitle: "Gerenciador de Arquivos",
        isLoading: _isLoading,
        showFilterButton: false,
        onRefresh: _loadDiretorios,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: GridColors.secondary))
          : _diretorios.isEmpty
              ? const Center(
                  child: Text("Nenhum diretório disponível",
                      style: TextStyle(color: GridColors.textPrimary)))
              : ListView.builder(
                  itemCount: _diretorios.length,
                  itemBuilder: (context, i) =>
                      _buildDiretorioBox(_diretorios[i]),
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildFAB(
              Icons.refresh, GridColors.secondary, _loadDiretorios, "refresh"),
          const SizedBox(height: 10),
          _buildFAB(Icons.add, GridColors.secondary, _showUploadDialog, "add"),
        ],
      ),
    );
  }

  Widget _buildFAB(
      IconData icon, Color color, VoidCallback onPressed, String tag) {
    return Container(
      decoration: BoxDecoration(
        color: GridColors.card,
        border: Border.all(color: GridColors.primary, width: 2),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: GridColors.shadow, blurRadius: 8, spreadRadius: 2)
        ],
      ),
      child: FloatingActionButton(
        heroTag: tag,
        backgroundColor: GridColors.card,
        foregroundColor: color,
        elevation: 0,
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }
}
