import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/recurring_contract_model.dart';
import 'package:task_manager_flutter/screens/contratos/faturar_contratos_state.dart';

void main() {
  test('filtra somente contratos ativos vencendo ate a competencia', () {
    final contratos = [
      RecurringContract(
        contractId: 'CTR-1',
        customerName: 'Cliente 1',
        planName: 'Mensal',
        monthlyValue: 100,
        nextDueDate: DateTime(2026, 8, 10),
        status: 'ACTIVE',
      ),
      RecurringContract(
        contractId: 'CTR-2',
        customerName: 'Cliente 2',
        planName: 'Mensal',
        monthlyValue: 200,
        nextDueDate: DateTime(2026, 9, 1),
        status: 'ACTIVE',
      ),
      RecurringContract(
        contractId: 'CTR-3',
        customerName: 'Cliente 3',
        planName: 'Mensal',
        monthlyValue: 300,
        nextDueDate: DateTime(2026, 8, 20),
        status: 'CANCELLED',
      ),
    ];

    final filtrados = FaturarContratosState.contratosAteCompetencia(
      contratos,
      DateTime(2026, 8),
    );

    expect(filtrados.map((contrato) => contrato.contractId), ['CTR-1']);
    expect(FaturarContratosState.totalMensal(filtrados), 100);
  });
}
