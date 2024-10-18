import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/home_screen.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/email_verification_screeen.dart';
import 'package:task_manager_flutter/ui/screens/bottom_navbar_screen.dart';
import 'package:task_manager_flutter/ui/widgets/custom_password_text_field.dart';
import 'package:task_manager_flutter/ui/widgets/custom_text_form_field.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/signup_form_screen.dart';
import 'dart:convert'; // Para converter JSON

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class News {
  final String title;
  final String summary;
  final String source;
  final String date;

  News(
      {required this.title,
      required this.summary,
      required this.source,
      required this.date});

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      title: json['title'],
      summary: json['summary'],
      source: json['source'],
      date: json['date'],
    );
  }
}

class NoticiaModel {
  String? status;
  String? token;
  Data? data;

  NoticiaModel({this.status, this.token, this.data});

  NoticiaModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _loginInProgress = false;

  List<News> newsList = []; // Lista de notícias
  bool isLoading = false; // Flag de carregamento
  int page = 1; // Controle de paginação

  // Função para buscar notícias do backend
  Future<void> fetchNews({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        page = 1;
        newsList.clear();
      });
    }

    setState(() {
      isLoading = true;
    });

    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.allNoticias);

    if (response.isSuccess) {
      NoticiaModel model = NoticiaModel.fromJson(response.body!);
      var x = 10;

      //   Map<dynamic>? newsJson = json.decode(response.body);
      setState(() {
        // newsList.addAll(newsJson.map((json) => News.fromJson(json)).toList());
        page++;
        isLoading = false;
      });
    } else {
      throw Exception('Falha ao carregar as notícias');
    }
  }

  Future<void> fetchNews2() async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> requestBody = {};

    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.allNoticias);
    _loginInProgress = false;
    if (mounted) {
      setState(() {});
    }

    if (response.isSuccess) {
      LoginModel model = LoginModel.fromJson(response.body!);
      await AuthUtility.setUserInfo(model);
      // List<dynamic> newsJson = json.decode(response.body);
      setState(() {
        //  newsList.addAll(newsJson.map((json) => News.fromJson(json)).toList());
        page++; // Incrementar página para buscar a próxima
        isLoading = false;
      });
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BottomNavBarScreen()),
            (route) => false);
      }
    } else {
      if (mounted) {
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect email or password')));
      }
    }
  }

  Future<void> login() async {
    _loginInProgress = true;
    if (mounted) {
      setState(() {});
    }
    Map<String, dynamic> requestBody = {
      "email": 'wlclimaco@gmail.com',
      "password": '123456'
    };
    final NetworkResponse response =
        await NetworkCaller().postRequest(ApiLinks.login, requestBody);
    _loginInProgress = false;
    if (mounted) {
      setState(() {});
    }
    if (response.isSuccess) {
      LoginModel model = LoginModel.fromJson(response.body!);
      await AuthUtility.setUserInfo(model);
      if (mounted) {
        fetchNews();
        //Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(builder: (context) => const BottomNavBarScreen()),
        //   (route) => false);
      }
    } else {
      if (mounted) {
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect email or password')));
      }
    }
  }

  late AnimationController _animationController;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          });
    super.initState();
    login();
  }

/*
  // Função para detectar scroll no final da lista
  void _onScroll() {
    if (!_controller.hasClients || isLoading) return;

    final thresholdReached = _controller.position.extentAfter <
        500; // Se o usuário está a 500px do fim

    if (thresholdReached) {
      fetchNews(); // Carregar mais notícias
    }
  }
*/
  final ScrollController _controller =
      ScrollController(); // Controlador de scroll

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Função para detectar o fim da lista e carregar mais notícias
  void _onScroll() {
    if (_controller.position.pixels == _controller.position.maxScrollExtent &&
        !isLoading) {
      fetchNews();
    }
  }

  // Função para o "Pull-to-Refresh"
  Future<void> _refreshNews() async {
    await fetchNews(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notícias'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _refreshNews(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNews,
        child: ListView.builder(
          controller: _controller,
          itemCount: newsList.length + 1,
          itemBuilder: (context, index) {
            if (index == newsList.length) {
              return isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox.shrink();
            }

            final news = newsList[index];
            return Card(
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(news.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(news.summary),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('teste',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('010101', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Notícias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Cotações',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Comprar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell),
            label: 'Vender',
          ),
        ],
        onTap: (index) {
          // Lógica de navegação aqui
          // Exemplo: navegar entre páginas dependendo do index selecionado
        },
      ),
    );
/*    return Scaffold(
      backgroundColor: const Color(0xFF340A9C),
      body: Container(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 70,
                        bottom: 32,
                      ),
                      child: Image.asset(
                        "assets/images/logoforafitn1.png",
                        height: 260,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Form(
                            key: _formKey,
                            child: CustomTextFormField(
                                hintText: "Email",
                                controller: _emailController,
                                textInputType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return "Please enter email";
                                  }
                                  return null;
                                }),
                          ),
                          const SizedBox(height: 12),
                          CustomPasswordTextFormField(
                            hintText: "Password",
                            controller: _passwordController,
                            obscureText: true,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Please enter password";
                              }
                              return null;
                            },
                            textInputType: TextInputType.visiblePassword,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFA903A),
                              minimumSize: const Size.fromHeight(50), // NEW
                            ),
                            onPressed: () {
                              login();
                            },
                            child: const Text(
                              'Acessar',
                              style:
                                  TextStyle(fontSize: 24, color: Colors.white),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFA903A),
                              minimumSize: const Size.fromHeight(50), // NEW
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SignUpFormScreen()),
                              );
                            },
                            child: const Text(
                              'Criar Conta',
                              style:
                                  TextStyle(fontSize: 24, color: Colors.white),
                            ),
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const EmailVarificationScreeen()));
                              },
                              child: const Text(
                                "Esqueceu a Senha?",
                                style: TextStyle(
                                    color: Color(0xFFFA903A),
                                    letterSpacing: .7,
                                    fontSize: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    ); */
  }
}
