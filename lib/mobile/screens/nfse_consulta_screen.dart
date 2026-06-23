import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../customization/generic_grid_card.dart';
import '../../../models/nfse_model.dart';

/// Consulta de NFS-e (nota fiscal de serviço) — módulo NFS-e do cliente.
/// Lista as notas emitidas via grid genérico (`/api/nfse`). A emissão é uma
/// ação separada (a construir) sobre `/api/fiscal/nfse/emitir`.
class NfseConsultaScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  final VoidCallback? onUserBannerTapped;

  const NfseConsultaScreen({
    super.key,
    required this.hasPermission,
    this.onUserBannerTapped,
  });

  @override
  Widget build(BuildContext context) {
    return GenericMobileGridScreen<Nfse>(
      title: 'Notas de Serviço (NFS-e)',
      fetchEndpoint: ApiLinks.allNfse,
      createEndpoint: ApiLinks.allNfse,
      updateEndpoint: ApiLinks.nfse(':id'),
      deleteEndpoint: ApiLinks.nfse(':id'),
      fromJson: (json) => Nfse.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Nfse.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'dataEmissao',
      useUserBannerAppBar: true,
      onUserBannerTapped: onUserBannerTapped,
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
    );
  }
}
