import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/transaction.dart';
import '../models/user_profile.dart';
import '../config/constants.dart';

class FirebaseService {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  FirebaseService() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
        _auth = FirebaseAuth.instance;
        debugPrint('✅ FirebaseService initialized');
      }
    } catch (e) {
      debugPrint('❌ FirebaseService init error: $e');
    }
  }

  String? get currentUserId => _auth?.currentUser?.uid;
  bool get isAvailable =>
      _firestore != null && _auth != null && currentUserId != null;

  // ==================== USER PROFILE ====================

  Future<UserProfile?> getUserProfile() async {
    if (!isAvailable) return null;

    try {
      final doc = await _firestore!
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .get();

      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error getting user profile: $e');
    }
    return null;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    if (!isAvailable) return;

    await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .set(profile.toFirestore(), SetOptions(merge: true));
  }

  Future<void> updateLastLogin() async {
    if (!isAvailable) return;

    await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .update({'lastLogin': Timestamp.now()});
  }

  // ==================== CUSTOMERS ====================

  Stream<List<Customer>> getCustomersStream() {
    if (!isAvailable) return Stream.value([]);

    return _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList(),
        );
  }

  Future<List<Customer>> getCustomers() async {
    if (!isAvailable) return [];

    final snapshot = await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .orderBy('name')
        .get();

    return snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();
  }

  Future<Customer?> getCustomer(String customerId) async {
    if (!isAvailable) return null;

    final doc = await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .doc(customerId)
        .get();

    if (doc.exists) {
      return Customer.fromFirestore(doc);
    }
    return null;
  }

  Stream<Customer?> getCustomerStream(String customerId) {
    if (!isAvailable) return Stream.value(null);

    return _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .doc(customerId)
        .snapshots()
        .map((doc) => doc.exists ? Customer.fromFirestore(doc) : null);
  }

  Future<String> addCustomer(Customer customer) async {
    if (!isAvailable) throw Exception('Not logged in');

    final docRef = await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .add(customer.toFirestore());

    return docRef.id;
  }

  Future<void> updateCustomer(Customer customer) async {
    if (!isAvailable) return;

    await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .doc(customer.id)
        .update(customer.toFirestore());
  }

  Future<void> deleteCustomer(String customerId) async {
    if (!isAvailable) return;

    // Delete all transactions for this customer first
    final transactions = await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.transactionsCollection)
        .where('customerId', isEqualTo: customerId)
        .get();

    for (var doc in transactions.docs) {
      await doc.reference.delete();
    }

    await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .doc(customerId)
        .delete();
  }

  // ==================== TRANSACTIONS ====================

  Stream<List<CustomerTransaction>> getTransactionsStream(String customerId) {
    if (!isAvailable) return Stream.value([]);

    return _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.transactionsCollection)
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CustomerTransaction.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<CustomerTransaction>> getAllTransactionsStream() {
    if (!isAvailable) return Stream.value([]);

    return _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.transactionsCollection)
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CustomerTransaction.fromFirestore(doc))
              .toList(),
        );
  }

  Future<String> addTransaction(CustomerTransaction transaction) async {
    if (!isAvailable) throw Exception('Not logged in');

    final docRef = await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.transactionsCollection)
        .add(transaction.toFirestore());

    // Update customer totals
    final customerRef = _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .doc(transaction.customerId);

    if (transaction.type == TransactionType.credit) {
      await customerRef.update({
        'totalCredit': FieldValue.increment(transaction.amount),
        'updatedAt': Timestamp.now(),
      });
    } else {
      await customerRef.update({
        'totalDebit': FieldValue.increment(transaction.amount),
        'updatedAt': Timestamp.now(),
      });
    }

    return docRef.id;
  }

  Future<void> deleteTransaction(CustomerTransaction transaction) async {
    if (!isAvailable) return;

    await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.transactionsCollection)
        .doc(transaction.id)
        .delete();

    final customerRef = _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .doc(transaction.customerId);

    if (transaction.type == TransactionType.credit) {
      await customerRef.update({
        'totalCredit': FieldValue.increment(-transaction.amount),
        'updatedAt': Timestamp.now(),
      });
    } else {
      await customerRef.update({
        'totalDebit': FieldValue.increment(-transaction.amount),
        'updatedAt': Timestamp.now(),
      });
    }
  }

  Future<List<CustomerTransaction>> getTransactions(String customerId) async {
    if (!isAvailable) return [];

    final snapshot = await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.transactionsCollection)
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CustomerTransaction.fromFirestore(doc))
        .toList();
  }
}
