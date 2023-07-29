class ApiLinks {
  ApiLinks._();
  static const String _baseUrl = 'https://task.teamrabbil.com/api/v1';
  static String regestration = '$_baseUrl/registration';
  static String profileUpdate = '$_baseUrl/profileUpdate';
  static String login = '$_baseUrl/login';
  static String createTask = '$_baseUrl/createTask';
  static String listTaskByStatus(String status) => '$_baseUrl/listTaskByStatus/$status';
}
