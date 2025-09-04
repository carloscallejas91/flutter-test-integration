import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:test_integration_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end test', () {
    testWidgets('toca no botão de ação flutuante e verifica o contador',
            (WidgetTester tester) async {
          // CORREÇÃO: Inicia o widget principal do app em vez de chamar app.main().
          // Esta abordagem é mais estável e recomendada para ambientes de teste.
          await tester.pumpWidget(const app.MyApp());

          // Aguarda o app carregar e todas as animações iniciais terminarem.
          await tester.pumpAndSettle();

          // Verifica se o contador começa em 0.
          expect(find.text('0'), findsOneWidget);

          // Encontra o botão pela sua Key.
          final Finder fab = find.byKey(const Key('increment'));

          // Emula um toque no botão.
          await tester.tap(fab);

          // Aguarda a UI ser atualizada após o toque.
          await tester.pumpAndSettle();

          // Verifica se o contador foi incrementado para 1.
          expect(find.text('1'), findsOneWidget);
        });
  });
}

