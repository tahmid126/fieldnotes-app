import 'package:flutter_test/flutter_test.dart';
import 'package:fieldnotes_app/models/customer_model.dart';
import 'package:fieldnotes_app/models/site_model.dart';
import 'package:fieldnotes_app/models/field_note_model.dart';

void main() {
  group('CustomerModel Serialization & Logic Tests', () {
    final now = DateTime.now();

    test('CustomerModel toMap and fromMap match SQLite schema', () {
      final customer = CustomerModel(
        id: 'cust-101',
        name: 'Apex Infrastructure',
        contactInformation: '+8801700000000, info@apex.com',
        deleted: false,
        createdAt: now,
        updatedAt: now,
        isSynced: true,
      );

      final map = customer.toMap();
      expect(map['id'], 'cust-101');
      expect(map['name'], 'Apex Infrastructure');
      expect(map['contact_information'], '+8801700000000, info@apex.com');
      expect(map['deleted'], 0);
      expect(map['is_synced'], 1);

      final fromMapCustomer = CustomerModel.fromMap(map);
      expect(fromMapCustomer.id, customer.id);
      expect(fromMapCustomer.name, customer.name);
      expect(fromMapCustomer.contactInformation, customer.contactInformation);
      expect(fromMapCustomer.deleted, false);
      expect(fromMapCustomer.isSynced, true);
    });

    test('CustomerModel toJson and fromJson match Server API format', () {
      final serverJson = {
        'id': 'cust-202',
        'name': 'Beximco Telecom',
        'contactInformation': 'beximco@contact.com',
        'deleted': false,
        'createdAt': '2026-10-10T12:00:00.000Z',
        'updatedAt': '2026-10-10T14:30:00.000Z',
      };

      final customer = CustomerModel.fromJson(serverJson);
      expect(customer.id, 'cust-202');
      expect(customer.name, 'Beximco Telecom');
      expect(customer.isSynced, true); // Server models are marked as synced

      final outJson = customer.toSyncJson();
      expect(outJson['id'], 'cust-202');
      expect(outJson['name'], 'Beximco Telecom');
      expect(outJson['contactInformation'], 'beximco@contact.com');
    });

    test('CustomerModel copyWith preserves unmodified fields', () {
      final original = CustomerModel(
        id: 'c1',
        name: 'Alpha',
        createdAt: now,
        updatedAt: now,
      );

      final modified = original.copyWith(name: 'Beta', isSynced: false);
      expect(modified.id, 'c1');
      expect(modified.name, 'Beta');
      expect(modified.isSynced, false);
      expect(modified.createdAt, original.createdAt);
    });
  });

  group('SiteModel Serialization & Logic Tests', () {
    final now = DateTime.now();

    test('SiteModel toMap and fromMap match SQLite schema', () {
      final site = SiteModel(
        id: 'site-301',
        name: 'Motijheel Central Exchange',
        address: '10 Dilkusha C/A, Dhaka',
        customerId: 'cust-101',
        customerName: 'Apex Infrastructure',
        deleted: false,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );

      final map = site.toMap();
      expect(map['id'], 'site-301');
      expect(map['name'], 'Motijheel Central Exchange');
      expect(map['address'], '10 Dilkusha C/A, Dhaka');
      expect(map['customer_id'], 'cust-101');
      expect(map['customer_name'], 'Apex Infrastructure');
      expect(map['deleted'], 0);
      expect(map['is_synced'], 0);

      final restored = SiteModel.fromMap(map);
      expect(restored.id, site.id);
      expect(restored.name, site.name);
      expect(restored.customerName, 'Apex Infrastructure');
      expect(restored.isSynced, false);
    });

    test('SiteModel fromJson gracefully handles missing optional customerName', () {
      final json = {
        'id': 'site-302',
        'name': 'Gulshan Hub',
        'address': 'Road 11, Gulshan',
        'customerId': 'cust-101',
        'customerName': null,
        'deleted': false,
        'createdAt': '2026-10-10T12:00:00.000Z',
        'updatedAt': '2026-10-10T12:00:00.000Z',
      };

      final site = SiteModel.fromJson(json);
      expect(site.id, 'site-302');
      expect(site.customerName, isNull);
      expect(site.isSynced, true);
    });
  });

  group('FieldNoteModel Serialization & Edge Cases Tests', () {
    final now = DateTime.now();

    test('FieldNoteModel handles complete attributes correctly', () {
      final note = FieldNoteModel(
        id: 'fn-401',
        title: 'Generator Load Test',
        description: 'Passed 8-hour continuous test on full load',
        location: 'Basement Floor 2',
        latitude: 23.7937,
        longitude: 90.4066,
        noteDateTime: now,
        status: 'COMPLETED',
        photoUrl: 'http://localhost:8080/uploads/gen_test.jpg',
        siteId: 'site-301',
        siteName: 'Motijheel Central Exchange',
        customerId: 'cust-101',
        customerName: 'Apex Infrastructure',
        deleted: false,
        createdAt: now,
        updatedAt: now,
        isSynced: true,
      );

      final map = note.toMap();
      expect(map['id'], 'fn-401');
      expect(map['latitude'], 23.7937);
      expect(map['longitude'], 90.4066);
      expect(map['status'], 'COMPLETED');
      expect(map['photo_url'], 'http://localhost:8080/uploads/gen_test.jpg');

      final fromMapNote = FieldNoteModel.fromMap(map);
      expect(fromMapNote.latitude, 23.7937);
      expect(fromMapNote.longitude, 90.4066);
      expect(fromMapNote.status, 'COMPLETED');
    });

    test('FieldNoteModel handles nullable coordinates, photo and descriptions', () {
      final note = FieldNoteModel(
        id: 'fn-402',
        title: 'Quick Visual Inspection',
        description: null,
        location: null,
        latitude: null,
        longitude: null,
        noteDateTime: now,
        status: 'DRAFT',
        photoUrl: null,
        siteId: 'site-301',
        createdAt: now,
        updatedAt: now,
      );

      final map = note.toMap();
      expect(map['description'], isNull);
      expect(map['location'], isNull);
      expect(map['latitude'], isNull);
      expect(map['longitude'], isNull);
      expect(map['photo_url'], isNull);

      final restored = FieldNoteModel.fromMap(map);
      expect(restored.description, isNull);
      expect(restored.latitude, isNull);
      expect(restored.longitude, isNull);
      expect(restored.photoUrl, isNull);

      final json = note.toSyncJson();
      expect(json['title'], 'Quick Visual Inspection');
      expect(json['status'], 'DRAFT');
    });

    test('FieldNoteModel handles string latitude/longitude from backend JSON safely', () {
      final serverJson = {
        'id': 'fn-403',
        'title': 'Microwave Dish Check',
        'description': 'Aligned',
        'location': 'Tower Top',
        'latitude': 23.8103,
        'longitude': 90.4125,
        'noteDateTime': '2026-10-10T15:00:00.000Z',
        'status': 'IN_PROGRESS',
        'photoUrl': null,
        'siteId': 'site-301',
        'siteName': 'Motijheel Central Exchange',
        'customerId': 'cust-101',
        'customerName': 'Apex Infrastructure',
        'deleted': false,
        'createdAt': '2026-10-10T15:00:00.000Z',
        'updatedAt': '2026-10-10T15:00:00.000Z',
      };

      final note = FieldNoteModel.fromJson(serverJson);
      expect(note.latitude, 23.8103);
      expect(note.longitude, 90.4125);
      expect(note.status, 'IN_PROGRESS');
      expect(note.isSynced, true);
    });
  });
}
