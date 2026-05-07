import 'package:flutter/material.dart';
import '../../../models/parceiro_model.dart';
import '../../../utils/api_links.dart';
import '../../customization/generic_grid_card.dart';

class ParceiroGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ParceiroGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericMobileGridScreen<Parceiro>(
      title: "Parceiros",
      fetchEndpoint: ApiLinks.allParceiros,
      createEndpoint: ApiLinks.createParceiro,
      updateEndpoint: ApiLinks.updateParceiro(":id"),
      deleteEndpoint: ApiLinks.deleteParceiro(":id"),
      fromJson: (json) => Parceiro.fromJson(json),
      toJson: (p) => p.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Parceiro.fieldConfigsMobile(),
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      useUserBannerAppBar: true,
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
    );
  }
}
