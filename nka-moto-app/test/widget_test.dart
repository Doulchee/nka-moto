import 'package:flutter_test/flutter_test.dart';
import 'package:nka_moto/main.dart';

void main() {
  testWidgets('app démarre', (tester) async {
    await tester.pumpWidget(const NkaMotoApp());
  });
}
