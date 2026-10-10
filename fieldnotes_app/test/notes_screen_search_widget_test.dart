import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fieldnotes_app/blocs/note_bloc.dart';
import 'package:fieldnotes_app/models/field_note_model.dart';
import 'package:fieldnotes_app/services/database_service.dart';
import 'package:fieldnotes_app/screens/notes/notes_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  final dbService = DatabaseService.instance;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await dbService.createTables(db);
    dbService.setDatabaseForTesting(db);

    // Seed notes
    await dbService.saveNote(FieldNoteModel(
      id: 'n1',
      title: 'Solar Panel Voltage Check',
      description: 'Inverter output 230V stable',
      location: 'Site Roof',
      noteDateTime: DateTime.now(),
      status: 'COMPLETED',
      siteId: 's1',
      siteName: 'Solar Farm North',
      customerName: 'Green Power Ltd',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await dbService.saveNote(FieldNoteModel(
      id: 'n2',
      title: 'Water Pipe Pressure Leak',
      description: 'Valve 3 leaking near meter',
      location: 'Basement Room 1',
      noteDateTime: DateTime.now(),
      status: 'IN_PROGRESS',
      siteId: 's2',
      siteName: 'Aqua Utility Central',
      customerName: 'City Water Board',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  tearDown(() async {
    await db.close();
    dbService.setDatabaseForTesting(null);
  });


  testWidgets('NotesScreen renders search bar and filters list dynamically', (WidgetTester tester) async {
    final noteBloc = NoteBloc();
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<NoteBloc>.value(
        value: noteBloc,
        child: const NotesScreen(),
      ),
    ));
    // Wait for real I/O and pump frame
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    // Verify both notes are shown initially
    expect(find.text('Solar Panel Voltage Check'), findsOneWidget);
    expect(find.text('Water Pipe Pressure Leak'), findsOneWidget);

    // Verify search text field exists
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    // Enter query 'Solar' into search bar
    await tester.enterText(searchField, 'Solar');
    // Pump past debounce timer (250ms)
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    // Now only Solar note should appear
    expect(find.text('Solar Panel Voltage Check'), findsOneWidget);
    expect(find.text('Water Pipe Pressure Leak'), findsNothing);

    // Clear icon should be visible
    final clearButton = find.byIcon(Icons.clear);
    expect(clearButton, findsOneWidget);

    // Tap clear button
    await tester.tap(clearButton);
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    // Both notes should reappear
    expect(find.text('Solar Panel Voltage Check'), findsOneWidget);
    expect(find.text('Water Pipe Pressure Leak'), findsOneWidget);

    // Search by site name 'Aqua Utility'
    await tester.enterText(searchField, 'Aqua');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(find.text('Solar Panel Voltage Check'), findsNothing);
    expect(find.text('Water Pipe Pressure Leak'), findsOneWidget);
  });
}
