import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/generic_grid_windows_screen.dart'
    as windows;
import 'package:task_manager_flutter/widgets/generic_grid_screen.dart' as web;

// Regressão card #458: ao selecionar uma imagem no campo de upload dentro
// do dialog "Editar item", o arquivo nunca aparecia na tela. Causa raiz:
// showDialog(builder: (ctx) => _buildForm(...)) sem StatefulBuilder — o
// Dialog é construído uma única vez na abertura, então mutar o fileCache
// depois (ao selecionar/remover arquivo) não reconstrói o dialog. O fix
// passa um callback onFileChanged (ligado a StatefulBuilder.setState) até
// _buildFileField/_selectFiles, chamado após cada mutação do fileCache.
//
// Este teste não mocka FilePicker.pickFiles (canal de plataforma) — em vez
// disso, exercita o botão de remover (que não depende do picker) para
// confirmar que o callback onFileChanged é de fato invocado a partir do
// widget construído por FieldFactory.buildField.
void main() {
  testWidgets(
      'windows: onFileChanged é chamado ao remover arquivo do campo FieldType.file',
      (tester) async {
    var callbackCount = 0;
    final controller = TextEditingController(text: 'foto.png');
    final fileCache = <String, List<PlatformFile>>{
      'foto': [PlatformFile(name: 'foto.png', size: 100, bytes: null)],
    };
    final config = windows.FieldConfigWindows(
      label: 'Foto',
      fieldName: 'foto',
      fieldType: windows.FieldType.file,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => windows.FieldFactory.buildField(
            config: config,
            controller: controller,
            context: context,
            fileCache: fileCache,
            dropdownCache: const {},
            onFileChanged: () => callbackCount++,
          ),
        ),
      ),
    ));

    expect(find.text('foto.png'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();

    expect(callbackCount, 1);
    expect(fileCache['foto'], isEmpty);
    expect(controller.text, '');
  });

  testWidgets(
      'web: onFileChanged é chamado ao remover arquivo do campo FieldType.file',
      (tester) async {
    var callbackCount = 0;
    final controller = TextEditingController(text: 'foto.png');
    final fileCache = <String, List<PlatformFile>>{
      'foto': [PlatformFile(name: 'foto.png', size: 100, bytes: null)],
    };
    final config = web.FieldConfig(
      label: 'Foto',
      fieldName: 'foto',
      fieldType: web.FieldType.file,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => web.FieldFactory.buildField(
            config: config,
            controller: controller,
            context: context,
            fileCache: fileCache,
            dropdownCache: const {},
            onFileChanged: () => callbackCount++,
          ),
        ),
      ),
    ));

    expect(find.text('foto.png'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();

    expect(callbackCount, 1);
    expect(fileCache['foto'], isEmpty);
    expect(controller.text, '');
  });
}
