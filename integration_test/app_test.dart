import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:test_integration_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Teste de ponta a ponta do Contador', () {
    testWidgets(
      'Tocar no botão incrementa o contador - Versão de Depuração',
          (WidgetTester tester) async {
        // As mensagens de print aparecerão no log do Firebase Test Lab
        print("--- INÍCIO DO TESTE ---");

        // Inicia a sua aplicação.
        app.main();
        print("--- app.main() executado ---");

        // Vamos usar um pump com duração para dar tempo à app de carregar.
        // Aumentei para 15 segundos para garantir.
        await tester.pump(const Duration(seconds: 15));
        print("--- Aguardou 15 segundos ---");

        // Verificação de Depuração 1: A página principal foi renderizada?
        // Esta é uma verificação mais robusta do que procurar por texto.
        final homePageFinder = find.byType(MyHomePage);
        expect(homePageFinder, findsOneWidget, reason: "A página MyHomePage não foi encontrada.");
        print("--- Verificação 1 (MyHomePage) SUCESSO ---");

        // Verificação 2: O contador inicial está visível?
        expect(find.text('0'), findsOneWidget, reason: "O texto '0' inicial não foi encontrado.");
        print("--- Verificação 2 (Texto '0') SUCESSO ---");

        // Interação
        await tester.tap(find.byKey(const Key('increment_button')));
        print("--- Botão de incremento tocado ---");

        // Aguarda a atualização da UI. Se falhar aqui, o problema é pós-toque.
        await tester.pumpAndSettle();
        print("--- pumpAndSettle após o toque executado ---");

        // Verificação Final
        expect(find.text('1'), findsOneWidget, reason: "O texto '1' após o incremento não foi encontrado.");
        print("--- Verificação 3 (Texto '1') SUCESSO ---");

        print("--- FIM DO TESTE ---");
      },
    );
  });
}

