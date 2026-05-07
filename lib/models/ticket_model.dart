import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class TicketItem {
  int? id;
  int? orderId;
  int? corretoraId;
  String? acao;
  double? cotacao;
  double? lucro;
  String? status;
  String? tipo;
  String? comentario;
  int? quantidade;

  TicketItem({this.id, this.orderId, this.corretoraId, this.acao, this.cotacao, this.lucro, this.status, this.tipo, this.comentario, this.quantidade});

  TicketItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderId = json['orderId'];
    corretoraId = json['corretoraId'];
    acao = json['acao'];
    cotacao = (json['cotacao'] as num?)?.toDouble();
    lucro = (json['lucro'] as num?)?.toDouble();
    status = json['status'];
    tipo = json['tipo'];
    comentario = json['comentario'];
    quantidade = json['quantidade'];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'corretoraId': corretoraId,
        'acao': acao,
        'cotacao': cotacao,
        'lucro': lucro,
        'status': status,
        'tipo': tipo,
        'comentario': comentario,
        'quantidade': quantidade,
      };

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(label: "Ação", fieldName: "acao", icon: Icons.trending_up, isInForm: true, isFilterable: true),
    FieldConfig(label: "Order ID", fieldName: "orderId", icon: Icons.receipt, isInForm: true),
    FieldConfig(label: "Corretora ID", fieldName: "corretoraId", icon: Icons.business, isInForm: true),
    FieldConfig(label: "Cotação", fieldName: "cotacao", icon: Icons.show_chart, isInForm: true),
    FieldConfig(label: "Lucro", fieldName: "lucro", icon: Icons.monetization_on, isInForm: true),
    FieldConfig(label: "Status", fieldName: "status", icon: Icons.info, isInForm: true, isFilterable: true),
    FieldConfig(label: "Tipo", fieldName: "tipo", icon: Icons.category, isInForm: true),
    FieldConfig(label: "Quantidade", fieldName: "quantidade", icon: Icons.numbers, isInForm: true),
    FieldConfig(label: "Comentário", fieldName: "comentario", icon: Icons.comment, isInForm: true),
  ];
}
