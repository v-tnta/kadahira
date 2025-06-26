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
      version: 2, // ★ バージョンを2に更新
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // ★ onUpgradeコールバックを追加
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
        timestamp INTEGER,
        notibefore INTEGER
      )
    '''); // ★ notibeforeカラムを追加
  }

  // ★ データベースのマイグレーション処理を追加
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // version 1 -> 2: notibeforeカラムを追加し、デフォルト値を10に設定
      await db.execute("ALTER TABLE records ADD COLUMN notibefore INTEGER DEFAULT 10");
    }
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

    return await
    db.update('records', record,
        where: 'id = ?',      // 条件を指定（idが一致するレコード）
        whereArgs: [id]);
  }

  // 全データの取得
  Future<List<Map<String, dynamic>>> getAllRecords() async {
    final db = await database;
    return await db.query('records');
  }

}