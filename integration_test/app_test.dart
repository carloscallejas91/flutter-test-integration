import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:test_integration_app/main.dart' as app;

void main() {
  // Garante que o binding de testes de integração seja inicializado.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Teste de ponta a ponta (end-to-end)', () {
    testWidgets('Verifica se o contador incrementa ao tocar no botão',
            (WidgetTester tester) async {
          // Inicia o seu aplicativo.
          app.main();
          // Aguarda o app ser totalmente renderizado.
          await tester.pumpAndSettle();

          // Verifica se o contador começa em '0'.
          expect(find.text('0'), findsOneWidget);

          // Encontra o FloatingActionButton (botão flutuante) pela sua Key.
          final Finder fab = find.byKey(const Key('increment_button'));

          // Simula um toque no botão.
          await tester.tap(fab);

          // Aguarda a reconstrução da UI após o toque.
          await tester.pumpAndSettle();

          // Verifica se o contador foi incrementado para '1'.
          expect(find.text('1'), findsOneWidget);
        });
  });
}
