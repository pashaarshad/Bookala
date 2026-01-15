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
      }
    } catch (e) {
      debugPrint('AuthProvider: Firebase not available: $e');
    }
    _init();
  }

  // Initialize and check auth state
  void _init() {
    if (_auth != null) {
      // LISTEN TO FIREBASE AUTH STATE
      _auth!.authStateChanges().listen(
        (User? user) async {
          debugPrint('AuthStateChanged: ${user?.email}');

          if (user != null) {
            _user = user;
            // Don't set authenticated yet, wait for profile loading (optional, but safer)
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
      _status = AuthStatus.error;
      _errorMessage = 'Firebase is not configured.';
      notifyListeners();
    }
  }

  // Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    try {
      _userProfile = await _firebaseService.getUserProfile();

      // Create profile if doesn't exist
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
      // Set loading state
      _status = AuthStatus.loading;
      notifyListeners();

      // 1. Google Sign In
      debugPrint('Starting interactive sign in...');
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

      if (googleUser == null) {
        // User cancelled
        debugPrint('User cancelled sign in');
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      // 2. Get Credential
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Firebase Sign In
      debugPrint('Signing in to Firebase with credential...');
      await _auth!.signInWithCredential(credential);

      // We don't need to manually set authenticated here because
      // the stream listener in _init() will fire and do it for us.

      return true;
    } catch (e) {
      debugPrint('SignIn Error: $e');
      _status = AuthStatus.error;
      _errorMessage = 'Login failed: ${e.toString()}';
      notifyListeners();

      // Ensure we reset to unauthenticated if it failed so retry works
      if (_user == null) {
        await signOut();
      }
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      if (_googleSignIn != null) await _googleSignIn!.signOut();
      if (_auth != null) await _auth!.signOut();

      // Listener will handle state update to unauthenticated
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

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
