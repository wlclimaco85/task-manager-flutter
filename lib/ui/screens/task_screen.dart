import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/task_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/ui/widgets/status_change_botom_sheet.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:task_manager_flutter/data/models/noticias_model.dart';
import 'package:task_manager_flutter/ui/screens/NewsDetailScreen.dart';

class TaskScreen extends StatefulWidget {
  final String screenStatus;
  final String apiLink;
  final bool showAllSummeryCard;
  final bool floatingActionButton;

  const TaskScreen({
    Key? key,
    required this.screenStatus,
    required this.apiLink,
    this.showAllSummeryCard = false,
    this.floatingActionButton = true,
  }) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class NoticiaModel {
  String? status;
  String? token;
  List<Data>? data;

  NoticiaModel({this.status, this.token, this.data});

  NoticiaModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];

    // Verifica se 'data' é uma lista de listas
    if (json['data'] != null) {
      /*  data = [];
    // Itera sobre cada lista no 'data'
    for (var list in json['data']) {
      // Adiciona à lista de 'data' uma lista de Map<String, dynamic>
      data.add(List<Map<String, dynamic>>.from(list.map((item) => Map<String, dynamic>.from(item))));
    } */
      //  List<Data> dataList = Data.fromJsonList2(json['data']['noticiasDTO']);
      List<Data> dataList = Data.fromJsonList(json['data']['noticiasDTO']);
      data =
          dataList; //json['data'] != null ? Data.fromJson(json['data']) : null;
    } else {
      data = null;
    }

    //data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  /* Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }*/

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (this.data != null) {
      // Mapeia cada item da lista 'data' para o formato JSON
      data['data'] = this.data!.map((item) => item.toJson()).toList();
    }
    return data;
  }
}

