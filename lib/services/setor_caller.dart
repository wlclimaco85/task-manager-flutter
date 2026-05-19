import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';

import '../models/setor_model.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class SetorCaller {
  Future<List<Setor>> fetchAllSetores() async {
    List<Setor> list = [];
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        ApiLinks.allSetores,
      );

      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']['dados'] ?? [];
        list = (data as List).map((item) => Setor.fromJson(item)).toList();
      }
    } catch (e) {
      L.d('Erro ao carregar setores: $e');
      throw Exception('Erro ao carregar setores: $e');
    }
    return list;
  }

  Future<List<Map<String, dynamic>>> fetchSetorDropdown() async {
    final setores = await fetchAllSetores();
    return setores.map((s) => {'value': s.id, 'label': s.nome}).toList();
  }
}
