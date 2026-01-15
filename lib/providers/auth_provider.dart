import 'package:flutter/material.dart';
import '../models/user_profile.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unauthenticated;
  UserProfile? _userProfile;
  String? _errorMessage;
  bool _isDemo = false;

  // Getters
  AuthStatus get status => _status;
  dynamic get user => _isDemo ? 'demo_user' : null;
  UserProfile? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    // Start in unauthenticated state - waiting for Firebase setup
    _status = AuthStatus.unauthenticated;
  }

  // Demo login for testing UI while Firebase is being set up
  Future<bool> signInAsDemo() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _isDemo = true;
    _userProfile = UserProfile(
      id: 'demo_user_123',
      name: 'Demo User',
      email: 'demo@bookala.app',
      businessName: 'Demo Business',
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );
    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  }

  // Placeholder for Google Sign-In - will be implemented after Firebase setup
  Future<bool> signInWithGoogle() async {
    _errorMessage = 'Firebase not configured yet. Use Demo Login.';
    notifyListeners();
    return false;
  }

  // Placeholder for Test User - will be implemented after Firebase setup
  Future<bool> signInAsTestUser() async {
    _errorMessage = 'Firebase not configured yet. Use Demo Login.';
    notifyListeners();
    return false;
  }

  // Sign out
  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    _isDemo = false;
    _userProfile = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? businessName,
    String? phone,
  }) async {
    if (_userProfile == null) return;

    _userProfile = _userProfile!.copyWith(
      name: name ?? _userProfile!.name,
      businessName: businessName ?? _userProfile!.businessName,
      phone: phone ?? _userProfile!.phone,
    );
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