class _TaskScreenState extends State<TaskScreen> {
  List<Data> newsList = [];
  bool isLoading = false;
  int page = 1;

  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchNews();
    _controller.addListener(_onScroll);
  }

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
    String jsonString;
    NoticiaModel model;
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.allNoticias);

    if (response.statusCode == 200) {
      if (response.body != null) {
        jsonString = json.encode(response.body);
        model = NoticiaModel.fromJson(response.body!);
        if (model != null && model.data != null) {
          newsList.addAll(model.data!);
        }
        // Use jsonString conforme necessário
      } else {
        // Trate o caso onde o data é nulo
      }

      // Map<String, dynamic> newsJson = json.decode(response.body);

      setState(() {
        page++;
        isLoading = false;
      });
    } else {
      throw Exception('Falha ao carregar as notícias');
    }
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

  TaskListModel _taskModel = TaskListModel();

  Future<void> getTask() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    final NetworkResponse response =
        await NetworkCaller().getRequest(widget.apiLink);
    if (response.isSuccess) {
      _taskModel = TaskListModel.fromJson(response.body!);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load data!"),
          ),
        );
      }
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  int count1 = 0;
  int count2 = 0;
  int count3 = 0;
  int count4 = 0;

  Future<void> statusCount() async {
    isLoading = true;
    if (mounted) {
      setState(() {});
    }
    final NetworkResponse newTaskResponse =
        await NetworkCaller().getRequest(ApiLinks.newTaskStatus);
    TaskListModel newTaskModel = TaskListModel.fromJson((newTaskResponse != null
        ? newTaskResponse.body != null
            ? newTaskResponse.body!
            : {}
        : {}));

    if (mounted) {
      setState(() {
        count1 = newTaskModel.data?.length ?? 0;
      });
    }

    final cancelledTaskResponse =
        await NetworkCaller().getRequest(ApiLinks.cancelledTaskStatus);
    TaskListModel cancelledTaskModel =
        TaskListModel.fromJson(cancelledTaskResponse != null
            ? cancelledTaskResponse.body != null
                ? cancelledTaskResponse.body!
                : {}
            : {});
    if (mounted) {
      setState(() {
        count2 = cancelledTaskModel.data?.length ?? 0;
      });
    }

    final completedTaskResponse =
        await NetworkCaller().getRequest(ApiLinks.completedTaskStatus);

    TaskListModel completedTaskModel =
        TaskListModel.fromJson(completedTaskResponse != null
            ? completedTaskResponse.body != null
                ? completedTaskResponse.body!
                : {}
            : {});
    if (mounted) {
      setState(() {
        count3 = completedTaskModel.data?.length ?? 0;
      });
    }

    final inProgressResponse =
        await NetworkCaller().getRequest(ApiLinks.inProgressTaskStatus);
    TaskListModel inProgressTaskModel =
        TaskListModel.fromJson(inProgressResponse != null
            ? inProgressResponse.body != null
                ? inProgressResponse.body!
                : {}
            : {});
    if (mounted) {
      setState(() {
        count4 = inProgressTaskModel.data?.length ?? 0;
      });
    }

    isLoading = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.deleteTask(taskId));
    if (response.isSuccess) {
      _taskModel.data!.removeWhere((element) => element.sId == taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Task Deleted Successfully!")));
      }
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // int getCountForStatus(String status) {
  //   final Data? statusData = statusCountModel.data?.firstWhere(
  //     (data) => data.statusId == status,
  //     orElse: () => Data(statusId: status, count: 0),
  //   );
  //   return statusData?.count ?? 0;
  // }
  bool standardSelected = false;
  bool filledSelected = false;
  bool tonalSelected = false;
  bool outlinedSelected = false;
  int count = 0;

  void log(String message) => print(message);

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
        child: Stack(
          children: [
            ListView.builder(
              controller: _controller,
              itemCount: newsList.length + 1,
              itemBuilder: (context, index) {
                if (index == newsList.length) {
                  return isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 60, // Tamanho maior
                            height: 60, // Tamanho maior
                            child: CircularProgressIndicator(
                                strokeWidth: 6.0), // Indicador maior
                          ),
                        )
                      : SizedBox.shrink();
                }

                final news = newsList[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(
                      news.tituloResu != null
                          ? news.tituloResu!
                          : 'Título não disponível',
                      style: const TextStyle(
                        fontSize: 16, // Define o tamanho da fonte para 16
                        fontWeight: FontWeight
                            .bold, // Define o estilo da fonte como negrito
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(news.resumo != null
                            ? news.resumo!
                            : 'Título não disponível'),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '${news.fonte ?? 'Título'}     ${news.dtNoticia != null ? DateFormat('dd/MM/yyyy HH:mm').format(news.dtNoticia!.toLocal()) : '   '}',
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold)),
                            Text(
                                news.autor != null
                                    ? news.autor!
                                    : 'Título não disponível',
                                style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsDetailScreen(news: news),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /* @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF340A9C),
      appBar: userBanner(
        context,
        onTapped: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const UpdateProfileScreen()));
        },
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButtonExample(
                text: 'Personal',
                color: 'Screenshot_2.png',
                onPresse: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PersonalScreen()));
                },
              ),
              const SizedBox(width: 10),
              IconButtonExample(
                text: 'Academias',
                color: 'images (1).png',
                onPresse: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AcademiaScreen()));
                },
              ),
              const SizedBox(width: 10),
              IconButtonExample(
                text: 'Treinos',
                color: 'images.png',
                onPresse: () {
                  print('Treinos');
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButtonExample(
                text: 'Suplemento',
                color: 'images (2).png',
                onPresse: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SuplementoScreen()));
                },
              ),
              const SizedBox(width: 10),
              IconButtonExample(
                text: 'Exames',
                color: 'images (3).png',
                onPresse: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ExameScreen()));
                },
              ),
              const SizedBox(width: 10),
              IconButtonExample(
                text: 'Dieta',
                color: 'images (4).png',
                onPresse: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Dietacreen()));
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButtonExample(
                text: 'Medicamento',
                color: 'Screenshot_3.png',
                onPresse: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Medicamentoscreen()));
                },
              ),
              const SizedBox(width: 10),
              IconButtonExample(
                text: 'Avaliação Fisica',
                color: 'Screenshot_4.png',
                onPresse: () {
                  print('Avaliação Fisica');
                },
              ),
              const SizedBox(width: 10),
              IconButtonExample(
                text: 'Pagamentos',
                color: 'Screenshot_5.png',
                onPresse: () {
                  print('Pagamentos');
                },
              ),
            ],
          ),
        ],
      ),
    );
  } */

  Color _getChipColor() {
    switch (widget.screenStatus) {
      case "Noticias":
        return Colors.blue;
      case "Cotação":
        return Colors.green;
      case "Compra":
        return Colors.red;
      case "Venda":
        return Colors.pink.shade400;
      case "Entrar":
        return Colors.pink.shade400;
      default:
        return Colors.grey;
    }
  }

  void statusUpdateButtomSheet(TaskData task) {
    showModalBottomSheet(
      shape: ShapeBorder.lerp(
          RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Colors.black)),
          RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Colors.black)),
          1)!,
      context: context,
      builder: (context) {
        return UpdateStatus(
          task: task,
          onTaskComplete: () {
            getTask();
          },
        );
      },
    );
  }
}
