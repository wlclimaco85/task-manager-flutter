import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/venda_model.dart';
import 'package:task_manager_flutter/data/models/negotiation_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/ui/screens/LoginPopup_screens.dart';

class VendasCaller {
  Future<List<Produto>> fetchCotacoes(BuildContext context) async {
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
      } else {
        print('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }

  Future<List<Product>> fetchItensAVenda(BuildContext context) async {
    List<Product>? model = [];
    ProductModel models;
    try {
      final NetworkResponse response = await NetworkCaller().getRequests(
          ApiLinks.fecthItensAVenda + '${AuthUtility.userInfo?.data?.id}',
          context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = ProductModel.fromJson(response.body!);
        model.addAll(models.produtos ?? []);
      } else {
        print('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar itens à venda: $e');
    }
    return model;
  }

  Future<List<Product>> fetchItensACompra(BuildContext context) async {
    List<Product>? model = [];
    ProductModel models;
    try {
      if (AuthUtility.userInfo?.data?.id == 1) {
        // AQUI CHAMAR O LOGIN
        await showDialog(
          context: context,
          builder: (BuildContext context) => LoginPopup(),
        );
      } else {
        final NetworkResponse response = await NetworkCaller().getRequests(
            ApiLinks.fecthItensACompra + '${AuthUtility.userInfo?.data?.id}',
            context);
        String jsonString;

        if (response.statusCode == 200 && response.body != null) {
          jsonString = json.encode(response.body);
          models = ProductModel.fromJson(response.body!);
          model.addAll(models.produtos ?? []);
        } else if (response.statusCode == 403) {
          // Mova o código que depende do BuildContext para este método.
          if (AuthUtility.userInfo == null) {
            // AQUI CHAMAR O LOGIN
            await showDialog(
              context: context,
              builder: (BuildContext context) => LoginPopup(),
            );
          }
        } else {
          print('Erro: Nenhum dado retornado');
        }
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar itens à compra: $e');
    }
    return model;
  }

  Future<List<Product>> fetchItensANegocias(BuildContext context) async {
    List<Product>? model = [];
    ProductModel models;
    try {
      final NetworkResponse response = await NetworkCaller().getRequests(
          ApiLinks.fecthItensANegociar + '${AuthUtility.userInfo?.data?.id}',
          context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = ProductModel.fromJson(response.body!);
        model.addAll(models.produtos ?? []);
      } else {
        print('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar itens a negociar: $e');
    }
    return model;
  }

  Future<List<Account>> fetchClassificacao(BuildContext context) async {
    List<Account>? model = [];
    ClassificacaoResponse models;
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequests(ApiLinks.allClassificacao, context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = ClassificacaoResponse.fromJson(response.body!);
        model.addAll(models.data ?? []);
      } else {
        print('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      print('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar classificações: $e');
    }
    return model;
  }
}
