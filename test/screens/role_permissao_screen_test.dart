import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/role_permissao_model.dart';
import 'package:task_manager_flutter/models/tela_model.dart';

void main() {
  group('RolePermissaoScreen - Telas Dinâmicas (Card #493)', () {
    setUp(() {
      // Setup inicial se necessário
      AuthUtility.userInfo = null;
    });

    test('Tela model serializa e deserializa corretamente', () {
      // Arrange
      final tela = Tela(
        id: 1,
        nome: 'nfeEntrada',
        descricao: 'NF-e Entrada',
      );

      // Act
      final json = tela.toJson();
      final telaRecuperada = Tela.fromJson(json);

      // Assert
      expect(telaRecuperada.id, tela.id);
      expect(telaRecuperada.nome, tela.nome);
      expect(telaRecuperada.descricao, tela.descricao);
    });

    test('RolePermissao pode ser criado com nome de tela dinamico', () {
      // Arrange
      final telaNomeDinamico = 'nfeEntrada';
      final rolePermissao = RolePermissao(
        id: 0,
        roleId: 1,
        roleKey: 'admin',
        roleDescription: 'Administrador',
        telaNome: telaNomeDinamico,
        podeVer: true,
        podeInserir: true,
        podeEditar: true,
        podeDeletar: true,
        podeBaixar: true,
      );

      // Assert
      expect(rolePermissao.telaNome, 'nfeEntrada');
      expect(rolePermissao.podeVer, true);
      expect(rolePermissao.podeInserir, true);
    });

    test('RolePermissao.copyWith atualiza permissoes corretamente', () {
      // Arrange
      final original = RolePermissao(
        id: 1,
        roleId: 1,
        roleKey: 'usuario',
        roleDescription: 'Usuário',
        telaNome: 'dashboard',
        podeVer: true,
        podeInserir: false,
        podeEditar: false,
        podeDeletar: false,
        podeBaixar: false,
      );

      // Act
      final atualizado = original.copyWith(podeInserir: true);

      // Assert
      expect(atualizado.podeVer, true);
      expect(atualizado.podeInserir, true);
      expect(atualizado.podeEditar, false);
    });

    test('Lista de telas dinamicas pode ser processada', () {
      // Arrange
      final telas = [
        Tela(id: 1, nome: 'dashboard', descricao: 'Dashboard'),
        Tela(id: 2, nome: 'nfeEntrada', descricao: 'NF-e Entrada'),
        Tela(id: 3, nome: 'relatorios', descricao: 'Relatórios'),
      ];

      // Act
      final nomes = telas.map((t) => t.nome).toList();

      // Assert
      expect(nomes, ['dashboard', 'nfeEntrada', 'relatorios']);
      expect(telas.length, 3);
    });

    test('Normalizacao de nomes de tela funciona corretamente', () {
      // Arrange - simula a normalizacao usada em _permissaoDe()
      String normalizeTelaNome(String s) =>
          s.toLowerCase().replaceAll('_', '');

      // Act
      final norm1 = normalizeTelaNome('nfe_entrada');
      final norm2 = normalizeTelaNome('nfeEntrada');
      final norm3 = normalizeTelaNome('NFE_ENTRADA');

      // Assert - todos devem normalizar para o mesmo valor
      expect(norm1, 'nfeentrada');
      expect(norm2, 'nfeentrada');
      expect(norm3, 'nfeentrada');
      expect(norm1, equals(norm2));
      expect(norm1, equals(norm3));
    });
  });
}
