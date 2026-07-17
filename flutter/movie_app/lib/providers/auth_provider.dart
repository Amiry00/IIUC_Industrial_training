import 'package:flutter/material.dart';
import 'package:cinema/data/model/user.dart';
import 'package:cinema/services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseService _dbService;

  AuthProvider(this._dbService);

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  bool get isAuthenticated => _currentUser != null;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final sessionData = await _dbService.getCurrentSession();
      if (sessionData != null) {
        _currentUser = User.fromMap(sessionData);
        _dbService.currentUserId = _currentUser!.id;
      }
    } catch (e) {
      _errorMessage = 'Failed to restore session';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final userData = await _dbService.loginUser(email, password);
      if (userData != null) {
        _currentUser = User.fromMap(userData);
        _dbService.currentUserId = _currentUser!.id;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid email or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during login';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final userData = await _dbService.registerUser(name, email, password);
      if (userData != null) {
        // Automatically login after successful registration
        return await login(email, password);
      } else {
        _errorMessage = 'Email is already registered';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during registration';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbService.clearSession();
      _currentUser = null;
      _dbService.currentUserId = 0;
    } catch (e) {
      _errorMessage = 'Failed to logout cleanly';
    }

    _isLoading = false;
    notifyListeners();
  }
}
