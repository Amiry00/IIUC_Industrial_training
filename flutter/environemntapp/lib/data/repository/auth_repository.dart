import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../core/constants/app_constants.dart';
import '../../services/database_service.dart';
import '../model/user.dart';

class AuthRepository {
  final DatabaseService _databaseService;

  AuthRepository(this._databaseService);

  /// Hash password using SHA-256.
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Register a new user. Returns the registered User or throws an Exception.
  Future<User> register(String name, String email, String password) async {
    final db = await _databaseService.database;

    // Check if user already exists
    final existingUser = await db.query(
      AppConstants.usersTable,
      where: 'email = ?',
      whereArgs: [email],
    );

    if (existingUser.isNotEmpty) {
      throw Exception('User with this email already exists.');
    }

    final passwordHash = _hashPassword(password);

    final id = await db.insert(
      AppConstants.usersTable,
      {
        'name': name,
        'email': email,
        'password_hash': passwordHash,
        'created_at': DateTime.now().toIso8601String(),
      },
    );

    return User(
      id: id,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );
  }

  /// Login a user. Returns the User if successful, throws an Exception otherwise.
  Future<User> login(String email, String password) async {
    final db = await _databaseService.database;
    final passwordHash = _hashPassword(password);

    final result = await db.query(
      AppConstants.usersTable,
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email, passwordHash],
    );

    if (result.isEmpty) {
      throw Exception('Invalid email or password.');
    }

    return User.fromMap(result.first);
  }

  /// Get user by ID.
  Future<User?> getUserById(int id) async {
    final db = await _databaseService.database;
    final result = await db.query(
      AppConstants.usersTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  /// Update user profile.
  Future<User> updateProfile(User user) async {
    final db = await _databaseService.database;
    await db.update(
      AppConstants.usersTable,
      {
        'name': user.name,
        'avatar_path': user.avatarPath,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return user;
  }
}
