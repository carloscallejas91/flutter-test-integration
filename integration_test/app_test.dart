import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
// Importe o ficheiro principal da sua aplicação (geralmente main.dart)
// import 'package:test_integration_app/main.dart' as app;

void main() {
  // Garante que o binding de integração está inicializado.
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // O FlutterTestPlayer ajuda a prevenir ANRs no Firebase Test Lab.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Teste de ponta a ponta', () {
    testWidgets('App inicia sem crashar', (WidgetTester tester) async {
      // Inicia a sua aplicação.
      // app.main();

      // Aguarda que a aplicação se estabilize (não haja mais frames a serem desenhados).
      await tester.pumpAndSettle();

      // Um teste simples para verificar se algo está no ecrã.
      // Altere 'Flutter Demo Home Page' para um texto que apareça no ecrã inicial da sua app.
      expect(find.text('Flutter Demo Home Page'), findsOneWidget);
    });
  });
}
