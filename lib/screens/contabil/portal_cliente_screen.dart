// lib/screens/contabil/portal_cliente_screen.dart
import 'package:flutter/material.dart';

class PortalClienteScreen extends StatelessWidget {
  const PortalClienteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Portal do Cliente',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Card 1: Saldo
                Card(
                  child: Container(
                    width: 100,
                    height: 120,
                    color: Colors.blue.shade50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wallet, size: 32, color: Colors.blue),
                        const SizedBox(height: 8),
                        const Text('Saldo'),
                        const SizedBox(height: 4),
                        const Text('R\$ 0,00',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                // Card 2: Documentos Pendentes
                Card(
                  child: Container(
                    width: 100,
                    height: 120,
                    color: Colors.orange.shade50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.insert_drive_file,
                            size: 32, color: Colors.orange),
                        const SizedBox(height: 8),
                        const Text('Documentos\nPendentes',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11)),
                        const SizedBox(height: 4),
                        const Text('0',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                // Card 3: Alertas
                Card(
                  child: Container(
                    width: 100,
                    height: 120,
                    color: Colors.red.shade50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_active,
                            size: 32, color: Colors.red),
                        const SizedBox(height: 8),
                        const Text('Alertas'),
                        const SizedBox(height: 4),
                        const Text('0',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
