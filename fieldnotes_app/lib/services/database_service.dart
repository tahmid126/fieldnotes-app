import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/customer_model.dart';
import '../models/site_model.dart';
import '../models/field_note_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  void setDatabaseForTesting(Database? db) {
    _database = db;
  }

  Future<void> createTables(Database db) async {
    await _createDB(db, 1);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fieldnotes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        contact_information TEXT,
        deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sites (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        customer_name TEXT,
        deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE field_notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        location TEXT,
        latitude REAL,
        longitude REAL,
        note_date_time TEXT NOT NULL,
        status TEXT NOT NULL,
        photo_url TEXT,
        site_id TEXT NOT NULL,
        site_name TEXT,
        customer_id TEXT,
        customer_name TEXT,
        deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (site_id) REFERENCES sites (id)
      )
    ''');
  }

  // ================= CUSTOMERS =================

  Future<void> saveCustomer(CustomerModel customer) async {
    final db = await database;
    await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CustomerModel>> getCustomers({bool includeDeleted = false}) async {
    final db = await database;
    final whereClause = includeDeleted ? null : 'deleted = 0';
    final result = await db.query(
      'customers',
      where: whereClause,
      orderBy: 'name ASC',
    );
    return result.map((e) => CustomerModel.fromMap(e)).toList();
  }

  Future<CustomerModel?> getCustomerById(String id) async {
    final db = await database;
    final result = await db.query(
      'customers',
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return CustomerModel.fromMap(result.first);
    }
    return null;
  }

  Future<void> softDeleteCustomer(String id) async {
    final db = await database;
    await db.update(
      'customers',
      {
        'deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= SITES =================

  Future<void> saveSite(SiteModel site) async {
    final db = await database;
    // enrich customer name if missing
    String? customerName = site.customerName;
    if (customerName == null || customerName.isEmpty) {
      final customer = await getCustomerById(site.customerId);
      customerName = customer?.name;
    }

    final toSave = site.copyWith(customerName: customerName);
    await db.insert(
      'sites',
      toSave.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SiteModel>> getSites({String? customerId, bool includeDeleted = false}) async {
    final db = await database;
    String whereClause = includeDeleted ? '1=1' : 'deleted = 0';
    List<dynamic> whereArgs = [];

    if (customerId != null) {
      whereClause += ' AND customer_id = ?';
      whereArgs.add(customerId);
    }

    final result = await db.query(
      'sites',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );
    return result.map((e) => SiteModel.fromMap(e)).toList();
  }

  Future<SiteModel?> getSiteById(String id) async {
    final db = await database;
    final result = await db.query(
      'sites',
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return SiteModel.fromMap(result.first);
    }
    return null;
  }

  Future<void> softDeleteSite(String id) async {
    final db = await database;
    await db.update(
      'sites',
      {
        'deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= FIELD NOTES =================

  Future<void> saveNote(FieldNoteModel note) async {
    final db = await database;
    // enrich site and customer names
    String? siteName = note.siteName;
    String? customerId = note.customerId;
    String? customerName = note.customerName;

    if (siteName == null || siteName.isEmpty) {
      final site = await getSiteById(note.siteId);
      if (site != null) {
        siteName = site.name;
        customerId = site.customerId;
        customerName = site.customerName;
      }
    }

    final toSave = note.copyWith(
      siteName: siteName,
      customerId: customerId,
      customerName: customerName,
    );

    await db.insert(
      'field_notes',
      toSave.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FieldNoteModel>> getNotes({
    String? status,
    String? siteId,
    String? searchQuery,
    bool includeDeleted = false,
  }) async {
    final db = await database;
    String sql = '''
      SELECT 
        fn.id,
        fn.title,
        fn.description,
        fn.location,
        fn.latitude,
        fn.longitude,
        fn.note_date_time,
        fn.status,
        fn.photo_url,
        fn.site_id,
        COALESCE(fn.site_name, s.name) AS site_name,
        COALESCE(fn.customer_id, s.customer_id, c.id) AS customer_id,
        COALESCE(fn.customer_name, s.customer_name, c.name) AS customer_name,
        fn.deleted,
        fn.created_at,
        fn.updated_at,
        fn.is_synced
      FROM field_notes fn
      LEFT JOIN sites s ON fn.site_id = s.id
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE ${includeDeleted ? '1=1' : 'fn.deleted = 0'}
    ''';
    List<dynamic> whereArgs = [];

    if (status != null && status.isNotEmpty && status != 'ALL') {
      sql += ' AND UPPER(fn.status) = ?';
      whereArgs.add(status.toUpperCase());
    }

    if (siteId != null && siteId.isNotEmpty) {
      sql += ' AND fn.site_id = ?';
      whereArgs.add(siteId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      sql += '''
        AND (
          LOWER(fn.title) LIKE ? OR
          (fn.description IS NOT NULL AND LOWER(fn.description) LIKE ?) OR
          (fn.location IS NOT NULL AND LOWER(fn.location) LIKE ?) OR
          (s.name IS NOT NULL AND LOWER(s.name) LIKE ?) OR
          (fn.site_name IS NOT NULL AND LOWER(fn.site_name) LIKE ?) OR
          (c.name IS NOT NULL AND LOWER(c.name) LIKE ?) OR
          (fn.customer_name IS NOT NULL AND LOWER(fn.customer_name) LIKE ?)
        )
      ''';
      whereArgs.addAll([q, q, q, q, q, q, q]);
    }

    sql += ' ORDER BY fn.note_date_time DESC';

    final result = await db.rawQuery(sql, whereArgs);
    return result.map((e) => FieldNoteModel.fromMap(e)).toList();
  }

  Future<FieldNoteModel?> getNoteById(String id) async {
    final db = await database;
    final sql = '''
      SELECT 
        fn.id,
        fn.title,
        fn.description,
        fn.location,
        fn.latitude,
        fn.longitude,
        fn.note_date_time,
        fn.status,
        fn.photo_url,
        fn.site_id,
        COALESCE(fn.site_name, s.name) AS site_name,
        COALESCE(fn.customer_id, s.customer_id, c.id) AS customer_id,
        COALESCE(fn.customer_name, s.customer_name, c.name) AS customer_name,
        fn.deleted,
        fn.created_at,
        fn.updated_at,
        fn.is_synced
      FROM field_notes fn
      LEFT JOIN sites s ON fn.site_id = s.id
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE fn.id = ? AND fn.deleted = 0
    ''';
    final result = await db.rawQuery(sql, [id]);
    if (result.isNotEmpty) {
      return FieldNoteModel.fromMap(result.first);
    }
    return null;
  }

  Future<void> softDeleteNote(String id) async {
    final db = await database;
    await db.update(
      'field_notes',
      {
        'deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= OFFLINE SYNC HELPERS =================

  Future<List<CustomerModel>> getUnsyncedCustomers() async {
    final db = await database;
    final result = await db.query('customers', where: 'is_synced = 0');
    return result.map((e) => CustomerModel.fromMap(e)).toList();
  }

  Future<List<SiteModel>> getUnsyncedSites() async {
    final db = await database;
    final result = await db.query('sites', where: 'is_synced = 0');
    return result.map((e) => SiteModel.fromMap(e)).toList();
  }

  Future<List<FieldNoteModel>> getUnsyncedNotes() async {
    final db = await database;
    final result = await db.query('field_notes', where: 'is_synced = 0');
    return result.map((e) => FieldNoteModel.fromMap(e)).toList();
  }

  Future<void> batchSaveServerData({
    required List<CustomerModel> customers,
    required List<SiteModel> sites,
    required List<FieldNoteModel> notes,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final c in customers) {
        await txn.insert(
          'customers',
          c.copyWith(isSynced: true).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final s in sites) {
        await txn.insert(
          'sites',
          s.copyWith(isSynced: true).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final n in notes) {
        await txn.insert(
          'field_notes',
          n.copyWith(isSynced: true).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('field_notes');
    await db.delete('sites');
    await db.delete('customers');
  }
}
