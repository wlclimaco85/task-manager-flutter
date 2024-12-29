import 'dart:convert';
import 'package:task_manager_flutter/data/models/venda_model.dart';
import 'package:task_manager_flutter/data/models/negotiation_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';

class VendasCaller {
  Future<List<Produto>> fetchCotacoes() async {
    List<Produto>? model = [];
    ProdutoModel models;
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.allVendas);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = ProdutoModel.fromJson(response.body!);
        model.addAll(models.produtos ?? []);

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

  Future<List<Product>> fetchItensAVenda() async {
    List<Product>? model = [];
    ProductModel models;
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.fecthItensAVenda + "4");
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = ProductModel.fromJson(response.body!);
        model.addAll(models.produtos ?? []);

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

  Future<List<Account>> fetchClassificacao() async {
    List<Account>? model = [];
    ClassificacaoResponse models;
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.allClassificacao);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = ClassificacaoResponse.fromJson(response.body!);
        model.addAll(models.data ?? []);

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
