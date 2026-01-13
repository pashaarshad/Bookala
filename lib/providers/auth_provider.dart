import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import '../services/firebase_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseService _firebaseService = FirebaseService();

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
    _init();
  }

  // Initialize and check auth state
  void _init() {
    _auth.authStateChanges().listen((User? user) async {
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
    });
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
      } else {
        // Update last login
        await _firebaseService.updateLastLogin();
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

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
      await _auth.signInWithCredential(credential);

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

      await _googleSignIn.signOut();
      await _auth.signOut();

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

    try {
      _userProfile = _userProfile!.copyWith(
        name: name ?? _userProfile!.name,
        businessName: businessName ?? _userProfile!.businessName,
        phone: phone ?? _userProfile!.phone,
      );

      await _firebaseService.saveUserProfile(_userProfile!);
      notifyListeners();
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
