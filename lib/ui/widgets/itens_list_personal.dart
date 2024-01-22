import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';

/// Flutter code sample for [IconButton].

/*void main() => runApp(const ListItensExampleApp());

class ListItensExampleApp extends StatelessWidget {
  const ListItensExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('IconButton Sample')),
        body: const Center(
          child: ListItensExample(),
        ),
      ),
    );
  }
} 

double _volume = 0.0;*/

class ListItensExample extends StatelessWidget {
  const ListItensExample({
    Key? key,
    required this.nome,
    required this.cpf,
    required this.cref,
    required this.valor,
    required this.foto,
    required this.id,
  }) : super(key: key);

  final String nome;
  final String cpf;
  final String cref;
  final double valor;
  final String foto;
  final int id;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 160,
      alignment: Alignment.topCenter,
      color: Colors.transparent,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 70,
                height: 140,
                padding: EdgeInsets.zero,
                color: Color(0xFF5937B2),
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: CircleAvatar(
                    radius: 20,
                  ),
                ),
              ),
              Flexible(
                child: Container(
                  height: 140,
                  color: Color(0xFF5937B2),
                  child: Column(
                    children: [
                      Column(
                        children: <Widget>[
                          (Text(
                            'Nome : $nome',
                            textAlign: TextAlign.start,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )), // <-- Wrapped in Flexible.
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          (Text(
                            'CPF: $cpf...    CREF: $cref',
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )), // <-- Wrapped in Flexible.
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          (Text(
                            'Vlr Aula: R $valor',
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color.fromARGB(255, 218, 16, 2),
                            ),
                          )), // <-- Wrapped in Flexible.
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                        width: double.infinity,
                      ),
                      const SizedBox(
                        height: 1,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: Colors.black),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                        width: double.infinity,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Container(
                            width: 50,
                            height: 50,
                            padding: EdgeInsets.all(4.0),
                            decoration: const BoxDecoration(
                                color: Color(0xFFFA903A),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(6.0),
                                  topRight: Radius.circular(6.0),
                                  bottomLeft: Radius.circular(6.0),
                                  bottomRight: Radius.circular(6.0),
                                )),
                            child: Column(
                              children: <Widget>[
                                Tooltip(
                                  message: 'this is something',
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const UpdateProfileScreen()));
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: Image.asset(
                                        "assets/images/observacao.png",
                                        height: 40,
                                        width: 40,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                            width: 10,
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            padding: EdgeInsets.all(4.0),
                            decoration: const BoxDecoration(
                                color: Color(0xFFFA903A),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(6.0),
                                  topRight: Radius.circular(6.0),
                                  bottomLeft: Radius.circular(6.0),
                                  bottomRight: Radius.circular(6.0),
                                )),
                            child: Column(
                              children: <Widget>[
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const UpdateProfileScreen()));
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: Image.asset(
                                      "assets/images/carrinho.png",
                                      height: 40,
                                      width: 40,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                            width: 10,
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            padding: EdgeInsets.all(4.0),
                            decoration: const BoxDecoration(
                                color: Color(0xFFFA903A),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(6.0),
                                  topRight: Radius.circular(6.0),
                                  bottomLeft: Radius.circular(6.0),
                                  bottomRight: Radius.circular(6.0),
                                )),
                            child: Column(
                              children: <Widget>[
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const UpdateProfileScreen()));
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: Image.asset(
                                      "assets/images/horarios.png",
                                      height: 40,
                                      width: 40,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                            width: 10,
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            padding: EdgeInsets.all(4.0),
                            decoration: const BoxDecoration(
                                color: Color(0xFFFA903A),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(6.0),
                                  topRight: Radius.circular(6.0),
                                  bottomLeft: Radius.circular(6.0),
                                  bottomRight: Radius.circular(6.0),
                                )),
                            child: Column(
                              children: <Widget>[
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const UpdateProfileScreen()));
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: Image.asset(
                                      "assets/images/chat.png",
                                      height: 40,
                                      width: 40,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                            width: 5,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
