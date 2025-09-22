import 'package:task_manager_flutter/data/models/regime_tributario_model.dart';
import 'package:task_manager_flutter/ui/widgets/tab_config.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/field_factory.dart';

List<TabConfig> tabConfigs = [
  // Aba Form
  TabConfig(
    title: "Dados Principais",
    icon: Icons.person,
    isGrid: true,
    endpoint: ApiLinks.allParceiros,
    fields: [
      FieldConfig(
        label: "Nome",
        fieldName: "nome",
        icon: Icons.person,
        isInForm: true,
        isRequired: true,
      ),
      FieldConfig(
        label: "CPF",
        fieldName: "cpf",
        icon: Icons.badge,
        isInForm: true,
      ),
      FieldConfig(
        label: "E-mail",
        fieldName: "email",
        icon: Icons.email,
        isInForm: true,
      ),
    ],
  ),

  // Aba Grid
  TabConfig(
    title: "Empresas",
    icon: Icons.business,
    isGrid: true,
    endpoint: ApiLinks.allEmpresas,
    //  parentField: "parceiroId",
    gridFieldConfigs: [
      FieldConfig(label: "Nome", fieldName: "nome", icon: Icons.business),
      FieldConfig(label: "CNPJ", fieldName: "cnpj", icon: Icons.badge),
    ],
  ),

  TabConfig(
    title: "Endereços",
    icon: Icons.location_city,
    isGrid: true,
    endpoint: ApiLinks.allExames,
    //  parentField: "parceiroId",
    gridFieldConfigs: [
      FieldConfig(
        label: "Logradouro",
        fieldName: "logradouro",
        icon: Icons.location_on,
      ),
      FieldConfig(
        label: "Cidade",
        fieldName: "cidade",
        icon: Icons.location_city,
      ),
    ],
  ),

  TabConfig(
    title: "Regimes Tributários",
    icon: Icons.receipt_long,
    isGrid: true,
    endpoint: ApiLinks.allRegimetributario,
    //parentField: "parceiroId",
    gridFieldConfigs: RegimeTributario.fieldConfigs,
  ),
];
