class ApiLinks {
  ApiLinks._();
  static const String _baseIp =
      "https://appacademia-production-be7e.up.railway.app";
  //static const String _chatId = 'ws://192.168.114.1:8088/boletobancos';

  static const String _chatId =
      "wss://appacademia-production-be7e.up.railway.app/boletobancos";
  // "http://192.168.100.41:8088";
  //  "http://192.168.114.1:8088";
  // "http://192.168.100.113:8088";
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
  static String allComunicados = '$_baseUrlNew/api/comunicados';
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
  static String fecthChats = '$_baseUrlNew/api/chat/user';
  static String fecthChatById = '$_baseUrlNew/api/chat/messages?chatId=';

  // Suplemento
  static String allAplicativos = '$_baseUrlNew/api/aplicativos';
  static String createAplicativo = '$_baseUrlNew/api/aplicativos';
  static String updateAplicativo(String id) =>
      '$_baseUrlNew/api/aplicativos/update/$id';
  static String deleteAplicativo(String id) =>
      '$_baseUrlNew/api/aplicativos/delete/$id';

  // Regime
  static String allRegimetributario = '$_baseUrlNew/api/regimetributario';
  static String createRegimetributario = '$_baseUrlNew/api/regimetributario';
  static String updateRegimetributario(String id) =>
      '$_baseUrlNew/api/regimetributario/update/$id';
  static String deleteRegimetributario(String id) =>
      '$_baseUrlNew/api/regimetributario/delete/$id';

  // Add these endpoints to your ApiLinks class
  static String get allLogins => '$_baseUrlNew/api/logins';
  static String get createLogin => '$_baseUrlNew/api/logins';
  static String updateLogin(String id) => '$_baseUrlNew/api/logins/$id';
  static String deleteLogin(String id) => '$_baseUrlNew/api/logins/$id';

  // Contas a Pagar
  static String get allContasPagar => '$_baseUrlNew/api/contas-pagar';
  static String get createContaPagar => '$_baseUrlNew/api/contas-pagar';
  static String updateContaPagar(String id) =>
      '$_baseUrlNew/api/contas-pagar/$id';
  static String deleteContaPagar(String id) =>
      '$_baseUrlNew/api/contas-pagar/$id';
  static String registrarBaixaContaPagar(String id) =>
      '$_baseUrlNew/api/contas-pagar/$id/baixa';

  // Contas a Receber
  static String get allContasReceber => '$_baseUrlNew/api/contas-receber';
  static String get createContaReceber => '$_baseUrlNew/api/contas-receber';
  static String updateContaReceber(String id) =>
      '$_baseUrlNew/api/contas-receber/$id';
  static String deleteContaReceber(String id) =>
      '$_baseUrlNew/api/contas-receber/$id';
  static String registrarBaixaContaReceber(String id) =>
      '$_baseUrlNew/api/contas-receber/$id/baixa';

  // Chamados
  static String get allChamados => '$_baseUrlNew/api/chamados';
  static String get createChamado => '$_baseUrlNew/api/chamados';
  static String updateChamado(String id) => '$_baseUrlNew/api/chamados/$id';
  static String deleteChamado(String id) => '$_baseUrlNew/api/chamados/$id';
  static String updateStatusChamado(String id) =>
      '$_baseUrlNew/api/chamados/$id/status';

  // Formas de Pagamento
  static String get allFormasPagamento => '$_baseUrlNew/api/forma-pagamento';
  static String get createFormaPagamento => '$_baseUrlNew/api/forma-pagamento';
  static String updateFormaPagamento(String id) =>
      '$_baseUrlNew/api/forma-pagamento/$id';
  static String deleteFormaPagamento(String id) =>
      '$_baseUrlNew/api/forma-pagamento/$id';
  static String formasPagamentoByEmpresa(String empresaId) =>
      '$_baseUrlNew/api/forma-pagamento/empresa/$empresaId';

  // Diretórios
  static String get allDiretorios => '$_baseUrlNew/api/diretorios';
  static String get createDiretorio => '$_baseUrlNew/api/diretorios';
  static String updateDiretorio(String id) => '$_baseUrlNew/api/diretorios/$id';
  static String deleteDiretorio(String id) => '$_baseUrlNew/api/diretorios/$id';

  // Arquivos
  static String get allArquivos => '$_baseUrlNew/api/arquivos';
  static String get createArquivo => '$_baseUrlNew/api/arquivos';
  static String updateArquivo(String id) => '$_baseUrlNew/api/arquivos/$id';
  static String deleteArquivo(String id) => '$_baseUrlNew/api/arquivos/$id';
  static String get uploadArquivo => '$_baseUrlNew/api/arquivos/upload';
  static String downloadArquivo(String id) =>
      '$_baseUrlNew/api/arquivos/download/$id';
  static String arquivosPorDiretorio(String diretorioId) =>
      '$_baseUrlNew/api/arquivos/diretorio/$diretorioId';

  static String get fecthAllDocumentos => '$_baseUrlNew/api/documentos';

  static String get fecthAllAlerts => '$_baseUrlNew/api/alert';

  static String get fecthAUpload => '$_baseUrlNew/api/files/upload';

  // Arquivos
  static String get allObrigacaoFiscal => '$_baseUrlNew/api/obrigacoes-fiscais';
  static String get createObrigacaoFiscal =>
      '$_baseUrlNew/api/obrigacoes-fiscais';
  static String updateObrigacaoFiscal(String id) =>
      '$_baseUrlNew/api/obrigacoes-fiscais/$id';
  static String deleteObrigacaoFiscal(String id) =>
      '$_baseUrlNew/api/obrigacoes-fiscais/$id';

  // Setor
  static String allSetores = '$_baseUrlNew/api/setor';
  static String createSetor = '$_baseUrlNew/api/setor';
  static String updateSetor(String id) => '$_baseUrlNew/api/setor/update/$id';
  static String deleteSetor(String id) => '$_baseUrlNew/api/setor/delete/$id';

  static String chatStart(String id, String setor) =>
      '$_chatId/ws-chat?user=$id&sector=$setor';

  //   'ws://192.168.114.1:8088/boletobancos/ws-chat?user=${widget.userName}&sector=${widget.sector}',
}
