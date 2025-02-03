import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/parceiro_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/ui/screens/LoginPopup_screens.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';

class CheckoutCaller {
  static final Dio _dio = Dio();

  static Future<String> carregarTermos() async {
    String jsonString = "";
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.fecthUltimoTermo);

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body?['texto']);
      } else {
        // Trate o caso onde o data é nulo
      }
    } catch (e) {
      return "Erro de conexão: ${e.toString()}";
    }
    return jsonString;
  }

  static Future<String> downloadContract() async {
    final url = 'https://seuservidor.com/api/contract.pdf';
    final response = await Dio().download(url, 'contrato.pdf');
    print('Contrato baixado: ${response.data}');

    return 'Contrato baixado com sucesso!';
  }

  void _uploadContract2() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });
      final response = await Dio()
          .post('https://seuservidor.com/api/upload', data: formData);
      print('Contrato enviado: ${response.data}');
    }
  }

  static Future<void> uploadContract() async {
    try {
      // Abre o seletor de arquivos
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        // Obtém o arquivo selecionado
        PlatformFile file = result.files.first;
        File uploadedFile = File(file.path!);

        // Exibe o nome do arquivo selecionado
        print('Arquivo selecionado: ${file.name}');

        // Envia o arquivo para o backend
        final dio = Dio();
        final url =
            'https://seuservidor.com/api/upload'; // Substitua pelo seu endpoint

        FormData formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(uploadedFile.path,
              filename: file.name),
        });

        final response = await dio.post(url, data: formData);

        if (response.statusCode == 200) {
          print('Contrato enviado com sucesso!');
        } else {
          print('Erro ao enviar o contrato: ${response.statusCode}');
        }
      } else {
        print('Nenhum arquivo selecionado.');
      }
    } catch (e) {
      print('Erro ao selecionar o arquivo: $e');
    }
  }

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

  Future<bool> insertParceiro(
      BuildContext context, Map<String, dynamic> parceiroData) async {
    try {
      final NetworkResponse response = await NetworkCaller().postRequest(
        '${ApiLinks.insertParceiro}',
        parceiroData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Analisar o JSON retornado para verificar se contém erros
        final Map<String, dynamic> responseBody =
            response.body as Map<String, dynamic>;
        final responseError = responseBody['response']['error'] as bool?;
        final responseMessage = responseBody['response']['message'];
        String sanitizedMessage = responseMessage != null
            ? utf8.decode(responseMessage.runes.toList())
            : "Erro desconhecido.";

        if (responseError == true) {
          // Mostra a mensagem de erro do servidor
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sanitizedMessage),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }

        print("Parceiro inserido com sucesso.");
        return true;
      } else {
        print("Erro ao inserir parceiro: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao inserir parceiro: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      print('Erro ao inserir parceiro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao inserir parceiro: $e"),
          backgroundColor: Colors.red,
        ),
      );
      throw Exception('Erro ao inserir parceiro: $e');
    }
  }

  Future<bool> updateParceiro(
      BuildContext context, Map<String, dynamic> parceiroData) async {
    try {
      final NetworkResponse response = await NetworkCaller().postRequest(
        '${ApiLinks.updateParceiro}',
        parceiroData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Analisar o JSON retornado para verificar se contém erros
        final Map<String, dynamic> responseBody =
            response.body as Map<String, dynamic>;
        final responseError = responseBody['response']['error'] as bool?;
        final responseMessage = responseBody['response']['message'];
        String sanitizedMessage = responseMessage != null
            ? utf8.decode(responseMessage.runes.toList())
            : "Erro desconhecido.";

        if (responseError == true) {
          // Mostra a mensagem de erro do servidor
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sanitizedMessage),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sanitizedMessage),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        print("Erro ao inserir parceiro: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao inserir parceiro: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      print('Erro ao inserir parceiro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao inserir parceiro: $e"),
          backgroundColor: Colors.red,
        ),
      );
      throw Exception('Erro ao inserir parceiro: $e');
    }
  }
}
