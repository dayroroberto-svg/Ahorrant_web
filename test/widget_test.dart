import 'package:flutter_test/flutter_test.dart';
import 'package:ahorrant_web/main.dart';

void main() {
  testWidgets('AhorrantApp carga la pantalla de inicio correctamente', (WidgetTester tester) async {
    // Construir la app y renderizar
    await tester.pumpWidget(const AhorrantApp());

    // Verificar que se renderiza el título Ahorrant
    expect(find.text('Ahorrant'), findsWidgets);
  });
}
