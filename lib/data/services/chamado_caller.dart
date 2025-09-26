import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../models/chamado_model.dart';

class ChamadoCaller {
  Future<List<Chamado>> fetchAllChamados() async {
    List<Chamado> list = [];
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        ApiLinks.allChamados,
      );

      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']['dados'] ?? [];
        list = (data as List).map((item) => Chamado.fromJson(item)).toList();
      }
    } catch (e) {
      print('Erro ao carregar chamados: $e');
      throw Exception('Erro ao carregar chamados: $e');
    }
    return list;
  }

  Future<List<Map<String, dynamic>>> fetchChamadoDropdown() async {
    final chamados = await fetchAllChamados();
    return chamados.map((c) => {'value': c.id, 'label': c.titulo}).toList();
  }
}
