import 'package:flutter_test/flutter_test.dart';
import 'package:yerepouni_news_flutter/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const YerepouniApp());
    await tester.pump();
  });
}
