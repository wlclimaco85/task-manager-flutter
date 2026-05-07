class ApiLinks {
  ApiLinks._();
  

  // URL do backend
  // Dev local: flutter run (usa default localhost)
  // Producao Railway: flutter run --dart-define=BACKEND_URL=https://appacademia-production-be7e.up.railway.app
  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8088',
  );

  static const String _baseIp = _backendUrl;

  // WebSocket: converte http→ws e https→wss
  static String get _wsUrl => _backendUrl
      .replaceFirst('https://', 'wss://')
      .replaceFirst('http://', 'ws://');

  static String get _chatId => '$_wsUrl/boletobancos';
  //  "wss://appacademia-production-be7e.up.railway.app/boletobancos";
  //    "http://192.168.100.41:8088";
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
  static String get noticiasPublicas => '$_baseUrlNew/api/noticias/public/recentes';
  static String get createNoticia => '$_baseUrlNew/api/noticias';
  static String updateNoticia(String id) => '$_baseUrlNew/api/noticias/$id';
  static String deleteNoticia(String id) => '$_baseUrlNew/api/noticias/$id';
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
  static String getCategorias = '$_baseUrlNew/api/setor';

  // Comunicado
  static String allComunicados = '$_baseUrlNew/api/comunicado';
  static String createComunicado = '$_baseUrlNew/api/comunicado';
  static String updateComunicado(String taskId) =>
      '$_baseUrlNew/api/comunicado/$taskId';
  static String deleteComunicado(String taskId) =>
      '$_baseUrlNew/api/comunicado/$taskId';

  // Alimento
  static String allAlimentos = '$_baseUrlNew/api/alimentos';
  static String createAlimento = '$_baseUrlNew/api/alimentos/insert';
  static String updateAlimento(String id) =>
      '$_baseUrlNew/api/alimentos/update/$id';
  static String deleteAlimento(String id) =>
      '$_baseUrlNew/api/alimentos/delete/$id';

  // Dieta
  static String allDietas = '$_baseUrlNew/api/dietas';
  static String createDieta = '$_baseUrlNew/api/dietas/insert';
  static String updateDieta(String id) => '$_baseUrlNew/api/dietas/update/$id';
  static String deleteDieta(String id) => '$_baseUrlNew/api/dietas/delete/$id';

  // Empresa
  static String allEmpresas = '$_baseUrlNew/api/empresa';
  static String createEmpresa = '$_baseUrlNew/api/empresa/insert';
  static String updateEmpresa(String id) =>
      '$_baseUrlNew/api/empresa/update/$id';
  static String deleteEmpresa(String id) =>
      '$_baseUrlNew/api/empresa/delete/$id';
  static String empresaById(String id) => '$_baseUrlNew/api/empresa/$id';
  static String atualizarDadosPessoais(dynamic id) =>
      '$_baseUrlNew/api/dadospessoais/$id';

  // Exame
  static String allExames = '$_baseUrlNew/api/exames';
  static String createExame = '$_baseUrlNew/api/exames/insert';
  static String updateExame(String id) => '$_baseUrlNew/api/exames/update/$id';
  static String deleteExame(String id) => '$_baseUrlNew/api/exames/delete/$id';

  // Exercicio
  static String allExercicios = '$_baseUrlNew/api/exercicios';
  static String createExercicio = '$_baseUrlNew/api/exercicios/insert';
  static String updateExercicio(String id) =>
      '$_baseUrlNew/api/exercicios/update/$id';
  static String deleteExercicio(String id) =>
      '$_baseUrlNew/api/exercicios/delete/$id';

  // Grupo Muscular
  static String allGruposMusculares = '$_baseUrlNew/api/grupos-musculares';
  static String createGrupoMuscular =
      '$_baseUrlNew/api/grupos-musculares/insert';
  static String updateGrupoMuscular(String id) =>
      '$_baseUrlNew/api/grupos-musculares/update/$id';
  static String deleteGrupoMuscular(String id) =>
      '$_baseUrlNew/api/grupos-musculares/delete/$id';

  // Medicamento
  static String allMedicamentos = '$_baseUrlNew/api/medicamentos';
  static String createMedicamento = '$_baseUrlNew/api/medicamentos/insert';
  static String updateMedicamento(String id) =>
      '$_baseUrlNew/api/medicamentos/update/$id';
  static String deleteMedicamento(String id) =>
      '$_baseUrlNew/api/medicamentos/delete/$id';

  // Mensalidade
  static String allMensalidades = '$_baseUrlNew/api/mensalidades';
  static String createMensalidade = '$_baseUrlNew/api/mensalidades/insert';
  static String updateMensalidade(String id) =>
      '$_baseUrlNew/api/mensalidades/update/$id';
  static String deleteMensalidade(String id) =>
      '$_baseUrlNew/api/mensalidades/delete/$id';

  // Modalidade
  static String allModalidades = '$_baseUrlNew/api/modalidades';
  static String createModalidade = '$_baseUrlNew/api/modalidades/insert';
  static String updateModalidade(String id) =>
      '$_baseUrlNew/api/modalidades/update/$id';
  static String deleteModalidade(String id) =>
      '$_baseUrlNew/api/modalidades/delete/$id';

  // Objetivo
  static String allObjetivos = '$_baseUrlNew/api/objetivos';
  static String createObjetivo = '$_baseUrlNew/api/objetivos/insert';
  static String updateObjetivo(String id) =>
      '$_baseUrlNew/api/objetivos/update/$id';
  static String deleteObjetivo(String id) =>
      '$_baseUrlNew/api/objetivos/delete/$id';

  // Parceiro
  static String allParceiros = '$_baseUrlNew/api/parceiro';
  static String createParceiro = '$_baseUrlNew/api/parceiro/insert';
  static String updateParceiro(String id) =>
      '$_baseUrlNew/api/parceiro/update/$id';
  static String deleteParceiro(String id) =>
      '$_baseUrlNew/api/parceiro/delete/$id';

  static String allParceirosPorEmp(String id) =>
      '$_baseUrlNew/api/parceiro/empresa/$id';

  // Personal
  static String allPersonais = '$_baseUrlNew/api/personais';
  static String createPersonal = '$_baseUrlNew/api/personais/insert';
  static String updatePersonal(String id) =>
      '$_baseUrlNew/api/personais/update/$id';
  static String deletePersonal(String id) =>
      '$_baseUrlNew/api/personais/delete/$id';

  // Plano
  static String allPlanos = '$_baseUrlNew/api/planos';
  static String createPlano = '$_baseUrlNew/api/planos/insert';
  static String updatePlano(String id) => '$_baseUrlNew/api/planos/update/$id';
  static String deletePlano(String id) => '$_baseUrlNew/api/planos/delete/$id';

  // Role
  static String allRoles = '$_baseUrlNew/api/role';
  static String createRole = '$_baseUrlNew/api/role';
  static String updateRole(String id) => '$_baseUrlNew/api/role/$id';
  static String deleteRole(String id) => '$_baseUrlNew/api/roles/delete/$id';

  // Setor
  static String allSetores = '$_baseUrlNew/api/setor';
  static String createSetor = '$_baseUrlNew/api/setor';
  static String updateSetor(String id) => '$_baseUrlNew/api/setor/update/$id';
  static String deleteSetor(String id) => '$_baseUrlNew/api/setor/delete/$id';

  // Suplemento
  static String allSuplementos = '$_baseUrlNew/api/suplementos';
  static String createSuplemento = '$_baseUrlNew/api/suplementos/insert';
  static String updateSuplemento(String id) =>
      '$_baseUrlNew/api/suplementos/update/$id';
  static String deleteSuplemento(String id) =>
      '$_baseUrlNew/api/suplementos/delete/$id';

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
  static String desfazerContaPagar(String id) =>
      '$_baseUrlNew/api/contas-pagar/desfazer/$id';

  // Contas a Receber
  static String get allContasReceber => '$_baseUrlNew/api/contas-receber';
  static String get createContaReceber => '$_baseUrlNew/api/contas-receber';
  static String updateContaReceber(String id) =>
      '$_baseUrlNew/api/contas-receber/$id';
  static String deleteContaReceber(String id) =>
      '$_baseUrlNew/api/contas-receber/$id';
  static String registrarBaixaContaReceber(String id) =>
      '$_baseUrlNew/api/contas-receber/$id/baixa';
  static String desfazerContaReceber(String id) =>
      '$_baseUrlNew/api/contas-receber/desfazer/$id';

  // Contas Bancárias
  static const String contasBancarias = '$_baseUrlNew/api/contas-bancaria';
  static const String allContasBancarias = '$contasBancarias/saldos';
  static const String createContaBancaria = contasBancarias;
  static String updateContaBancaria(String id) => '$contasBancarias/$id';
  static String deleteContaBancaria(String id) => '$contasBancarias/$id';

  // Ponto
  static String pontoRegistrar = '$_baseUrlNew/api/pontos/registrar';
  static String pontoListar = '$_baseUrlNew/api/pontos/listar';
  static String pontoPdf = '$_baseUrlNew/api/pontos/pdf';
  static String pontoBancoHoras = '$_baseUrlNew/api/pontos/banco-horas';

  // Países / Estados / Cidades
  static const String buscarPaises = '$_baseUrlNew/api/pais';
  static String buscarEstados(String paisId) => '$_baseUrlNew/api/estado/pais/$paisId';
  static String buscarCidades(String estadoId) => '$_baseUrlNew/api/cidade/estado/$estadoId';

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

  static String chatStart(String id, String setor) =>
      '$_chatId/ws-chat?user=$id&sector=$setor';

  static String chatStartfetch(String id) => '$_baseUrlNew/api/chat/$id';

  static String downloadFile(dynamic id) =>
      '$_baseUrlNew/api/files/download/$id';

  static String getFile(dynamic id) => '$_baseUrlNew/api/files/$id';

  static String get uploadFile => '$_baseUrlNew/api/files/upload';

  static String chatFinalize(dynamic id) => '$_baseUrlNew/api/chat/$id';
  static String chatDelete(dynamic id) => '$_baseUrlNew/api/chat/$id';

  static String getAllTelas(String nome, {int? empId, int? clienteId}) {
    final params = <String, String>{};
    if (empId != null) params['empId'] = empId.toString();
    if (clienteId != null) params['clienteId'] = clienteId.toString();
    final query = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';
    return '$_baseUrlNew/api/telas/$nome$query';
  }

  static String getAllpreferencias(String id, String setor) =>
      ('$_baseUrlNew/api/$id/user-preferences/$setor');

  // Caso seu backend também sirva link público direto:
  static String publicFileUrl(int fileId) =>
      '$_baseUrlNew/files/public/$fileId';

  static String atualizarUsuario(int fileId) =>
      '$_baseUrlNew/api/parceiro/atualizar/$fileId';

  static String updateArquivoLido(int fileId) =>
      '$_baseUrlNew/api/parceiro/atualizar/$fileId';

  static String get getFinance => '$_baseUrlNew/api/dashboard/finance/series';
  static String get statusCounts => '$_baseUrlNew/api/dashboard/statusCounts';
  static String get chatDaily => '$_baseUrlNew/api/dashboard/chats/daily';

  static String get chatDailys => '$_baseUrlNew/api/dashboard/chats/dailys';

  static String get quarterlyComparison =>
      '$_baseUrlNew/api/dashboard/finance/quarterlyComparison';

  static String get overdue =>
      '$_baseUrlNew/api/dashboard/finance/alerts/overdue';

  static String get dueSoon =>
      '$_baseUrlNew/api/dashboard/finance/alerts/dueSoon';

  static String get kpis => '$_baseUrlNew/api/dashboard/kpis';

  // Jobs Monitor
  static String get allJobs => '$_baseUrlNew/api/admin/jobs';

  // Tipo Parceiro
  static String get allTipoParceiro => '$_baseUrlNew/api/tipo-parceiro';
  static String get createTipoParceiro => '$_baseUrlNew/api/tipo-parceiro';
  static String updateTipoParceiro(String id) => '$_baseUrlNew/api/tipo-parceiro/$id';
  static String deleteTipoParceiro(String id) => '$_baseUrlNew/api/tipo-parceiro/$id';

  // Servico Contratado
  static String get allServicoContratado => '$_baseUrlNew/api/servico-contratado';
  static String get createServicoContratado => '$_baseUrlNew/api/servico-contratado';
  static String updateServicoContratado(String id) => '$_baseUrlNew/api/servico-contratado/$id';
  static String deleteServicoContratado(String id) => '$_baseUrlNew/api/servico-contratado/$id';

  // Modulo Servico
  static String get allModuloServico => '$_baseUrlNew/api/modulo-servico';
  static String get createModuloServico => '$_baseUrlNew/api/modulo-servico';
  static String updateModuloServico(String id) => '$_baseUrlNew/api/modulo-servico/$id';
  static String deleteModuloServico(String id) => '$_baseUrlNew/api/modulo-servico/$id';
  static String jobHistorico(String nome) => '$_baseUrlNew/api/admin/jobs/$nome/historico';
  static String jobExecutar(String nome) => '$_baseUrlNew/api/admin/jobs/$nome/executar';

  static String get clientDistribution =>
      '$_baseUrlNew/api/dashboard/finance/clientDistribution';

  static String get trend => '$_baseUrlNew/api/dashboard/finance/trend';

  static String get ticketsTrend => '$_baseUrlNew/api/dashboard/tickets/trend';

  static String get financeFluxoDiario =>
      '$_baseUrlNew/api/dashboard/finance/fluxo-diario';

  static String get financeFluxoDiarioSaldo => '$_baseUrlNew/api/contas/saldos';

  static String financeFluxoEvolucao(int fileId) =>
      '$_baseUrlNew/api/contas/$fileId/evolucao/';

  static String get financeFluxoDiarioPdf =>
      '$_baseUrlNew/api/contas/extrato/pdf';

  static String get baseUrl => _baseUrlNew;

  // Certificado Digital
  static String certificadosByEmpresa(int empresaId) => '$_baseUrlNew/api/certificados?empresaId=$empresaId';
  static String get uploadCertificado => '$_baseUrlNew/api/certificados/upload';
  static String deleteCertificado(int id) => '$_baseUrlNew/api/certificados/$id';
  static String get alertasCertificados => '$_baseUrlNew/api/certificados/alertas';

  static String getAllRoles =
      '$_baseUrlNew/api/role?size=1000'; // Aumentamos o size para pegar todas as roles

  static String associateRoleToLogin(int loginId, int roleId) {
    return '$_baseUrlNew/api/logins/$loginId/roles/$roleId';
  }

  static String removeRoleFromLogin(int loginId, int roleId) {
    return '$_baseUrlNew/api/logins/$loginId/roles/$roleId';
  }

  //ApiLinks.fecharChamado(widget.chamadoId),
  static String getRolesLoginId(String id) =>
      '$_baseUrlNew/api/logins/$id/roles';

  static String fecharChamados(String id) => "$_baseUrlNew/chamados/$id/fechar";

  static String chatByEmpesaId(String id) => '$_baseUrlNew/api/chat/chat/$id';

  static String clienteByEmpresaId(String id) =>
      '$_baseUrlNew/api/parceiro/parceiro/$id';

  static String chamadoByEmpresaId(String id) =>
      '$_baseUrlNew/api/chamados/chamado/$id';

  static const String workflowChamados = '$_baseUrlNew/api/workflow/chamados';

  static String getAllChamados(String id) =>
      '$_baseUrlNew/api/workflow/chamados/$id/historico';

  // Ticket
  static String get allTickets => '$_baseUrlNew/api/ticket';
  static String get createTicket => '$_baseUrlNew/api/ticket';
  static String updateTicket(String id) => '$_baseUrlNew/api/ticket/$id';
  static String deleteTicket(String id) => '$_baseUrlNew/api/ticket/$id';

  // Order
  static String get allOrders => '$_baseUrlNew/api/order';
  static String get createOrder => '$_baseUrlNew/api/order';
  static String updateOrder(String id) => '$_baseUrlNew/api/order/$id';
  static String deleteOrder(String id) => '$_baseUrlNew/api/order/$id';

  // Dividendo
  static String get allDividendos => '$_baseUrlNew/api/dividendos';
  static String get createDividendo => '$_baseUrlNew/api/dividendos';
  static String updateDividendo(String id) => '$_baseUrlNew/api/dividendos/$id';
  static String deleteDividendo(String id) => '$_baseUrlNew/api/dividendos/$id';

  // Cotação Frete
  static String get allCotacoesFrete => '$_baseUrlNew/api/cotacaofrete';
  static String get createCotacaoFrete => '$_baseUrlNew/api/cotacaofrete';
  static String updateCotacaoFrete(String id) => '$_baseUrlNew/api/cotacaofrete/$id';
  static String deleteCotacaoFrete(String id) => '$_baseUrlNew/api/cotacaofrete/$id';

  // Pedido
  static String get allPedidos => '$_baseUrlNew/api/pedidos';
  static String get createPedido => '$_baseUrlNew/api/pedidos';
  static String updatePedido(String id) => '$_baseUrlNew/api/pedidos/$id';
  static String deletePedido(String id) => '$_baseUrlNew/api/pedidos/$id';

  // Calendário Guias
  static String get allCalendariosGuias => '$_baseUrlNew/api/calendarios-guias';
  static String get createCalendarioGuias => '$_baseUrlNew/api/calendarios-guias';
  static String updateCalendarioGuias(String id) => '$_baseUrlNew/api/calendarios-guias/$id';
  static String deleteCalendarioGuias(String id) => '$_baseUrlNew/api/calendarios-guias/$id';

  // Cargo
  static String get allCargos => '$_baseUrlNew/api/cargo';
  static String get createCargo => '$_baseUrlNew/api/cargo';
  static String updateCargo(String id) => '$_baseUrlNew/api/cargo/$id';
  static String deleteCargo(String id) => '$_baseUrlNew/api/cargo/$id';

  // Centro de Custo
  static String get allCentrosCusto => '$_baseUrlNew/api/centro-custo';
  static String get createCentroCusto => '$_baseUrlNew/api/centro-custo';
  static String updateCentroCusto(String id) => '$_baseUrlNew/api/centro-custo/$id';
  static String deleteCentroCusto(String id) => '$_baseUrlNew/api/centro-custo/$id';

  // Departamento
  static String get allDepartamentos => '$_baseUrlNew/api/departamento';
  static String get createDepartamento => '$_baseUrlNew/api/departamento';
  static String updateDepartamento(String id) => '$_baseUrlNew/api/departamento/$id';
  static String deleteDepartamento(String id) => '$_baseUrlNew/api/departamento/$id';

  // Feriado
  static String get allFeriados => '$_baseUrlNew/api/feriado';
  static String get createFeriado => '$_baseUrlNew/api/feriado';
  static String updateFeriado(String id) => '$_baseUrlNew/api/feriado/$id';
  static String deleteFeriado(String id) => '$_baseUrlNew/api/feriado/$id';

  // Alerta Aluno
  static String get allAlertasAluno => '$_baseUrlNew/api/alertas-aluno';

  // Funcionário
  static String get allFuncionarios => '$_baseUrlNew/api/funcionario';
  static String get createFuncionario => '$_baseUrlNew/api/funcionario';
  static String updateFuncionario(String id) => '$_baseUrlNew/api/funcionario/$id';
  static String deleteFuncionario(String id) => '$_baseUrlNew/api/funcionario/$id';
  static String registrarPontoFuncionario(String id) => '$_baseUrlNew/api/funcionario/$id/ponto';
  static String pontosFuncionario(String id) => '$_baseUrlNew/api/funcionario/$id/pontos';
  static String acertoPontoFuncionario(String id) => '$_baseUrlNew/api/funcionario/$id/acerto-ponto';
  static String pdfPontoFuncionario(String id) => '$_baseUrlNew/api/funcionario/$id/ponto/pdf';  static String get createAlertaAluno => '$_baseUrlNew/api/alertas-aluno';
  static String updateAlertaAluno(String id) => '$_baseUrlNew/api/alertas-aluno/$id';
  static String deleteAlertaAluno(String id) => '$_baseUrlNew/api/alertas-aluno/$id';

  // Avaliação Física
  static String get allAvaliacoesFisicas => '$_baseUrlNew/api/avaliacoes-fisicas';
  static String get createAvaliacaoFisica => '$_baseUrlNew/api/avaliacoes-fisicas';
  static String updateAvaliacaoFisica(String id) => '$_baseUrlNew/api/avaliacoes-fisicas/$id';
  static String deleteAvaliacaoFisica(String id) => '$_baseUrlNew/api/avaliacoes-fisicas/$id';

  // Classificação
  static String get allClassificacoes => '$_baseUrlNew/api/classificacoes';
  static String get createClassificacao => '$_baseUrlNew/api/classificacoes';
  static String updateClassificacao(String id) => '$_baseUrlNew/api/classificacoes/$id';
  static String deleteClassificacao(String id) => '$_baseUrlNew/api/classificacoes/$id';

  // Treino
  static String get allTreinos => '$_baseUrlNew/api/treinos';
  static String get createTreino => '$_baseUrlNew/api/treinos';
  static String updateTreino(String id) => '$_baseUrlNew/api/treinos/$id';
  static String deleteTreino(String id) => '$_baseUrlNew/api/treinos/$id';

  // Nota Fiscal Entrada
  static String get allNotasFiscaisEntrada => '$_baseUrlNew/api/notas-fiscais-entrada';
  static String get createNotaFiscalEntrada => '$_baseUrlNew/api/notas-fiscais-entrada';
  static String updateNotaFiscalEntrada(String id) => '$_baseUrlNew/api/notas-fiscais-entrada/$id';
  static String deleteNotaFiscalEntrada(String id) => '$_baseUrlNew/api/notas-fiscais-entrada/$id';

  // Nota Fiscal Saída
  static String get allNotasFiscaisSaida => '$_baseUrlNew/api/notas-fiscais-saida';
  static String get createNotaFiscalSaida => '$_baseUrlNew/api/notas-fiscais-saida';
  static String updateNotaFiscalSaida(String id) => '$_baseUrlNew/api/notas-fiscais-saida/$id';
  static String deleteNotaFiscalSaida(String id) => '$_baseUrlNew/api/notas-fiscais-saida/$id';

  // Horário Funcionário
  static String get allHorariosFunc => '$_baseUrlNew/api/horarioFunc';
  static String get createHorarioFunc => '$_baseUrlNew/api/horarioFunc';
  static String updateHorarioFunc(String id) => '$_baseUrlNew/api/horarioFunc/$id';
  static String deleteHorarioFunc(String id) => '$_baseUrlNew/api/horarioFunc/$id';

  // Tipo Produto
  static String get allTiposProduto => '$_baseUrlNew/api/tipoProdutos';
  static String get createTipoProduto => '$_baseUrlNew/api/tipoProdutos';
  static String updateTipoProduto(String id) => '$_baseUrlNew/api/tipoProdutos/$id';
  static String deleteTipoProduto(String id) => '$_baseUrlNew/api/tipoProdutos/$id';
}

