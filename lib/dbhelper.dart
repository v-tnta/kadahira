import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    // データベースの初期化
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // データベースのパスを取得
    String path = join(await getDatabasesPath(), 'my_kadailist.db');

    // データベースを開き、存在しない場合は作成
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // テーブルの作成
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        datetime TEXT,
        area TEXT,
        format TEXT,
        timestamp INTEGER
      )
    ''');
  }

  // データの挿入
  Future<int> insertRecord(Map<String, dynamic> record) async {
    final db = await database;
    return await db.insert('records', record);
  }

  // データの削除
  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete('records',
      where: 'id = ?',      // 条件を指定（idが一致するレコード）
      whereArgs: [id],      // whereArgsにidをリスト形式で渡す
    );
  }

  //データの編集
  Future<int> editRecord(int id, Map<String, dynamic> record) async {
    final db = await database;
    return await db.update('records', record,
        where: 'id = ?',      // 条件を指定（idが一致するレコード）
        whereArgs: record['$id']);
  }

  // 全データの取得
  Future<List<Map<String, dynamic>>> getAllRecords() async {
    final db = await database;
    return await db.query('records');
  }
}