import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer.dart';
import '../models/transaction.dart';
import '../models/user_profile.dart';
import '../config/constants.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== USER PROFILE ====================

  // Get user profile
  Future<UserProfile?> getUserProfile() async {
    if (currentUserId == null) return null;

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .get();

    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    }
    return null;
  }

  // Create or update user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    if (currentUserId == null) return;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .set(profile.toFirestore(), SetOptions(merge: true));
  }

  // Update last login
  Future<void> updateLastLogin() async {
    if (currentUserId == null) return;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .update({'lastLogin': Timestamp.now()});
  }

  // ==================== CUSTOMERS ====================

  // Get all customers stream
  Stream<List<Customer>> getCustomersStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
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

  // Get all customers (one-time fetch)
  Future<List<Customer>> getCustomers() async {
    if (currentUserId == null) return [];

    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .orderBy('name')
        .get();

    return snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();
  }

  // Get single customer
  Future<Customer?> getCustomer(String customerId) async {
    if (currentUserId == null) return null;

    final doc = await _firestore
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

  // Get customer stream
  Stream<Customer?> getCustomerStream(String customerId) {
    if (currentUserId == null) return Stream.value(null);

    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .doc(customerId)
        .snapshots()
        .map((doc) => doc.exists ? Customer.fromFirestore(doc) : null);
  }

  // Add customer
  Future<String> addCustomer(Customer customer) async {
    if (currentUserId == null) throw Exception('User not logged in');

    final docRef = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .add(customer.toFirestore());

    return docRef.id;
  }

  // Update customer
  Future<void> updateCustomer(Customer customer) async {
    if (currentUserId == null) return;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .doc(customer.id)
        .update(customer.toFirestore());
  }

  // Delete customer
  Future<void> deleteCustomer(String customerId) async {
    if (currentUserId == null) return;

    // Delete all transactions for this customer first
    final transactions = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.transactionsCollection)
        .where('customerId', isEqualTo: customerId)
        .get();

    for (var doc in transactions.docs) {
      await doc.reference.delete();
    }

    // Delete customer
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .doc(customerId)
        .delete();
  }

  // ==================== TRANSACTIONS ====================

  // Get transactions stream for a customer
  Stream<List<CustomerTransaction>> getTransactionsStream(String customerId) {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
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

  // Get all transactions stream
  Stream<List<CustomerTransaction>> getAllTransactionsStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
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

  // Add transaction and update customer balance
  Future<String> addTransaction(CustomerTransaction transaction) async {
    if (currentUserId == null) throw Exception('User not logged in');

    // Add transaction
    final docRef = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.transactionsCollection)
        .add(transaction.toFirestore());

    // Update customer totals
    final customerRef = _firestore
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

  // Delete transaction and update customer balance
  Future<void> deleteTransaction(CustomerTransaction transaction) async {
    if (currentUserId == null) return;

    // Delete transaction
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.transactionsCollection)
        .doc(transaction.id)
        .delete();

    // Update customer totals
    final customerRef = _firestore
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

  // ==================== ANALYTICS ====================

  // Get dashboard totals
  Future<Map<String, double>> getDashboardTotals() async {
    if (currentUserId == null) return {'credit': 0, 'debit': 0};

    final customers = await getCustomers();

    double totalCredit = 0;
    double totalDebit = 0;

    for (var customer in customers) {
      totalCredit += customer.totalCredit;
      totalDebit += customer.totalDebit;
    }

    return {
      'credit': totalCredit,
      'debit': totalDebit,
      'balance': totalCredit - totalDebit,
    };
  }
}
