import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// 1. DESCOMENTE A LINHA ABAIXO E AJUSTE O CAMINHO PARA O SEU main.dart
import 'package:test_integration_app/main.dart' as app;
import 'package:test_integration_app/main.dart';

void main() {
  // Garante que o binding de integração está inicializado.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // O FlutterTestPlayer ajuda a prevenir ANRs no Firebase Test Lab.
  // binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Teste de ponta a ponta', () {
    testWidgets('App inicia e mostra a página inicial', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const MyHomePage(title: 'Flutter Demo Home Page'),
        ),
      );

      // Aguarda que a aplicação se estabilize (não haja mais frames a serem desenhados).
      await tester.pumpAndSettle();

      // 3. ALTERE O TEXTO ABAIXO para um texto que realmente apareça no ecrã inicial da sua app.
      //    Este é o ponto de verificação do seu teste.
      expect(find.text('Flutter Demo Home Page'), findsOneWidget);
    });
  });
}
