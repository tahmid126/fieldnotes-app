import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fieldnotes_app/models/customer_model.dart';
import 'package:fieldnotes_app/models/site_model.dart';
import 'package:fieldnotes_app/models/field_note_model.dart';
import 'package:fieldnotes_app/services/database_service.dart';

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

    // Seed test customer
    await dbService.saveCustomer(CustomerModel(
      id: 'cust-1',
      name: 'Acme Telecom',
      contactInformation: 'contact@acme.com',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // Seed test sites
    await dbService.saveSite(SiteModel(
      id: 'site-1',
      name: 'Dhaka Tower A',
      address: 'Gulshan 2, Dhaka',
      customerId: 'cust-1',
      customerName: 'Acme Telecom',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await dbService.saveSite(SiteModel(
      id: 'site-2',
      name: 'Chittagong Hub',
      address: 'Agrabad, Chittagong',
      customerId: 'cust-1',
      customerName: 'Acme Telecom',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // Seed test notes
    await dbService.saveNote(FieldNoteModel(
      id: 'note-1',
      title: 'Fiber Cable Inspection',
      description: 'Found bent optical patch cord near rack 4',
      location: 'Server Room B1',
      noteDateTime: DateTime.now().subtract(const Duration(hours: 2)),
      status: 'IN_PROGRESS',
      siteId: 'site-1',
      siteName: 'Dhaka Tower A',
      customerId: 'cust-1',
      customerName: 'Acme Telecom',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await dbService.saveNote(FieldNoteModel(
      id: 'note-2',
      title: 'Power Backup Generator Test',
      description: 'Diesel levels nominal, battery at 100%',
      location: 'Basement Generator Yard',
      noteDateTime: DateTime.now().subtract(const Duration(hours: 1)),
      status: 'COMPLETED',
      siteId: 'site-1',
      siteName: 'Dhaka Tower A',
      customerId: 'cust-1',
      customerName: 'Acme Telecom',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    await dbService.saveNote(FieldNoteModel(
      id: 'note-3',
      title: 'Antenna Alignment Survey',
      description: 'Microwave dish realignment scheduled',
      location: 'Rooftop Mast',
      noteDateTime: DateTime.now(),
      status: 'DRAFT',
      siteId: 'site-2',
      siteName: 'Chittagong Hub',
      customerId: 'cust-1',
      customerName: 'Acme Telecom',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  tearDown(() async {
    await db.close();
    dbService.setDatabaseForTesting(null);
  });

  group('Field Notes Search & Filter Tests', () {
    test('Empty or null query returns all non-deleted notes', () async {
      final allNotes = await dbService.getNotes();
      expect(allNotes.length, 3);

      final emptyNotes = await dbService.getNotes(searchQuery: '   ');
      expect(emptyNotes.length, 3);
    });

    test('Search by title substring (case-insensitive)', () async {
      final resultsUpper = await dbService.getNotes(searchQuery: 'FIBER');
      expect(resultsUpper.length, 1);
      expect(resultsUpper.first.id, 'note-1');

      final resultsLower = await dbService.getNotes(searchQuery: 'generator');
      expect(resultsLower.length, 1);
      expect(resultsLower.first.id, 'note-2');
    });

    test('Search by description snippet', () async {
      final results = await dbService.getNotes(searchQuery: 'optical patch cord');
      expect(results.length, 1);
      expect(results.first.id, 'note-1');

      final resultsDiesel = await dbService.getNotes(searchQuery: 'diesel');
      expect(resultsDiesel.length, 1);
      expect(resultsDiesel.first.id, 'note-2');
    });

    test('Search by location substring', () async {
      final results = await dbService.getNotes(searchQuery: 'Rooftop');
      expect(results.length, 1);
      expect(results.first.id, 'note-3');

      final resultsBasement = await dbService.getNotes(searchQuery: 'basement');
      expect(resultsBasement.length, 1);
      expect(resultsBasement.first.id, 'note-2');
    });

    test('Search by site name', () async {
      final dhakaResults = await dbService.getNotes(searchQuery: 'Dhaka Tower');
      expect(dhakaResults.length, 2);

      final ctgResults = await dbService.getNotes(searchQuery: 'Chittagong Hub');
      expect(ctgResults.length, 1);
      expect(ctgResults.first.id, 'note-3');
    });

    test('Search by customer name', () async {
      final results = await dbService.getNotes(searchQuery: 'Acme Telecom');
      expect(results.length, 3);
    });

    test('Combined filter: status filter + search query', () async {
      // Both note-1 and note-2 are at Dhaka Tower, but note-1 is IN_PROGRESS and note-2 is COMPLETED
      final completedAtDhaka = await dbService.getNotes(
        status: 'COMPLETED',
        searchQuery: 'Dhaka',
      );
      expect(completedAtDhaka.length, 1);
      expect(completedAtDhaka.first.id, 'note-2');

      final draftAtDhaka = await dbService.getNotes(
        status: 'DRAFT',
        searchQuery: 'Dhaka',
      );
      expect(draftAtDhaka.length, 0);
    });

    test('Non-matching query returns empty list', () async {
      final results = await dbService.getNotes(searchQuery: 'nonexistent xyz 12345');
      expect(results, isEmpty);
    });

    test('Soft deleted notes are not returned in search', () async {
      await dbService.softDeleteNote('note-1');
      final results = await dbService.getNotes(searchQuery: 'Fiber');
      expect(results, isEmpty);
    });
  });
}
