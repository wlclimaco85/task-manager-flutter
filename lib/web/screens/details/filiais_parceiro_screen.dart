import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_windows_screen.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../services/custom_http_client.dart';
import '../../../utils/api_links.dart';
import 'dart:convert';

class FiliaisParceiroScreen extends StatefulWidget {
  final int matrizId;
  final int? empresaId;
  final SecurityCheck hasPermission;

  const FiliaisParceiroScreen({
    super.key,
    required this.matrizId,
    this.empresaId,
    required this.hasPermission,
  });

  @override
  State<FiliaisParceiroScreen> createState() => _FiliaisParceiroScreenState();
}

class _FiliaisParceiroScreenState extends State<FiliaisParceiroScreen> {
  final _key = GlobalKey<GenericGridWindowsScreenState>();

  void _vincularFilial() {
    String? selectedParceiroId;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Vincular Filial Existente'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Selecione um parceiro para vincular como filial:'),
                    const SizedBox(height: 16),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: DropdownHelpers.parceiros(empresaId: widget.empresaId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Text('Erro ao carregar parceiros');
                        }
                        final options = snapshot.data!
                            .where((p) => p['id']?.toString() != widget.matrizId.toString())
                            .toList();
                        
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          value: selectedParceiroId,
                          items: options.map((e) => DropdownMenuItem(
                            value: e['id']?.toString(),
                            child: Text(e['nome']?.toString() ?? e['razaoSocial']?.toString() ?? ''),
                          )).toList(),
                          onChanged: (val) {
                            setState(() => selectedParceiroId = val);
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            }
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedParceiroId == null) return;
                
                try {
                  final getResp = await customHttpClient.get(Uri.parse('\/'));
                  if (getResp.statusCode == 200) {
                    final data = jsonDecode(utf8.decode(getResp.bodyBytes));
                    data['matriz'] = {'id': widget.matrizId};
                    
                    final putResp = await customHttpClient.put(
                      Uri.parse('\/'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(data),
                    );
                    
                    if (putResp.statusCode == 200 || putResp.statusCode == 201) {
                      if (mounted) Navigator.of(ctx).pop();
                      _key.currentState?.refreshData();
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao vincular filial.')));
                      }
                    }
                  }
                } catch (e) {
                   if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ')));
                   }
                }
              },
              child: const Text('Vincular'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GenericGridWindowsScreen(
      key: _key,
      telaNome: 'parceiro',
      hasPermission: widget.hasPermission,
      extraParams: {'matrizId': widget.matrizId, if (widget.empresaId != null) 'empresaId': widget.empresaId},
      hideAddButton: true,
      headerActions: [
        ElevatedButton.icon(
          onPressed: _vincularFilial,
          icon: const Icon(Icons.add_link),
          label: const Text('Vincular Filial Existente'),
        ),
      ],
      showAppBar: false,
    );
  }
}
