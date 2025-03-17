class ApiLinks {
  ApiLinks._();
  static const String _baseIp =
      // "https://appacademia-production-be7e.up.railway.app";

      //  "http://192.168.100.41:8088";
      "http://192.168.100.113:8088";
  //  "http://192.168.146.1:8088";
  // // "http://192.168.100.41:8088";
  // "http://192.168.100.41:8088"; // "http://192.168.12.19:8088"; //
  //'https://academia-app-919f42758cd6.herokuapp.com'; // "http://192.168.12.28:8088";
  // "http://192.168.12.23:8088"; // "http://192.168.56.1:8088"; // ; // //"http://192.168.12.23:8088";
  //static const String _baseIp = "http://192.168.56.1:8088"; //"http://192.168.12.23:8088";
  static const String _baseUrl = 'https://task.teamrabbil.com/api/v1';
  static const String _baseUrlNew = '$_baseIp/boletobancos';
  //static const String _baseUrlNew =
  //    'https://academia-app-919f42758cd6.herokuapp.com/boletobancos';
  static const String allPersonal = '$_baseUrlNew/personal/findAll';
  static const String allAcademia = '$_baseUrlNew/academia/findAll';
  static const String allModalidade = '$_baseUrlNew/modalidade/findAll';
  static const String allTipoRefeicao = '$_baseUrlNew/dieta/findByRefeicao';
  static const String allUniMeds = '$_baseUrlNew/unidade/findAll';
  static const String insertPersonal = '$_baseUrlNew/personal/inserir';
  static const String insertSuplemento = '$_baseUrlNew/suplemento/insert';
  static const String insertAcademia = '$_baseUrlNew/academia/inserir';
  static const String allSuplementoAluno =
      '$_baseUrlNew/suplemento/findByIdAluno';
  static const String insertAluno = '$_baseUrlNew/rest/auth/inserirAluno';
  static String regestration = '$_baseUrl/registration';
  static String profileUpdate = '$_baseUrl/profileUpdate';
  static const String insertExame = '$_baseUrlNew/exame/inserir';
  static const String findByIdAluno = '$_baseUrlNew/exame/findByParceiros';
  static const String insertMedicamento = '$_baseUrlNew/medicamento/inserir';
  static const String findByAlunoByMedicamento =
      '$_baseUrlNew/medicamento/findByParceiros';
  static const String findByAlunoByDieta = '$_baseUrlNew/dieta/findByParceiros';
  // static String login = '$_baseUrl/login';
  // static String login = '$_baseUrl/rest/auth/login';

  // static String login = 'http://192.168.56.1:8088/boletobancos/rest/auth/login';
  static String login = '$_baseUrlNew/rest/auth/login';
  static String recoverVerifyEmail(String email) =>
      '$_baseUrl/RecoverVerifyEmail/$email';
  static String recoverVerifyOTP(String email, String otp) =>
      '$_baseUrl/RecoverVerifyOTP/$email/$otp';
  static String recoverResetPassword = '$_baseUrl/RecoverResetPass';

  static String createTask = '$_baseUrl/createTask';
  static String newTaskStatus = '$_baseUrl/listTaskByStatus/New';

  static String completedTaskStatus = '$_baseUrl/listTaskByStatus/Completed';
  static String inProgressTaskStatus = '$_baseUrl/listTaskByStatus/Progress';
  static String cancelledTaskStatus = '$_baseUrl/listTaskByStatus/Canceled';
  static String updateTask(String id, String status) =>
      '$_baseUrl/updateTaskStatus/$id/$status';
  static String taskStatusCount = '$_baseUrl/listTaskByStatus/taskStatusCount';
  static String deleteTask(String taskId) => '$_baseUrl/deleteTask/$taskId';
  static String allNoticias = '$_baseUrlNew/api/noticias';
  static String allCotacoes = '$_baseUrlNew/api/cotacoes';
  static String allVendas = '$_baseUrlNew/api/produtos';
  static String insertNegociacao = '$_baseUrlNew/api/negociacao';
  static String allClassificacao = '$_baseUrlNew/api/classificacoes';
  static String parceiroById = '$_baseUrlNew/api/parceiro/parceiro';
  static String insertProduto = '$_baseUrlNew/api/produtos';
  static String fecthItensAVenda = '$_baseUrlNew/api/produtos/vendedor/';
  static String fecthItensACompra = '$_baseUrlNew/api/produtos/comprador/';
  static String fecthItensANegociar = '$_baseUrlNew/api/produtos/negociacoes/';
  static String insertCotacaoFrete = '$_baseUrlNew/api/cotacaofrete';
  static String allAlerts = '$_baseUrlNew/api/alert';
  static String alertFindByUser = '$_baseUrlNew/api/alert/byUser/';
  static String compradorFindByUser = '$_baseUrlNew/api/produtos/comprador/';
  static String vendedorFindByUser = '$_baseUrlNew/api/produtos/vendedor/';
  static String negociacaoFindByUser = '$_baseUrlNew/produtos/negociacoes/';
  static String insertParceiro = '$_baseUrlNew/api/parceiro/insert';
  static String updateParceiro = '$_baseUrlNew/api/parceiro/update';
  static String fecthAllCotacaoDollar = '$_baseUrlNew/api/cotacoes/dollar';
  static String confirmarNegociacao = '$_baseUrlNew/api/negociacao/finalizar';
  static String confirmarRecusar = '$_baseUrlNew/api/negociacao/recusar';
  static String contraProposta = '$_baseUrlNew/api/negociacao/contraposta';
  static String downloadContrato = '$_baseUrlNew/api/contrato/download';
  static String upLoadContrato = '$_baseUrlNew/api/contrato/upload';
  static String fecthUltimoTermo = '$_baseUrlNew/api/termos';
  static String fecthProdutosById = '$_baseUrlNew/api/produtos/';
  static String fecthAllPaises = '$_baseUrlNew/api/paises';
  static String fecthEstadoByPais = '$_baseUrlNew/api/estados/by-pais/';
  static String fecthCidadeByEstado = '$_baseUrlNew/api/cidade/by-estado/';
  static String fecthCalcFrete = '$_baseUrlNew/api/rota/calcular';
}
