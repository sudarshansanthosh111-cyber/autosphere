import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:typed_data';
import 'api.dart';

class AppState extends ChangeNotifier {
  static const maximumVehicles = 3;
  static const defaultServiceInterval = 5000;

  Database? _db;
  List<Map<String, dynamic>> maintenanceRecords = [];
  List<Map<String, dynamic>> timelineRecords = [];
  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> documents = [];
  List<Map<String, dynamic>> reminders = [];
  Map<String, dynamic>? prediction;
  bool isSyncing = false;
  bool isLoading = true;
  int currentMileage = 10100;
  int? currentVehicleId;

  bool get canAddVehicle => vehicles.length < maximumVehicles;

  int get currentServiceInterval {
    for (final vehicle in vehicles) {
      if (vehicle['id'] == currentVehicleId) {
        return (vehicle['service_interval'] as num?)?.toInt() ??
            defaultServiceInterval;
      }
    }
    return defaultServiceInterval;
  }

  int? get lastServiceMileage {
    for (final record in maintenanceRecords) {
      if (record['type'] == 'service' && record['odometer'] is num) {
        return (record['odometer'] as num).toInt();
      }
    }
    return null;
  }

  Future<void> initDB() async {
    try {
      final dbPath = await getDatabasesPath();
      _db = await openDatabase(
        join(dbPath, 'autosphere.db'),
        version: 4,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await _createSchema(db);
          await _seedGarage(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createSchema(db);
            await db.insert('vehicles', {
              'nickname': 'Family car',
              'make': 'Toyota',
              'model': 'Innova Hycross ZX',
              'year': 2025,
              'fuel_type': 'Hybrid',
              'registration': '',
              'odometer': 10100,
            });
            await db.execute('''
              INSERT INTO activities
                (vehicle_id, date, type, title, cost, category)
              SELECT 1, date, 'service', title, cost, 'Maintenance'
              FROM maintenance
            ''');
          }
          if (oldVersion < 3 && oldVersion >= 2) {
            await db.execute('ALTER TABLE vehicles ADD COLUMN backend_id TEXT');
            await db.execute(
              'ALTER TABLE activities ADD COLUMN backend_id TEXT',
            );
            await _createSettingsTable(db);
          }
          if (oldVersion < 4) {
            final vehicleColumns = await db.rawQuery(
              'PRAGMA table_info(vehicles)',
            );
            if (!vehicleColumns.any(
              (column) => column['name'] == 'service_interval',
            )) {
              await db.execute(
                'ALTER TABLE vehicles ADD COLUMN service_interval INTEGER NOT NULL DEFAULT $defaultServiceInterval',
              );
            }
          }
        },
      );
      await loadVehicles();
      await loadRecords();
      await loadDocuments();
      await loadReminders();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _createSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nickname TEXT NOT NULL,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER,
        fuel_type TEXT,
        registration TEXT,
        odometer INTEGER NOT NULL DEFAULT 0,
        service_interval INTEGER NOT NULL DEFAULT $defaultServiceInterval,
        photo BLOB,
        backend_id TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        cost REAL NOT NULL DEFAULT 0,
        category TEXT,
        odometer INTEGER,
        quantity REAL,
        service_center TEXT,
        details TEXT,
        backend_id TEXT,
        FOREIGN KEY(vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        document_type TEXT NOT NULL,
        file_name TEXT NOT NULL,
        mime_type TEXT,
        data BLOB NOT NULL,
        expires_on TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        reminder_type TEXT NOT NULL,
        due_date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY(vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
    await _createSettingsTable(db);
  }

  Future<void> _createSettingsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        setting_key TEXT PRIMARY KEY,
        setting_value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedGarage(DatabaseExecutor db) async {
    final vehicleId = await db.insert('vehicles', {
      'nickname': 'Hycross',
      'make': 'Toyota',
      'model': 'Innova Hycross ZX',
      'year': 2025,
      'fuel_type': 'Hybrid',
      'registration': '',
      'odometer': 10100,
    });
    await db.insert('activities', {
      'vehicle_id': vehicleId,
      'date': '2026-05-14',
      'type': 'service',
      'title': '10,000 Km Service @ Mandovi Motors',
      'cost': 4500.0,
      'category': 'Maintenance',
      'odometer': 10000,
    });
    await db.insert('activities', {
      'vehicle_id': vehicleId,
      'date': '2026-08-10',
      'type': 'expense',
      'title': '360° Camera System Upgrade',
      'cost': 0.0,
      'category': 'Repairs',
    });
  }

  Future<void> loadVehicles() async {
    if (_db == null) return;
    vehicles = await _db!.query('vehicles', orderBy: 'id');
    if (vehicles.isEmpty) {
      currentVehicleId = null;
      return;
    }
    if (!vehicles.any((vehicle) => vehicle['id'] == currentVehicleId)) {
      currentVehicleId = vehicles.first['id'] as int;
    }
    currentMileage =
        (vehicles.firstWhere(
                  (vehicle) => vehicle['id'] == currentVehicleId,
                )['odometer']
                as num?)
            ?.toInt() ??
        0;
  }

  Future<void> loadRecords() async {
    if (_db == null) return;
    final where = currentVehicleId == null ? null : 'vehicle_id = ?';
    final args = currentVehicleId == null ? null : [currentVehicleId];
    maintenanceRecords = await _db!.query(
      'activities',
      where: where,
      whereArgs: args,
      orderBy: 'date DESC, id DESC',
    );
    timelineRecords = await _db!.query(
      'activities',
      orderBy: 'date DESC, id DESC',
    );
    notifyListeners();
  }

  Future<void> selectVehicle(int id) async {
    currentVehicleId = id;
    await loadVehicles();
    await loadRecords();
    await loadDocuments();
    await loadReminders();
  }

  Future<void> addVehicle({
    required String nickname,
    required String make,
    required String model,
    required int year,
    required String fuelType,
    required String registration,
    required int odometer,
    Uint8List? photo,
  }) async {
    if (!canAddVehicle) {
      throw StateError(
        'A garage can contain at most $maximumVehicles vehicles.',
      );
    }
    final id = await _db!.transaction<int>((transaction) async {
      final count =
          Sqflite.firstIntValue(
            await transaction.rawQuery('SELECT COUNT(*) FROM vehicles'),
          ) ??
          0;
      if (count >= maximumVehicles) {
        throw StateError(
          'A garage can contain at most $maximumVehicles vehicles.',
        );
      }
      return transaction.insert('vehicles', {
        'nickname': nickname,
        'make': make,
        'model': model,
        'year': year,
        'fuel_type': fuelType,
        'registration': registration,
        'odometer': odometer,
        'photo': photo,
      });
    });
    currentVehicleId = id;
    await loadVehicles();
    await loadRecords();
    await loadDocuments();
    await loadReminders();
  }

  Future<void> updateVehicle({
    required int id,
    required String nickname,
    required String make,
    required String model,
    required int year,
    required String fuelType,
    required String registration,
    required int odometer,
    Uint8List? photo,
  }) async {
    final values = <String, Object?>{
      'nickname': nickname,
      'make': make,
      'model': model,
      'year': year,
      'fuel_type': fuelType,
      'registration': registration,
      'odometer': odometer,
    };
    if (photo != null) values['photo'] = photo;
    await _db!.update('vehicles', values, where: 'id = ?', whereArgs: [id]);
    await loadVehicles();
    await loadRecords();
  }

  Future<void> setServiceInterval({
    required int vehicleId,
    required int interval,
  }) async {
    if (interval <= 0) {
      throw ArgumentError.value(interval, 'interval', 'Must be greater than 0');
    }
    final db = _db;
    if (db == null) {
      throw StateError('The database is not initialized.');
    }
    final updated = await db.update(
      'vehicles',
      {'service_interval': interval},
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
    if (updated == 0) {
      throw StateError('Vehicle $vehicleId does not exist.');
    }
    vehicles = vehicles
        .map(
          (vehicle) => vehicle['id'] == vehicleId
              ? {...vehicle, 'service_interval': interval}
              : vehicle,
        )
        .toList();
    notifyListeners();
  }

  Future<void> deleteVehicle(int id) async {
    if (vehicles.length <= 1) return;
    await _db!.delete('vehicles', where: 'id = ?', whereArgs: [id]);
    if (currentVehicleId == id) currentVehicleId = null;
    await loadVehicles();
    await loadRecords();
    await loadDocuments();
    await loadReminders();
  }

  Future<void> deleteRecord(int id) async {
    await _db!.delete('activities', where: 'id = ?', whereArgs: [id]);
    await loadRecords();
  }

  Future<void> addRecord({
    required String title,
    required String date,
    required double cost,
  }) async {
    await addActivity(
      type: 'service',
      title: title,
      date: date,
      cost: cost,
      category: 'Maintenance',
    );
  }

  Future<void> addActivity({
    required String type,
    required String title,
    required String date,
    required double cost,
    String category = 'General',
    int? odometer,
    double? quantity,
    String? serviceCenter,
    String? details,
  }) async {
    final vehicleId = currentVehicleId;
    if (vehicleId == null) return;
    await _db!.insert('activities', {
      'vehicle_id': vehicleId,
      'date': date,
      'type': type,
      'title': title,
      'cost': cost,
      'category': category,
      'odometer': odometer,
      'quantity': quantity,
      'service_center': serviceCenter,
      'details': details,
    });
    if (odometer != null && odometer > currentMileage) {
      await _db!.update(
        'vehicles',
        {'odometer': odometer},
        where: 'id = ?',
        whereArgs: [vehicleId],
      );
      currentMileage = odometer;
      await loadVehicles();
    }
    await loadRecords();
  }

  Future<void> addDocument({
    required String title,
    required String documentType,
    required String fileName,
    required String mimeType,
    required Uint8List data,
    String? expiresOn,
  }) async {
    final vehicleId = currentVehicleId;
    if (vehicleId == null) return;
    await _db!.insert('documents', {
      'vehicle_id': vehicleId,
      'title': title,
      'document_type': documentType,
      'file_name': fileName,
      'mime_type': mimeType,
      'data': data,
      'expires_on': expiresOn,
      'created_at': DateTime.now().toIso8601String(),
    });
    if (expiresOn != null) {
      await _db!.insert('reminders', {
        'vehicle_id': vehicleId,
        'title': '$title renewal',
        'reminder_type': documentType,
        'due_date': expiresOn,
        'notes': 'Renewal date for $title',
      });
    }
    await addActivity(
      type: 'document',
      title: 'Added $documentType',
      date: DateTime.now().toIso8601String(),
      cost: 0,
      category: 'Documents',
    );
    await loadDocuments();
    await loadReminders();
  }

  Future<void> loadDocuments() async {
    if (_db == null || currentVehicleId == null) return;
    documents = await _db!.query(
      'documents',
      columns: [
        'id',
        'vehicle_id',
        'title',
        'document_type',
        'file_name',
        'mime_type',
        'length(data) AS data_size',
        'expires_on',
        'created_at',
      ],
      where: 'vehicle_id = ?',
      whereArgs: [currentVehicleId],
      orderBy: 'created_at DESC',
    );
    notifyListeners();
  }

  Future<Uint8List> readDocumentData(int id) async {
    final db = _db;
    if (db == null) {
      throw StateError('The database is not initialized.');
    }
    final rows = await db.query(
      'documents',
      columns: ['data'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty || rows.first['data'] is! Uint8List) {
      throw StateError('The saved document could not be read.');
    }
    return rows.first['data'] as Uint8List;
  }

  Future<void> deleteDocument(int id) async {
    await _db!.delete('documents', where: 'id = ?', whereArgs: [id]);
    await loadDocuments();
  }

  Future<void> addReminder({
    required String title,
    required String reminderType,
    required String dueDate,
    String? notes,
  }) async {
    final vehicleId = currentVehicleId;
    if (vehicleId == null) return;
    await _db!.insert('reminders', {
      'vehicle_id': vehicleId,
      'title': title,
      'reminder_type': reminderType,
      'due_date': dueDate,
      'notes': notes,
    });
    await addActivity(
      type: 'reminder',
      title: title,
      date: dueDate,
      cost: 0,
      category: reminderType,
    );
    await loadReminders();
  }

  Future<void> loadReminders() async {
    if (_db == null || currentVehicleId == null) return;
    reminders = await _db!.query('reminders', orderBy: 'due_date');
    notifyListeners();
  }

  Future<void> deleteReminder(int id) async {
    await _db!.delete('reminders', where: 'id = ?', whereArgs: [id]);
    await loadReminders();
  }

  Future<void> syncWithCloud() async {
    isSyncing = true;
    cloudSyncMessage = 'Connecting to ${Api.baseUrl}';
    notifyListeners();

    try {
      final userId = await _remoteUserId();
      await Api.getUser(userId);
      var uploadedServices = 0;
      for (final vehicle in vehicles) {
        var backendVehicleId = vehicle['backend_id'] as String?;
        if (backendVehicleId == null || backendVehicleId.isEmpty) {
          final remoteVehicle = await Api.createVehicle(
            userId: userId,
            make: vehicle['make'] as String,
            model: vehicle['model'] as String,
            year: (vehicle['year'] as num?)?.toInt() ?? DateTime.now().year,
            currentMileage: (vehicle['odometer'] as num?)?.toInt() ?? 0,
          );
          backendVehicleId = remoteVehicle['id']?.toString();
          if (backendVehicleId == null || backendVehicleId.isEmpty) {
            throw const ApiException(
              'The backend did not return a vehicle ID.',
            );
          }
          await _db!.update(
            'vehicles',
            {'backend_id': backendVehicleId},
            where: 'id = ?',
            whereArgs: [vehicle['id']],
          );
          vehicles = vehicles
              .map(
                (item) => item['id'] == vehicle['id']
                    ? {...item, 'backend_id': backendVehicleId}
                    : item,
              )
              .toList();
        }

        final serviceRecords = await _db!.query(
          'activities',
          where: 'vehicle_id = ? AND type = ? AND backend_id IS NULL',
          whereArgs: [vehicle['id'], 'service'],
          orderBy: 'date, id',
        );
        for (final record in serviceRecords) {
          final date = DateTime.tryParse(record['date'] as String? ?? '');
          final remoteRecord = await Api.createMaintenance(
            vehicleId: backendVehicleId,
            serviceDate: (date ?? DateTime.now())
                .toIso8601String()
                .split('T')
                .first,
            serviceType: record['title'] as String? ?? 'Maintenance',
            cost: (record['cost'] as num?)?.toDouble() ?? 0,
            mileageAtService:
                (record['odometer'] as num?)?.toInt() ??
                (vehicle['odometer'] as num?)?.toInt() ??
                0,
            notes: (record['details'] as String?)?.isNotEmpty == true
                ? record['details'] as String
                : record['service_center'] as String?,
          );
          final remoteRecordId = remoteRecord['id']?.toString();
          if (remoteRecordId == null || remoteRecordId.isEmpty) {
            throw const ApiException(
              'The backend did not return a service ID.',
            );
          }
          await _db!.update(
            'activities',
            {'backend_id': remoteRecordId},
            where: 'id = ?',
            whereArgs: [record['id']],
          );
          uploadedServices++;
        }
        await Api.getMaintenance(backendVehicleId);
      }

      final selectedVehicle = vehicles.where(
        (vehicle) => vehicle['id'] == currentVehicleId,
      );
      final selectedBackendId = selectedVehicle.isEmpty
          ? null
          : selectedVehicle.first['backend_id'] as String?;
      prediction = selectedBackendId == null
          ? null
          : await Api.getPrediction(selectedBackendId);
      cloudSyncMessage =
          'Synced ${vehicles.length} vehicles and $uploadedServices service records.';
      await loadVehicles();
      await loadRecords();
    } on ApiException catch (error) {
      prediction = null;
      cloudSyncMessage = 'Sync unavailable: ${error.message}';
    } catch (error) {
      prediction = null;
      cloudSyncMessage = 'Could not reach ${Api.baseUrl}';
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  String? cloudSyncMessage;

  Future<String> _remoteUserId() async {
    final saved = await _db!.query(
      'app_settings',
      where: 'setting_key = ?',
      whereArgs: ['backend_user_id'],
      limit: 1,
    );
    if (saved.isNotEmpty) {
      final userId = saved.first['setting_value'] as String;
      try {
        await Api.getUser(userId);
        return userId;
      } on ApiException catch (error) {
        if (error.statusCode != 404) rethrow;
        await _db!.delete(
          'app_settings',
          where: 'setting_key = ?',
          whereArgs: ['backend_user_id'],
        );
        await _db!.update('vehicles', {'backend_id': null});
        await _db!.update('activities', {'backend_id': null});
        await loadVehicles();
      }
    }

    final random = Random.secure();
    String token() =>
        List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
    final user = await Api.createUser(
      email: 'garage-${token()}@autosphere.local',
      password: token(),
    );
    final userId = user['id']?.toString();
    if (userId == null || userId.isEmpty) {
      throw const ApiException('The backend did not return a user ID.');
    }
    await _db!.insert('app_settings', {
      'setting_key': 'backend_user_id',
      'setting_value': userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return userId;
  }
}
