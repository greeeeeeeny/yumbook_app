import 'package:flutter_test/flutter_test.dart';
import 'package:yumbook_app/main.dart';

void main() {
  testWidgets('Yumbook app builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const YumbookApp());

    expect(find.byType(YumbookApp), findsOneWidget);
  });
}