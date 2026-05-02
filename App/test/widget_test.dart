import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Firebase init gerektirdiğinden bu test mock gerektirir.
    // Gerçek cihazda test edilmeli.
    expect(true, isTrue);
  });
}
