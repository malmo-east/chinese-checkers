import 'package:flutter_test/flutter_test.dart';

import 'package:chinese_checkers/main.dart';

void main() {
  testWidgets('home screen renders title and play button', (tester) async {
    await tester.pumpWidget(const ChineseCheckersApp());
    await tester.pump();

    expect(find.text('ИГРАТЬ'), findsOneWidget);
    expect(find.textContaining('КИТАЙСКИЕ'), findsOneWidget);
  });
}
