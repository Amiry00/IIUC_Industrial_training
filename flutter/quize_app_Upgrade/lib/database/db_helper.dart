import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../models/result.dart';

class DBHelper {
  // Singleton pattern to ensure only one instance of DBHelper exists
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quiz_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        created_by INTEGER NOT NULL,
        FOREIGN KEY (created_by) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL,
        question TEXT NOT NULL,
        option_a TEXT NOT NULL,
        option_b TEXT NOT NULL,
        option_c TEXT NOT NULL,
        option_d TEXT NOT NULL,
        correct_option TEXT NOT NULL,
        FOREIGN KEY (exam_id) REFERENCES exams (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        exam_id INTEGER NOT NULL,
        score INTEGER NOT NULL,
        total INTEGER NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (exam_id) REFERENCES exams (id)
      )
    ''');
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUser(String email, String password) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<bool> isEmailTaken(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty;
  }

  Future<int> insertExam(Exam exam) async {
    final db = await database;
    return await db.insert('exams', exam.toMap());
  }

  Future<List<Exam>> getExamsByAdmin(int adminId) async {
    final db = await database;
    final maps = await db.query(
      'exams',
      where: 'created_by = ?',
      whereArgs: [adminId],
    );
    return maps.map((map) => Exam.fromMap(map)).toList();
  }

  Future<List<Exam>> getAllExams() async {
    final db = await database;
    final maps = await db.query('exams');
    return maps.map((map) => Exam.fromMap(map)).toList();
  }

  // Cascading delete: delete associated questions and results first
  Future<int> deleteExam(int examId) async {
    final db = await database;
    await db.delete('questions', where: 'exam_id = ?', whereArgs: [examId]);
    await db.delete('results', where: 'exam_id = ?', whereArgs: [examId]);
    return await db.delete('exams', where: 'id = ?', whereArgs: [examId]);
  }

  Future<int> insertQuestion(Question question) async {
    final db = await database;
    return await db.insert('questions', question.toMap());
  }

  Future<List<Question>> getQuestionsByExam(int examId) async {
    final db = await database;
    final maps = await db.query(
      'questions',
      where: 'exam_id = ?',
      whereArgs: [examId],
    );
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  Future<int> getQuestionCount(int examId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM questions WHERE exam_id = ?',
      [examId],
    );
    return result.first['count'] as int;
  }

  Future<int> insertResult(Result result) async {
    final db = await database;
    return await db.insert('results', result.toMap());
  }

  Future<List<Result>> getResultsByUser(int userId) async {
    final db = await database;
    final maps = await db.query(
      'results',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Result.fromMap(map)).toList();
  }

  Future<Exam?> getExamById(int examId) async {
    final db = await database;
    final maps = await db.query(
      'exams',
      where: 'id = ?',
      whereArgs: [examId],
    );
    if (maps.isNotEmpty) {
      return Exam.fromMap(maps.first);
    }
    return null;
  }

  Future<void> printDatabaseContents() async {
    try {
      final db = await database;
      final tables = ['users', 'exams', 'questions', 'results'];
      for (final table in tables) {
        final List<Map<String, dynamic>> maps = await db.query(table);
        debugPrint('--- Table: $table ---');
        for (final row in maps) {
          debugPrint(row.toString());
        }
        debugPrint('----------------------');
      }
    } catch (e) {
      debugPrint('Error printing database: $e');
    }
  }
}
