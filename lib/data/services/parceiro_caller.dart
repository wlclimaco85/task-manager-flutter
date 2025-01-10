import 'dart:convert';
import 'package:flutter/material.dart'; // Necessário para BuildContext e showDialog
import 'package:task_manager_flutter/data/models/parceiro_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/ui/screens/LoginPopup_screens.dart';

class ParceiroCaller {
  Future<List<Parceiro>> fetchParceiros(
      BuildContext context, int idParceiro) async {
    List<Parceiro>? model = [];
    ParceiroModel models;
    try {
      if (AuthUtility.userInfo?.data?.id != null &&
          AuthUtility.userInfo?.data?.id == 1) {
        // AQUI CHAMAR O LOGIN
        await showDialog(
          context: context,
          builder: (BuildContext context) => LoginPopup(),
        );
      } else {
        final NetworkResponse response = await NetworkCaller()
            .getRequest('${ApiLinks.parceiroById}/$idParceiro');
        String jsonString;

        if (response.statusCode == 200 && response.body != null) {
          jsonString = json.encode(response.body);
          models = ParceiroModel.fromJson(response.body!);
          model.addAll(models.parceiros ?? []);
        } else {
          // Trate o caso onde o data é nulo
        }
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }
}
