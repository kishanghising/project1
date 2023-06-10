import 'dart:async';
import 'package:my_app/extensions/list/filter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

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
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Future<DatabaseNote> updateNote({
    required DatabaseNote note,
    required String customer,
    required int amount,
  }) async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    //make sure note exist
    await getNote(id: note.id);
    // update db
    final updatesCount = await db.update(
      noteTable,
      {
        customerColumn: customer,
        amountColumn: amount,
        isSyncedWithCloudColumn: 0,
      },
      where: 'id = ?',
      whereArgs: [note.id],
    );

    if (updatesCount == 0) {
      throw CouldNotUpdateNote();
    } else {
      final updatedNote = await getNote(id: note.id);
      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }

  Future<Iterable<DatabaseNote>> getAllNotes() async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
    );

    return notes.map((noteRow) => DatabaseNote.fromRow(noteRow));
  }

  Future<DatabaseNote> getNote({required int id}) async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
      limit: 1,
      where: 'id = ?',
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

  Future<int> deleteAllNotes() async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(noteTable);
    _notes = [];
    _notesStreamController.add(_notes);
    return numberOfDeletions;
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: 'id = ?',
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

  Future<DatabaseNote> createNote() async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();

    const customer = '';
    const amount = 0;

    //create the note
    final noteId = await db.insert(noteTable, {
      customerColumn: customer,
      amountColumn: amount,
      isSyncedWithCloudColumn: 1,
    });

    final note = DatabaseNote(
      id: noteId,
      customer: customer,
      amount: amount,
      isSyncedWithCloud: true,
    );

    _notes.add(note);
    _notesStreamController.add(_notes);

    return note;
  }

  // Future<DatabaseUser> createUser({required String email}) async {
  //   await _ensureDBIsOpen();
  //   final db = _getDatabaseOrThrow();
  //   final results = await db.query(
  //     userTable,
  //     limit: 1,
  //     where: 'email = ?',
  //     whereArgs: [email.toLowerCase()],
  //   );
  //   if (results.isNotEmpty) {
  //     throw UserAlreadyExists();
  //   }

  //   final userId = await db.insert(userTable, {
  //     emailColumn: email.toLowerCase(),
  //   });

  //   return DatabaseUser(
  //     id: userId,
  //     email: email,
  //   );
  // }

  // Future<DatabaseUser> getUser({required String email}) async {
  //   await _ensureDBIsOpen();
  //   final db = _getDatabaseOrThrow();
  //   final results = await db.query(
  //     userTable,
  //     limit: 1,
  //     where: 'email = ?',
  //     whereArgs: [email.toLowerCase()],
  //   );

  //   if (results.isEmpty) {
  //     throw CouldNotFindUser();
  //   } else {
  //     return DatabaseUser.fromRow(results.first);
  //   }
  // }

  // Future<void> deleteUser({required String email}) async {
  //   await _ensureDBIsOpen();
  //   final db = _getDatabaseOrThrow();
  //   final deletedCount = await db.delete(
  //     userTable,
  //     where: 'email = ?',
  //     whereArgs: [email.toLowerCase()],
  //   );
  //   if (deletedCount != 1) {
  //     throw CouldNotDeleteUser();
  //   }
  // }

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

      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }
}

class DatabaseNote {
  final int id;
  // final String text;
  final String customer;
  final int amount;
  final bool isSyncedWithCloud;

  DatabaseNote({
    required this.id,
    required this.customer,
    required this.amount,
    required this.isSyncedWithCloud,
  });

  DatabaseNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        customer = map[customerColumn] as String,
        amount = map[amountColumn] as int,
        isSyncedWithCloud =
            (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Note, ID = $id, isSyncedWithCloud = $isSyncedWithCloud, customer = $customer, amount = $amount ';

  // @override
  // bool operator ==(covariant DatabaseUser other) => id == other.id;

  // @override
  // int get hashCode => id.hashCode;
}

const dbName = 'notes.db';
const noteTable = 'note';
const idColumn = 'id';
const customerColumn = 'customer';
const amountColumn = 'amount';
// const emailColumn = 'email';
// const userIdColumn = 'user_id';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';
// const textColumn = 'text';
const createNoteTable = '''CREATE TABLE IF NOT EXISTS "note"(
        "id" INTEGER NOT NULL,
        "customer" TEXT,
        "amount" INTEGER,
        "is_synced_with_cloud" INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY("id" AUTOINCREMENT)
      );''';
// const createUserTable = '''CREATE TABLE IF NOT EXISTS "user"(
//         "id" INTEGER NOT NULL,
//         "email" TEXT NOT NULL UNIQUE,
//         PRIMARY KEY("id" AUTOINCREMENT)
//       );''';
