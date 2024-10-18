import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/data/models/noticias_model.dart';

class NewsDetailScreen extends StatelessWidget {
  final Data news;

  const NewsDetailScreen({Key? key, required this.news}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(news.titulo ?? 'Detalhes da Notícia'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                news.titulo ?? 'Título não disponível',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                news.fonte != null ? "Fonte: ${news.fonte}" : '',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 10),
              Text(
                news.dtNoticia != null
                    ? "Data: ${DateFormat('dd/MM/yyyy HH:mm').format(news.dtNoticia!.toLocal())}"
                    : '',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 20),
              Text(
                news.noticia ?? 'Notícia não disponível',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
