import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fieldnotes_app/blocs/customer_bloc.dart';
import 'package:fieldnotes_app/blocs/site_bloc.dart';
import 'package:fieldnotes_app/blocs/note_bloc.dart';
import 'package:fieldnotes_app/models/customer_model.dart';
import 'package:fieldnotes_app/models/field_note_model.dart';
import 'package:fieldnotes_app/services/database_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  final dbService = DatabaseService.instance;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await dbService.createTables(db);
    dbService.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await db.close();
    dbService.setDatabaseForTesting(null);
  });

  group('CustomerBloc Unit Tests', () {
    test('LoadCustomers emits CustomerLoading then CustomerLoaded', () async {
      final bloc = CustomerBloc();

      // Seed one customer directly in DB
      await dbService.saveCustomer(CustomerModel(
        id: 'c1',
        name: 'Banglalink Digital',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CustomerLoading>(),
          isA<CustomerLoaded>().having((s) => s.customers.length, 'length', 1),
        ]),
      );

      bloc.add(LoadCustomers());
    });

    test('AddCustomer saves record and reloads list', () async {
      final bloc = CustomerBloc();

      bloc.add(AddCustomer('Teletalk Bangladesh', '01511111111'));

      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<CustomerLoaded>().having(
            (s) => s.customers.any((c) => c.name == 'Teletalk Bangladesh'),
            'has Teletalk',
            true,
          ),
        ),
      );

      // Verify in DB
      final dbCustomers = await dbService.getCustomers();
      expect(dbCustomers.any((c) => c.name == 'Teletalk Bangladesh'), isTrue);
    });

    test('DeleteCustomer soft-deletes and removes from loaded list', () async {
      final customer = CustomerModel(
        id: 'del-c1',
        name: 'To Delete Customer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await dbService.saveCustomer(customer);

      final bloc = CustomerBloc();
      bloc.add(LoadCustomers());

      await expectLater(
        bloc.stream,
        emitsThrough(isA<CustomerLoaded>()),
      );

      bloc.add(DeleteCustomer('del-c1'));

      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<CustomerLoaded>().having(
            (s) => s.customers.any((c) => c.id == 'del-c1'),
            'has deleted',
            false,
          ),
        ),
      );
    });
  });

  group('SiteBloc Unit Tests', () {
    test('AddSite and LoadSites with customer filtering', () async {
      final bloc = SiteBloc();

      bloc.add(AddSite(
        name: 'Dhanmondi Tower',
        address: 'Road 27, Dhanmondi',
        customerId: 'cust-xyz',
        customerName: 'XYZ Enterprise',
      ));

      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<SiteLoaded>().having(
            (s) => s.sites.any((site) => site.name == 'Dhanmondi Tower'),
            'has Dhanmondi Tower',
            true,
          ),
        ),
      );

      // Filter by different customerId should yield empty list
      bloc.add(LoadSites(customerId: 'other-cust'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<SiteLoaded>().having((s) => s.sites, 'sites', isEmpty),
        ),
      );
    });
  });

  group('NoteBloc Unit Tests', () {
    test('AddNote and LoadNotes filters by status correctly', () async {
      final noteBloc = NoteBloc();

      final note = FieldNoteModel(
        id: 'note-draft-1',
        title: 'Battery Cell Replacement',
        noteDateTime: DateTime.now(),
        status: 'DRAFT',
        siteId: 'site-dhk-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      noteBloc.add(AddNote(note));

      await expectLater(
        noteBloc.stream,
        emitsThrough(
          isA<NoteLoaded>().having(
            (s) => s.notes.any((n) => n.id == 'note-draft-1'),
            'has note',
            true,
          ),
        ),
      );

      // Query for COMPLETED should return 0 notes
      noteBloc.add(LoadNotes(status: 'COMPLETED'));
      await expectLater(
        noteBloc.stream,
        emitsThrough(
          isA<NoteLoaded>().having((s) => s.notes, 'completed notes', isEmpty),
        ),
      );

      // Query for DRAFT should return 1 note
      noteBloc.add(LoadNotes(status: 'DRAFT'));
      await expectLater(
        noteBloc.stream,
        emitsThrough(
          isA<NoteLoaded>().having((s) => s.notes.length, 'draft notes count', 1),
        ),
      );
    });
  });
}
