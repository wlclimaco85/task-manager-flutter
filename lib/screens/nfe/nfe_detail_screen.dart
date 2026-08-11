import 'package:flutter/material.dart';
import 'package:task_manager_flutter/web/screens/details/nfe_detail_screen.dart';

class NfeDetailScreen extends StatelessWidget {
  final int nfeId;

  const NfeDetailScreen({super.key, required this.nfeId});

  @override
  Widget build(BuildContext context) {
    return NfeSankhyaDetailScreen(item: {'id': nfeId});
  }
}
