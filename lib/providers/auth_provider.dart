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
  bool _isDemo = false;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isDemo => _isDemo;

  AuthProvider() {
    _firebaseService = FirebaseService();
    try {
      // Safely initialize Firebase instances if available
      // Import 'package:firebase_core/firebase_core.dart' to check apps
      // Wait, I should import it at the top.
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
      _auth!.authStateChanges().listen((User? user) async {
        if (_isDemo) return; // Don't override demo state

        if (user != null) {
          _user = user;
          await _loadUserProfile();
          _status = AuthStatus.authenticated;
        } else if (!_isDemo) {
          // Only set unauthenticated if not in demo mode
          _user = null;
          _userProfile = null;
          _status = AuthStatus.unauthenticated;
        }
        notifyListeners();
      });
    } else {
      // No Firebase, default to unauthenticated
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // Mock Login for Demo
  Future<bool> signInAsDemo() async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1500));

      _isDemo = true;
      _firebaseService.setMockMode(true);

      _userProfile = UserProfile(
        id: 'demo_user_123',
        name: 'Demo User',
        email: 'demo@bookala.com',
        photoUrl: null,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        businessName: 'My Demo Shop',
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Demo login failed';
      notifyListeners();
      return false;
    }
  }

  // Load user profile from Firestore or Mock
  Future<void> _loadUserProfile() async {
    if (_isDemo) return;

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
        // Update last login
        await _firebaseService.updateLastLogin();
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    if (_auth == null || _googleSignIn == null) {
      _status = AuthStatus.error;
      _errorMessage = 'Firebase is not configured for this device.';
      notifyListeners();
      return false;
    }

    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

      if (googleUser == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      await _auth!.signInWithCredential(credential);
      _isDemo = false;
      _firebaseService.setMockMode(false);

      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'An error occurred during sign in';
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      if (!_isDemo && _auth != null && _googleSignIn != null) {
        await _googleSignIn!.signOut();
        await _auth!.signOut();
      }

      _isDemo = false;
      _firebaseService.setMockMode(false);
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

    // Update local state
    _userProfile = _userProfile!.copyWith(
      name: name ?? _userProfile!.name,
      businessName: businessName ?? _userProfile!.businessName,
      phone: phone ?? _userProfile!.phone,
    );
    notifyListeners();

    if (_isDemo) return; // Don't save to firebase in demo mode

    try {
      await _firebaseService.saveUserProfile(_userProfile!);
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
