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
        // Web Client ID from google-services.json
        _googleSignIn = GoogleSignIn(
          serverClientId:
              '583387496324-11askmipvnrob3hg5n4d4komre5k8b6g.apps.googleusercontent.com',
        );
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
    } else {
      _status = AuthStatus.error;
      _errorMessage = 'Firebase is not configured. Please check your setup.';
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
      _status = AuthStatus.error;
      _errorMessage = 'Firebase is not configured. Please reinstall the app.';
      notifyListeners();
      return false;
    }

    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      debugPrint('Starting Google Sign-In...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

      if (googleUser == null) {
        debugPrint('Google Sign-In cancelled by user');
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Sign in cancelled';
        notifyListeners();
        return false;
      }

      debugPrint('Got Google user: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint('Got Google auth tokens');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      debugPrint('Signing in to Firebase...');
      final userCredential = await _auth!.signInWithCredential(credential);

      if (userCredential.user != null) {
        debugPrint(
          'Firebase sign-in successful: ${userCredential.user!.email}',
        );
        _user = userCredential.user;
        await _loadUserProfile();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        debugPrint('Firebase sign-in failed: no user returned');
        _status = AuthStatus.error;
        _errorMessage = 'Authentication failed';
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.message}');
      _status = AuthStatus.error;
      _errorMessage = e.message ?? 'Authentication failed';
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Sign-in error: $e');
      _status = AuthStatus.error;
      _errorMessage = 'Sign in failed: $e';
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      if (_auth != null && _googleSignIn != null) {
        await _googleSignIn!.signOut();
        await _auth!.signOut();
      }

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

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
