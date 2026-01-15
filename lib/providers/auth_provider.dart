import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import '../services/firebase_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  late final FirebaseService _firebaseService;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  UserProfile? _userProfile;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _firebaseService = FirebaseService();
    try {
      if (Firebase.apps.isNotEmpty) {
        _auth = FirebaseAuth.instance;
        _googleSignIn = GoogleSignIn();
        debugPrint('✅ Firebase Auth initialized');
      } else {
        debugPrint('⚠️ Firebase not initialized yet');
      }
    } catch (e) {
      debugPrint('❌ AuthProvider init error: $e');
    }
    _init();
  }

  void _init() {
    if (_auth != null) {
      _auth!.authStateChanges().listen(
        (User? user) async {
          debugPrint('Auth state changed: ${user?.email}');

          if (user != null) {
            _user = user;
            await _loadUserProfile();
            _status = AuthStatus.authenticated;
          } else {
            _user = null;
            _userProfile = null;
            _status = AuthStatus.unauthenticated;
          }
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Auth listener error: $e');
          _status = AuthStatus.error;
          _errorMessage = e.toString();
          notifyListeners();
        },
      );
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      _userProfile = await _firebaseService.getUserProfile();

      if (_userProfile == null && _user != null) {
        _userProfile = UserProfile(
          id: _user!.uid,
          name: _user!.displayName ?? 'User',
          email: _user!.email ?? '',
          photoUrl: _user!.photoURL,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await _firebaseService.saveUserProfile(_userProfile!);
      } else if (_userProfile != null) {
        await _firebaseService.updateLastLogin();
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    if (_auth == null || _googleSignIn == null) {
      _errorMessage = 'Firebase not initialized';
      notifyListeners();
      return false;
    }

    try {
      _status = AuthStatus.loading;
      notifyListeners();

      debugPrint('Starting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

      if (googleUser == null) {
        debugPrint('Google Sign-In cancelled');
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      debugPrint('Got Google user: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('Signing in to Firebase...');
      await _auth!.signInWithCredential(credential);
      debugPrint('✅ Firebase sign-in successful!');

      return true;
    } catch (e) {
      debugPrint('❌ Sign-in error: $e');
      _status = AuthStatus.error;
      _errorMessage = 'Sign in failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Sign in as Test User (Email/Password)
  Future<bool> signInAsTestUser() async {
    if (_auth == null) {
      _errorMessage = 'Firebase not initialized';
      notifyListeners();
      return false;
    }

    try {
      _status = AuthStatus.loading;
      notifyListeners();

      const testEmail = 'testuser@bookala.test';
      const testPassword = 'TestUser123!';

      try {
        await _auth!.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
        debugPrint('✅ Test User signed in!');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          await _auth!.createUserWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          );
          debugPrint('✅ Test User created and signed in!');
        } else {
          rethrow;
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ Test User error: $e');
      _status = AuthStatus.error;
      _errorMessage = 'Test login failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Sign in as Demo (Offline mode)
  Future<bool> signInAsDemo() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

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

  // Sign out
  Future<void> signOut() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      if (_googleSignIn != null) await _googleSignIn!.signOut();
      if (_auth != null) await _auth!.signOut();

      _user = null;
      _userProfile = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error signing out';
      notifyListeners();
    }
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

    try {
      await _firebaseService.saveUserProfile(_userProfile!);
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
