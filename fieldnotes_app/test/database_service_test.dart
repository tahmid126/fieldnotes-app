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
  });

  tearDown(() async {
    await db.close();
    dbService.setDatabaseForTesting(null);
  });

  group('DatabaseService Customer CRUD & Sync Flags', () {
    test('saveCustomer inserts and getCustomerById returns correct record', () async {
      final customer = CustomerModel(
        id: 'c1',
        name: 'Grameenphone Ltd',
        contactInformation: 'gp@grameenphone.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      await dbService.saveCustomer(customer);
      final retrieved = await dbService.getCustomerById('c1');

      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Grameenphone Ltd');
      expect(retrieved.contactInformation, 'gp@grameenphone.com');
      expect(retrieved.isSynced, false);
    });

    test('update customer updates content and getCustomers returns updated', () async {
      final customer = CustomerModel(
        id: 'c1',
        name: 'Initial Name',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await dbService.saveCustomer(customer);

      final updated = customer.copyWith(name: 'Updated Name', contactInformation: '01711111111');
      await dbService.saveCustomer(updated);

      final list = await dbService.getCustomers();
      expect(list.length, 1);
      expect(list.first.name, 'Updated Name');
      expect(list.first.contactInformation, '01711111111');
    });

    test('softDeleteCustomer marks deleted=1 and is_synced=0', () async {
      final customer = CustomerModel(
        id: 'c1',
        name: 'Robi Axiata',
        isSynced: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await dbService.saveCustomer(customer);

      await dbService.softDeleteCustomer('c1');

      // Regular getCustomers excludes deleted
      final activeList = await dbService.getCustomers();
      expect(activeList, isEmpty);

      // getUnsyncedCustomers should include it so deletion syncs to server
      final unsynced = await dbService.getUnsyncedCustomers();
      expect(unsynced.length, 1);
      expect(unsynced.first.deleted, true);
      expect(unsynced.first.isSynced, false);
    });
  });

  group('DatabaseService Site CRUD & Relations', () {
    test('saveSite enriches customerName automatically from customer table', () async {
      await dbService.saveCustomer(CustomerModel(
        id: 'cust-gp',
        name: 'Grameenphone',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final site = SiteModel(
        id: 'site-dhk-1',
        name: 'GP House Basundhara',
        address: 'Plot 3, Baridhara',
        customerId: 'cust-gp',
        // customerName omitted intentionally
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.saveSite(site);

      final savedSite = await dbService.getSiteById('site-dhk-1');
      expect(savedSite, isNotNull);
      expect(savedSite!.customerName, 'Grameenphone');
    });

    test('getSites with customerId filter only returns sites for that customer', () async {
      await dbService.saveSite(SiteModel(
        id: 's1',
        name: 'Site 1',
        address: 'Addr 1',
        customerId: 'cust-A',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await dbService.saveSite(SiteModel(
        id: 's2',
        name: 'Site 2',
        address: 'Addr 2',
        customerId: 'cust-B',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final custASites = await dbService.getSites(customerId: 'cust-A');
      expect(custASites.length, 1);
      expect(custASites.first.id, 's1');

      final allSites = await dbService.getSites();
      expect(allSites.length, 2);
    });

    test('softDeleteSite excludes site from active list and marks for sync', () async {
      await dbService.saveSite(SiteModel(
        id: 's1',
        name: 'Site 1',
        address: 'Addr 1',
        customerId: 'cust-A',
        isSynced: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await dbService.softDeleteSite('s1');

      final active = await dbService.getSites();
      expect(active, isEmpty);

      final unsynced = await dbService.getUnsyncedSites();
      expect(unsynced.length, 1);
      expect(unsynced.first.deleted, true);
    });
  });

  group('DatabaseService Field Notes & Batch Server Sync', () {
    test('saveNote enriches siteName and customerName from sites table', () async {
      await dbService.saveCustomer(CustomerModel(
        id: 'c1',
        name: 'Banglalink',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await dbService.saveSite(SiteModel(
        id: 's1',
        name: 'Tigers Den Gulshan',
        address: 'Gulshan 1',
        customerId: 'c1',
        customerName: 'Banglalink',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final note = FieldNoteModel(
        id: 'n1',
        title: 'Router Firmware Upgrade',
        noteDateTime: DateTime.now(),
        status: 'IN_PROGRESS',
        siteId: 's1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.saveNote(note);

      final saved = await dbService.getNoteById('n1');
      expect(saved, isNotNull);
      expect(saved!.siteName, 'Tigers Den Gulshan');
      expect(saved.customerName, 'Banglalink');
    });

    test('getNotes filters correctly by siteId and status', () async {
      await dbService.saveNote(FieldNoteModel(
        id: 'n1',
        title: 'Note 1',
        noteDateTime: DateTime.now(),
        status: 'DRAFT',
        siteId: 's1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await dbService.saveNote(FieldNoteModel(
        id: 'n2',
        title: 'Note 2',
        noteDateTime: DateTime.now(),
        status: 'COMPLETED',
        siteId: 's1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await dbService.saveNote(FieldNoteModel(
        id: 'n3',
        title: 'Note 3',
        noteDateTime: DateTime.now(),
        status: 'COMPLETED',
        siteId: 's2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final s1Completed = await dbService.getNotes(siteId: 's1', status: 'COMPLETED');
      expect(s1Completed.length, 1);
      expect(s1Completed.first.id, 'n2');
    });

    test('batchSaveServerData stores server entities and marks is_synced=1', () async {
      final now = DateTime.now();

      await dbService.batchSaveServerData(
        customers: [
          CustomerModel(
            id: 'server-c1',
            name: 'Server Customer',
            createdAt: now,
            updatedAt: now,
            isSynced: true,
          )
        ],
        sites: [
          SiteModel(
            id: 'server-s1',
            name: 'Server Site',
            address: 'Server Address',
            customerId: 'server-c1',
            createdAt: now,
            updatedAt: now,
            isSynced: true,
          )
        ],
        notes: [
          FieldNoteModel(
            id: 'server-n1',
            title: 'Server Note',
            noteDateTime: now,
            status: 'COMPLETED',
            siteId: 'server-s1',
            createdAt: now,
            updatedAt: now,
            isSynced: true,
          )
        ],
      );

      final customers = await dbService.getCustomers();
      expect(customers.any((c) => c.id == 'server-c1'), isTrue);

      final sites = await dbService.getSites();
      expect(sites.any((s) => s.id == 'server-s1'), isTrue);

      final notes = await dbService.getNotes();
      expect(notes.any((n) => n.id == 'server-n1'), isTrue);

      // Verify none of them are marked as unsynced
      final unsyncedCustomers = await dbService.getUnsyncedCustomers();
      final unsyncedSites = await dbService.getUnsyncedSites();
      final unsyncedNotes = await dbService.getUnsyncedNotes();

      expect(unsyncedCustomers, isEmpty);
      expect(unsyncedSites, isEmpty);
      expect(unsyncedNotes, isEmpty);
    });
  });
}
