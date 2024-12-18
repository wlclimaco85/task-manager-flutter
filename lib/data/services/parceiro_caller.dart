import 'dart:convert';
import 'dart:ffi';
import 'package:task_manager_flutter/data/models/parceiro_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';

class ParceiroCaller {
  Future<List<Parceiro>> fetchParceiros(int idParceiro) async {
    List<Parceiro>? model = [];
    ParceiroModel models;
    try {
      final NetworkResponse response = await NetworkCaller()
          .getRequest('${ApiLinks.parceiroById}/$idParceiro');
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = ParceiroModel.fromJson(response.body!);
        model.addAll(models.parceiros ?? []);

        // if (model != null && model.data != null) {
        //   newsList.addAll(model.data!);
        // }
        // Use jsonString conforme necessário
      } else {
        // Trate o caso onde o data é nulo
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }
}
