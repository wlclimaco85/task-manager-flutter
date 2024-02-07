class ApiLinks {
  ApiLinks._();
  static const String _baseIp =
      "http://192.168.56.1"; // "http://192.168.12.23"; // //"http://192.168.12.23";
  //static const String _baseIp = "http://192.168.56.1"; //"http://192.168.12.23";
  static const String _baseUrl = 'https://task.teamrabbil.com/api/v1';
  static const String _baseUrlNew = '$_baseIp:8088/boletobancos';
  //static const String _baseUrlNew =
  //    'https://academia-app-919f42758cd6.herokuapp.com/boletobancos';
  static const String allPersonal = '$_baseUrlNew/personal/findAll';
  static const String insertPersonal = '$_baseUrlNew/personal/inserir';
  static const String insertAluno = '$_baseUrlNew/personal/inserirAluno';
  static String regestration = '$_baseUrl/registration';
  static String profileUpdate = '$_baseUrl/profileUpdate';
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
}
