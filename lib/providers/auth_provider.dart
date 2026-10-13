import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import '../services/appwrite_service.dart';

class AuthProvider extends ChangeNotifier {
  models.User? _user;
  bool _loading = true;
  String? _error;

  models.User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      _user = await AppwriteService().account.get();
    } catch (_) {
      _user = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    try {
      await AppwriteService().account.createEmailPasswordSession(email: email, password: password);
      _user = await AppwriteService().account.get();
      notifyListeners();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message ?? 'Login failed';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String email, String password, String name) async {
    _error = null;
    try {
      await AppwriteService().account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      return await login(email, password);
    } on AppwriteException catch (e) {
      _error = e.message ?? 'Sign up failed';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await AppwriteService().account.deleteSession(sessionId: 'current');
    } catch (_) {}
    _user = null;
    notifyListeners();
  }
}
