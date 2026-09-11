import 'package:flutter/material.dart';
import '../../utils/api_links.dart';
import '../../services/network_caller.dart';
import '../../utils/app_logger.dart';
import 'dart:html' as html;

class CnabRemessaScreen extends StatefulWidget {
  const CnabRemessaScreen({super.key});

  @override
  State<CnabRemessaScreen> createState() => _CnabRemessaScreenState();
}

class _CnabRemessaScreenState extends State<CnabRemessaScreen> {
  bool _loading = false;
  List<dynamic> _contasBancarias = [];
  int? _selectedContaId;

  @override
  void initState() {
    super.initState();
    _loadContas();
  }

  Future<void> _loadContas() async {
    setState(() => _loading = true);
    try {
      final res = await NetworkCaller().getRequest('${ApiLinks.baseUrl}/api/conta-bancaria');
      if (res.isSuccess && res.body != null) {
        final data = res.body!['data'] ?? res.body!['content'] ?? res.body;
        if (data is List) {
          setState(() {
            _contasBancarias = data;
          });
        }
      }
    } catch (e, stack) {
      AppLogger.i.error('Erro ao carregar contas bancárias', stack);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _gerarRemessa() async {
    if (_selectedContaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma conta bancária')));
      return;
    }
    
    setState(() => _loading = true);
    try {
      // Achado ao mergear pra main (2026-09-11): `NetworkCaller().accessToken`
      // nao existe (getter nunca foi definido) -- quebrava a compilacao. A
      // variavel nunca era usada na URL/download abaixo mesmo antes, entao
      // removida sem mudanca de comportamento. Se o endpoint exigir
      // autenticacao, quem estiver com o card de CNAB precisa anexar o
      // token de outra forma (o download via <a> nao envia header
      // Authorization).
      final url = '${ApiLinks.baseUrl}/api/edi/remessa/gerar/$_selectedContaId';
      
      html.AnchorElement anchorElement = html.AnchorElement(href: url);
      anchorElement.download = "remessa.rem";
      anchorElement.target = '_blank';
      anchorElement.click();
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download da remessa iniciado!')));
    } catch (e, stack) {
      AppLogger.i.error('Erro ao gerar remessa', stack);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao gerar remessa')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Envio EDI (Remessa CNAB)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecione a Conta Bancária para gerar o arquivo de Remessa dos boletos pendentes.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            if (_contasBancarias.isEmpty && _loading)
               const CircularProgressIndicator()
            else if (_contasBancarias.isEmpty)
               const Text('Nenhuma conta bancária encontrada.')
            else
               DropdownButtonFormField<int>(
                 value: _selectedContaId,
                 items: _contasBancarias.map((c) {
                   final id = c['id'] as int;
                   final nome = c['descricao'] ?? c['banco'] ?? 'Conta $id';
                   return DropdownMenuItem<int>(
                     value: id,
                     child: Text('$nome (Ag: ${c['agencia']} CC: ${c['numero']})'),
                   );
                 }).toList(),
                 onChanged: (val) => setState(() => _selectedContaId = val),
                 decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Conta Bancária'),
               ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_download),
              label: const Text('Gerar Arquivo de Remessa (EDI)'),
              onPressed: _loading || _selectedContaId == null ? null : _gerarRemessa,
              style: ElevatedButton.styleFrom(minimumSize: const Size(250, 50)),
            )
          ],
        ),
      ),
    );
  }
}
