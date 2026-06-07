import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/main.dart';
import 'package:frontend/providers/quiz_provider.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => QuizProvider())],
        child: MyApp(),
      ),
    );

    expect(find.text('AdaptIQ Quiz'), findsOneWidget);
  });
}
