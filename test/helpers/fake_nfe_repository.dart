import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/repositories/nfe_repository.dart';

/// Repositorio falso para testes de NFe: cada teste define a resposta desejada
/// e confere os argumentos recebidos. Nao depende de codigo gerado pelo mockito.
class FakeNfeRepository implements NfeRepository {
  List<NfeModel> nfesParaListar = [];
  Object? erroAoListar;
  NfeModel? nfeParaObter;
  Object? erroAoObter;
  NfeModel? nfeParaCriar;
  Object? erroAoCriar;

  int chamadasListar = 0;
  int? ultimaPaginaListada;
  String? ultimoStatus;
  String? ultimoCnpj;
  Map<String, dynamic>? ultimosDadosCriados;

  @override
  Future<List<NfeModel>> listarNfe({
    required int page,
    required int pageSize,
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? clienteCnpj,
  }) async {
    chamadasListar++;
    ultimaPaginaListada = page;
    ultimoStatus = status;
    ultimoCnpj = clienteCnpj;
    if (erroAoListar != null) throw erroAoListar!;
    return nfesParaListar;
  }

  @override
  Future<NfeModel> obterNfe(int id) async {
    if (erroAoObter != null) throw erroAoObter!;
    return nfeParaObter!;
  }

  @override
  Future<NfeModel> criarNfe(Map<String, dynamic> dados) async {
    ultimosDadosCriados = dados;
    if (erroAoCriar != null) throw erroAoCriar!;
    return nfeParaCriar!;
  }

  @override
  Future<String> downloadXml(int id) => throw UnimplementedError();

  @override
  Future<List<int>> downloadPdf(int id) => throw UnimplementedError();
}
