import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'business_card_parser.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('business_cards.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE business_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone_numbers TEXT,
        emails TEXT,
        urls TEXT,
        address TEXT,
        original_text TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> saveBusinessCard(
    BusinessCardEntity card,
    String originalText,
  ) async {
    final db = await instance.database;

    final data = {
      'name': card.name,
      'phone_numbers': jsonEncode(card.phoneNumbers),
      'emails': jsonEncode(card.emails),
      'urls': jsonEncode(card.urls),
      'address': card.address,
      'original_text': originalText,
      'created_at': DateTime.now().toIso8601String(),
    };

    return await db.insert('business_cards', data);
  }

  Future<List<Map<String, dynamic>>> getBusinessCards() async {
    final db = await instance.database;
    return await db.query('business_cards', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getBusinessCard(int id) async {
    final db = await instance.database;
    final results = await db.query(
      'business_cards',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  Future<int> deleteBusinessCard(int id) async {
    final db = await instance.database;
    return await db.delete('business_cards', where: 'id = ?', whereArgs: [id]);
  }

  Future<BusinessCardEntity> businessCardFromMap(
    Map<String, dynamic> map,
  ) async {
    return BusinessCardEntity(
      name: map['name'],
      phoneNumbers: List<String>.from(jsonDecode(map['phone_numbers'])),
      emails: List<String>.from(jsonDecode(map['emails'])),
      urls: List<String>.from(jsonDecode(map['urls'])),
      address: map['address'],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
