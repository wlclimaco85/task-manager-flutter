import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/home_screen.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/noticia_model.dart';
import 'package:task_manager_flutter/data/models/new_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/screens/bottom_navbar_screen.dart'; // Corrigida a importação

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _loginInProgress = false;

  List<News> newsList = [];
  bool isLoading = false;
  int page = 1;

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
      setState(() {
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

    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.allNoticias);

    _loginInProgress = false;
    if (mounted) {
      setState(() {});
    }

    if (response.isSuccess) {
      LoginModel model = LoginModel.fromJson(response.body!);
      await AuthUtility.setUserInfo(model);
      setState(() {
        page++;
        isLoading = false;
      });
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBarScreen()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect email or password')),
        );
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
      }
    } else {
      if (mounted) {
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect email or password')),
        );
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

  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_controller.position.pixels == _controller.position.maxScrollExtent &&
        !isLoading) {
      fetchNews();
    }
  }

  Future<void> _refreshNews() async {
    await fetchNews(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notícias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshNews,
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
                  ? const Center(child: CircularProgressIndicator())
                  : const SizedBox.shrink();
            }

            final news = newsList[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(news.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(news.summary),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fonte',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text('Data', style: TextStyle(fontSize: 12)),
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
          // Lógica de navegação
        },
      ),
    );
  }
}
