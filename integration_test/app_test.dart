import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:test_integration_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end test', () {
    testWidgets('toca no botão de ação flutuante e verifica o contador',
            (WidgetTester tester) async {
          // DEBUG: Adiciona um log para confirmar que o teste está sendo executado.
          print("--- INICIANDO TESTE DE INTEGRAÇÃO ---");

          // Inicia o widget principal do app.
          await tester.pumpWidget(const app.MyApp());

          // Aguarda o app carregar.
          await tester.pumpAndSettle();

          // CORREÇÃO: Adiciona uma pequena espera explícita.
          // Às vezes, em ambientes de CI mais lentos, isso ajuda a garantir que a UI
          // esteja completamente pronta antes de interagir com ela.
          await Future.delayed(const Duration(seconds: 2));

          // Verifica se o contador começa em 0.
          expect(find.text('0'), findsOneWidget);
          print("--- VERIFICADO: Contador inicial é 0 ---");

          // Encontra o botão pela sua Key.
          final Finder fab = find.byKey(const Key('increment'));

          // Emula um toque no botão.
          await tester.tap(fab);

          // Aguarda a UI ser atualizada após o toque.
          await tester.pumpAndSettle();
          print("--- AÇÃO: Botão de incremento tocado ---");

          // Verifica se o contador foi incrementado para 1.
          expect(find.text('1'), findsOneWidget);
          print("--- VERIFICADO: Contador final é 1 ---");
        });
  });
}

