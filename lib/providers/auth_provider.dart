import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' show OAuthProvider;
import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config.dart';
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

  /// Google sign-in via Appwrite OAuth2 (same provider the website uses).
  /// Opens the system browser; Appwrite redirects back into the app through
  /// the `appwrite-callback-<projectId>` scheme declared in AndroidManifest.
  Future<bool> signInWithGoogle() async {
    _error = null;
    notifyListeners();
    const scheme = 'appwrite-callback-${AppConfig.appwriteProjectId}';
    try {
      await AppwriteService().account.createOAuth2Session(
        provider: OAuthProvider.google,
        success: '$scheme://',
        failure: '$scheme://',
      );
      _user = await AppwriteService().account.get();
      notifyListeners();
      return true;
    } on PlatformException catch (e) {
      // User dismissed the browser tab before finishing.
      if (e.code == 'CANCELED') return false;
      _error = 'Google sign-in failed. Please try again.';
      notifyListeners();
      return false;
    } on AppwriteException catch (e) {
      _error = e.message ?? 'Google sign-in failed';
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Google sign-in failed. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
