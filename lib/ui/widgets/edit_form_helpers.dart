import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart';

String safeToString(dynamic v) => v?.toString() ?? '';
int? safeToInt(dynamic v) =>
    v == null ? null : (v is int ? v : int.tryParse(v.toString() ?? ''));

/// ===============================================================
/// MODELOS
/// ===============================================================
class PaisModel {
  final int id;
  final String nome;

  PaisModel({required this.id, required this.nome});

  factory PaisModel.fromJson(Map<String, dynamic> j) => PaisModel(
        id: safeToInt(j['id']) ?? 0,
        nome: safeToString(j['nomePt'].isEmpty ? j['nome'] : j['nomePt']),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PaisModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

class EstadoModel {
  final int id;
  final String nome;
  final int paisId;

  EstadoModel({required this.id, required this.nome, required this.paisId});

  factory EstadoModel.fromJson(Map<String, dynamic> j) => EstadoModel(
        id: safeToInt(j['id']) ?? 0,
        nome: safeToString(j['nome']),
        paisId: safeToInt(j['paisId']) ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is EstadoModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

class CidadeModel {
  final int id;
  final String nome;
  final int estadoId;

  CidadeModel({required this.id, required this.nome, required this.estadoId});

  factory CidadeModel.fromJson(Map<String, dynamic> j) => CidadeModel(
        id: safeToInt(j['id']) ?? 0,
        nome: safeToString(j['nome']),
        estadoId: safeToInt(j['estadoId']) ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CidadeModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// ===============================================================
/// SERVICES - Fetch País / Estado / Cidade
/// ===============================================================
Future<List<PaisModel>> fetchPaises() async {
  try {
    final resp = await NetworkCaller().getRequest(ApiLinks.buscarPaises);
    if (resp.isSuccess) {
      final dynamic data = resp.body ?? {};
      final List<dynamic>? list = data is List
          ? data
          : (data is Map &&
                  (data['data']?['dados'] is List || data['dados'] is List))
              ? (data['data']?['dados'] ?? data['dados']) as List
              : null;
      if (list != null) {
        return list.map((e) => PaisModel.fromJson(e)).toList();
      }
    }
  } catch (e) {
    debugPrint('Erro buscar países: $e');
  }
  return [];
}

Future<List<EstadoModel>> fetchEstados(int paisId) async {
  try {
    final resp = await NetworkCaller()
        .getRequest(ApiLinks.buscarEstados(paisId.toString()));
    if (resp.isSuccess) {
      final dynamic data = resp.body ?? {};
      final List<dynamic>? list = data is List
          ? data
          : (data is Map &&
                  (data['data']?['dados'] is List || data['dados'] is List))
              ? (data['data']?['dados'] ?? data['dados']) as List
              : null;
      if (list != null) {
        return list.map((e) => EstadoModel.fromJson(e)).toList();
      }
    }
  } catch (e) {
    debugPrint('Erro buscar estados: $e');
  }
  return [];
}

Future<List<CidadeModel>> fetchCidades(int estadoId) async {
  try {
    final resp = await NetworkCaller()
        .getRequest(ApiLinks.buscarCidades(estadoId.toString()));
    if (resp.isSuccess) {
      final dynamic data = resp.body ?? {};
      final List<dynamic>? list = data is List
          ? data
          : (data is Map &&
                  (data['data']?['dados'] is List || data['dados'] is List))
              ? (data['data']?['dados'] ?? data['dados']) as List
              : null;
      if (list != null) {
        return list.map((e) => CidadeModel.fromJson(e)).toList();
      }
    }
  } catch (e) {
    debugPrint('Erro buscar cidades: $e');
  }
  return [];
}

/// ===============================================================
/// TEXTFIELDS
/// ===============================================================
Widget buildTextField(String label, TextEditingController c,
    {TextInputType type = TextInputType.text,
    bool required = false,
    bool readOnly = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextFormField(
      controller: c,
      readOnly: readOnly,
      keyboardType: type,
      style: const TextStyle(color: GridColors.textSecondary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: GridColors.inputBackground,
        labelStyle: const TextStyle(color: GridColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) {
        if (required && (v == null || v.isEmpty)) return 'Obrigatório';
        return null;
      },
    ),
  );
}

Widget buildTextFieldMasked(String label, TextEditingController c,
    {MaskedInputFormatter? mask,
    bool required = false,
    TextInputType type = TextInputType.text}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextFormField(
      controller: c,
      keyboardType: type,
      inputFormatters: mask != null ? [mask] : [],
      style: const TextStyle(color: GridColors.textSecondary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: GridColors.inputBackground,
        labelStyle: const TextStyle(color: GridColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) {
        if (required && (v == null || v.isEmpty)) return 'Obrigatório';
        return null;
      },
    ),
  );
}

/// ===============================================================
/// DROPDOWNS
/// ===============================================================
Widget buildDropdown<T>({
  required String label,
  required T? value,
  required List<T> items,
  required String Function(T) labelBuilder,
  required void Function(T?) onChanged,
}) {
  // evita erro de valor duplicado ou não encontrado
  final validValue = items.contains(value) ? value : null;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: DropdownButtonFormField<T>(
      value: validValue,
      isExpanded: true,
      items: items
          .map((e) =>
              DropdownMenuItem<T>(value: e, child: Text(labelBuilder(e))))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: GridColors.inputBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

Widget buildDropdownInt({
  required String label,
  required int? value,
  required List<Map<String, dynamic>> items,
  required void Function(int?) onChanged,
}) {
  final validValue = items.any((e) => e['id'] == value) ? value : null;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: DropdownButtonFormField<int>(
      value: validValue,
      isExpanded: true,
      items: items
          .map((e) => DropdownMenuItem<int>(
                value: e['id'] as int,
                child: Text(e['nome'].toString()),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: GridColors.inputBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

/// ===============================================================
/// IMAGEM
/// ===============================================================
Future<(File?, String?)> pickImageWithValidation(ImageSource src) async {
  final picker = ImagePicker();
  final XFile? file = await picker.pickImage(
      source: src, maxWidth: 800, maxHeight: 800, imageQuality: 80);
  if (file == null) return (null, null);
  final f = File(file.path);
  if (await f.length() > 2 * 1024 * 1024) return (null, 'LIMITE_EXCEDIDO');
  final bytes = await f.readAsBytes();
  return (f, base64Encode(bytes));
}

Future<void> showImageSourceDialog(
    BuildContext context, Future<void> Function(ImageSource) onPicked) async {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.red, width: 2),
      ),
      title: const Text(
        'Selecionar imagem',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'Escolha a origem da imagem:',
        style: TextStyle(color: Colors.black54, fontSize: 14),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.camera_alt, color: Colors.green),
          label: const Text(
            'Câmera',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.pop(context);
            onPicked(ImageSource.camera);
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.photo_library, color: Colors.green),
          label: const Text(
            'Galeria',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.pop(context);
            onPicked(ImageSource.gallery);
          },
        ),
      ],
    ),
  );
}

/// ===============================================================
/// IMAGEM CIRCULAR EDITÁVEL
/// ===============================================================
class EditableImageCircle extends StatelessWidget {
  final File? file;
  final String? imageUrl;
  final IconData placeholderIcon;
  final VoidCallback onTap;

  const EditableImageCircle({
    super.key,
    required this.file,
    required this.imageUrl,
    required this.placeholderIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            if (file != null)
              ClipOval(
                child: Image.file(
                  file!,
                  width: 116,
                  height: 116,
                  fit: BoxFit.cover,
                ),
              )
            else if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipOval(
                child: Image.network(
                  imageUrl!,
                  width: 116,
                  height: 116,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    placeholderIcon,
                    size: 50,
                    color: GridColors.primary,
                  ),
                ),
              )
            else
              Icon(
                placeholderIcon,
                size: 50,
                color: GridColors.primary,
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: GridColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child:
                    const Icon(Icons.camera_alt, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
