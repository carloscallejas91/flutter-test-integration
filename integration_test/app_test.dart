import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// 1. AJUSTE O CAMINHO ABAIXO PARA O SEU main.dart
import 'package:test_integration_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Teste de ponta a ponta do Contador', () {
    testWidgets(
      'App inicia e mostra o contador em 0',
          (WidgetTester tester) async {
        // Inicia a sua aplicação.
        app.main();

        // Aguarda que a UI se estabilize (não haja mais frames a serem desenhados).
        // Este é o método preferido quando não há animações infinitas.
        await tester.pump(Duration(seconds: 10));

        // Verificação do estado inicial:
        // Confirma que o texto inicial está visível.
        expect(find.text('You have pushed the button this many times:'), findsOneWidget);
        // Confirma que o contador começa em '0'.
        expect(find.text('0'), findsOneWidget);
        // Garante que o contador não começa em '1'.
        expect(find.text('1'), findsNothing);
      },
    );

    testWidgets(
      'Tocar no botão incrementa o contador para 1',
          (WidgetTester tester) async {
        app.main();
        await tester.pump(Duration(seconds: 10));

        // Passo 1: Encontra o botão através da sua Key.
        final Finder button = find.byKey(const Key('increment_button'));

        // Passo 2: Simula um toque no botão.
        await tester.tap(button);

        // Passo 3: Aguarda que a UI se atualize após o toque.
        await tester.pumpAndSettle();

        // Verificação do novo estado:
        // Confirma que o contador '0' já não está no ecrã.
        expect(find.text('0'), findsNothing);
        // Confirma que o contador foi atualizado para '1'.
        expect(find.text('1'), findsOneWidget);
      },
    );
  });
}

