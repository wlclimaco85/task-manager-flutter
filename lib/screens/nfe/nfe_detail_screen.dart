import 'package:flutter/material.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/web/screens/details/nfe_detail_screen.dart';

class NfeDetailScreen extends StatelessWidget {
  final NfeModel nfe;

  const NfeDetailScreen({super.key, required this.nfe});

  @override
  Widget build(BuildContext context) {
    return NfeSankhyaDetailScreen(item: {
      'id': nfe.id,
      'empresa': {'id': nfe.empresaId},
      'numero': nfe.numero,
      'serie': nfe.serie,
      'status': nfe.statusNfe.code,
      'ambiente': nfe.ambiente,
      'tipoOperacao': 'SAIDA',
      'chave': nfe.xmlNfeAssinado,
      'destinatario': {
        'cnpjCpf': nfe.tomador.cnpjCpf,
        'nome': nfe.tomador.razaoSocial,
        'razaoSocial': nfe.tomador.razaoSocial,
      },
      'valorTotal': nfe.valores.total,
      'dataHora': nfe.dataHora.toIso8601String(),
    });
  }
}
