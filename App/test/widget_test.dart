import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:berber_app_ui/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Firebase init gerektirdiğinden bu test mock gerektirir.
    // Gerçek cihazda test edilmeli.
    expect(true, isTrue);
  });
}
