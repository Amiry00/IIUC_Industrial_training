import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cinema/main.dart';

void main() {
  setUp(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    GetIt.instance.reset();
    setupDependencies();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CinemaApp());
    expect(find.text('CineVault'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
