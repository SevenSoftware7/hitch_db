import 'package:flutter/foundation.dart';

import 'package:hitch_db/services/login_service.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthSession extends ChangeNotifier {
  AuthSession(this._loginService);

  final LoginService _loginService;

  AuthStatus _status = AuthStatus.checking;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isChecking => _status == AuthStatus.checking;

  Future<void> restoreSession() async {
    _status = AuthStatus.checking;
    _errorMessage = null;
    notifyListeners();

    final isLoggedIn = await _loginService.isLoggedIn();
    _status = isLoggedIn
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _errorMessage = null;
    notifyListeners();

    final result = await _loginService.login(email: email, password: password);
    if (!result.isSuccess) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = result.message ?? 'Unable to sign in.';
      notifyListeners();
      return false;
    }

    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _loginService.register(
        email: email,
        password: password,
      );
      if (!result.isSuccess) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = result.message ?? 'Unable to create your account.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'An error occurred during registration: $e';
      notifyListeners();
      return false;
    }

    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _loginService.logout();
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> deleteAccount({required String password}) async {
    _errorMessage = null;
    notifyListeners();

    bool result;
    try {
      result = await _loginService.deleteAccount(password: password);
    } catch (e) {
      _errorMessage = 'An error occurred while deleting your account: $e';
      notifyListeners();
      return false;
    }

    if (!result) {
      _errorMessage = 'Failed to delete your account.';
      notifyListeners();
      return false;
    }

    await logout();
    return result;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _loginService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!result) {
        _errorMessage = 'Failed to update your password.';
        notifyListeners();
      }
      return result;
    } catch (e) {
      _errorMessage = 'An error occurred while changing password: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }
}
