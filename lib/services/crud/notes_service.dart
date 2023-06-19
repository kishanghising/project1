import 'dart:async';
import 'package:my_app/extensions/list/filter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import 'crud_exceptions.dart';

class NotesService {
  Database? _db;

  List<DatabaseNote> _notes = [];

  static final NotesService _shared = NotesService._sharedInstance();
  NotesService._sharedInstance() {
    _notesStreamController = StreamController<List<DatabaseNote>>.broadcast(
      onListen: () {
        _notesStreamController.sink.add(_notes);
      },
    );
  }
  factory NotesService() => _shared;

  late final StreamController<List<DatabaseNote>> _notesStreamController;

  Stream<List<DatabaseNote>> get allNotes =>
      _notesStreamController.stream.filter((note) {
        return true;
      });

  Future<void> _cacheNotes() async {
    // await _ensureDBIsOpen();
    final allNotes = await getAllCustomers();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Future<DatabaseNote> updateCustomer({
    required DatabaseNote note,
    required String customer,
    required int total,
  }) async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    //make sure note exist
    await getCustomer(id: note.id);
    // update db
    final updatesCount = await db.update(
      customerTable,
      {
        customerColumn: customer,
        totalColumn: total,
      },
      where: 'customer_id = ?',
      whereArgs: [note.id],
    );

    if (updatesCount == 0) {
      throw CouldNotUpdateNote();
    } else {
      final updatedNote = await getCustomer(id: note.id);
      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }

  Future<Iterable<DatabaseNote>> getAllCustomers() async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      customerTable,
    );

    return notes.map((noteRow) => DatabaseNote.fromRow(noteRow));
  }

  Future<DatabaseNote> getCustomer({required int id}) async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      customerTable,
      limit: 1,
      where: 'customer_id = ?',
      whereArgs: [id],
    );
    if (notes.isEmpty) {
      throw CouldNotFindNote();
    } else {
      final note = DatabaseNote.fromRow(notes.first);
      _notes.removeWhere((note) => note.id == id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
  }

  Future<int> deleteAllCustomer() async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(customerTable);
    _notes = [];
    _notesStreamController.add(_notes);
    return numberOfDeletions;
  }

  Future<void> deleteCustomer({required int id}) async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      customerTable,
      where: 'customer_id = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteNote();
    } else {
      // final countBefore = _notes.length;
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<DatabaseNote> createCustomer() async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    const customer = '';
    const total = 0;
    //create the note
    final customerId = await db.insert(customerTable, {
      customerColumn: customer,
      totalColumn: total,
    });

    final note = DatabaseNote(
      id: customerId,
      customer: customer,
      total: total,
    );

    _notes.add(note);
    _notesStreamController.add(_notes);

    return note;
  }

  Future<DatabasePurchase> createPurchase(
      {required int amount, required int customerId}) async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final nowT = DateTime.now();
    DateTime currentTime = DateTime(
      nowT.year,
      nowT.month,
      nowT.day,
      nowT.hour,
      nowT.minute,
      nowT.second,
    );
    final String now = DateFormat('yyyy-MM-dd HH:mm:ss').format(currentTime);

    final purchaseId = await db.insert(purchaseTable, {
      amountColumn: amount,
      customerIdColumn: customerId,
      purchaseDateColumn: now,
    });

    return DatabasePurchase(
      id: purchaseId,
      amount: amount,
      customerId: customerId,
      purchaseDate: now,
    );
  }

  Future<DatabasePurchase> getPurchase({required int purchaseId}) async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      purchaseTable,
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );

    if (results.isEmpty) {
      throw CouldNotFindUser();
    } else {
      return DatabasePurchase.fromRow(results.first);
    }
  }

  Future<Iterable<DatabasePurchase>> getAllPurchases(
      {required int customerId}) async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      purchaseTable,
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );

    if (results.isEmpty) {
      throw CouldNotFindUser();
    } else {
      return results
          .map((purchaseRow) => DatabasePurchase.fromRow(purchaseRow));
    }
  }

  Future<void> deletePurchase({required int purchaseId}) async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      purchaseTable,
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDBIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      //empty
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);

      _db = db;

      await db.execute(createNoteTable);
      await db.execute(createPurchaseTable);

      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }
}

// @immutable
class DatabasePurchase {
  final int id;
  final int amount;
  final int customerId;
  final String purchaseDate;

  const DatabasePurchase({
    required this.id,
    required this.amount,
    required this.customerId,
    required this.purchaseDate,
  });

  DatabasePurchase.fromRow(Map<String, Object?> map)
      : id = map[purchaseIdColumn] as int,
        customerId = map[customerIdColumn] as int,
        amount = map[amountColumn] as int,
        purchaseDate = map[purchaseDateColumn] as String;

  @override
  String toString() =>
      'Purchase, Id = $id, customerId = $customerId, amount = $amount, purchaseDate = $purchaseDate';

  @override
  bool operator ==(covariant DatabasePurchase other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int total;
  final String customer;

  DatabaseNote({
    required this.id,
    required this.customer,
    required this.total,
  });

  DatabaseNote.fromRow(Map<String, Object?> map)
      : id = map[customerIdColumn] as int,
        customer = map[customerColumn] as String,
        total = map[totalColumn] as int;

  @override
  String toString() =>
      'Customer, ID = $id, customer = $customer, total = $total ';
}

const dbName = 'notes.db';
const customerTable = 'customer';
const purchaseTable = 'purchase';
const customerIdColumn = 'customer_id';
const customerColumn = 'customer';
const amountColumn = 'amount';
const totalColumn = 'total';
const purchaseDateColumn = 'purchase_date';
const purchaseIdColumn = 'purchase_id';
// const textColumn = 'text';
const createNoteTable = '''CREATE TABLE IF NOT EXISTS "customer"(
        "customer_id" INTEGER NOT NULL,
        "customer" TEXT,
        "total" INTEGER NOT NULL,
        PRIMARY KEY("customer_id" AUTOINCREMENT)
      );''';
const createPurchaseTable = '''CREATE TABLE IF NOT EXISTS "purchase"(
        "purchase_id" INTEGER NOT NULL,
        "amount" INTEGER,
        "customer_id" INTEGER NOT NULL,
        "purchase_date" TEXT,
        FOREIGN KEY("customer_id") REFERENCES "customer"("customer_id"),
        PRIMARY KEY("purchase_id" AUTOINCREMENT)        
      );''';
