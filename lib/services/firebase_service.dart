import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/customer.dart';
import '../models/transaction.dart';
import '../models/user_profile.dart';
import '../config/constants.dart';

class FirebaseService {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  bool _isMock = false;

  // Mock Data Store
  final Map<String, Customer> _mockCustomers = {};
  final Map<String, CustomerTransaction> _mockTransactions = {};

  // StreamControllers for mock mode to enable real-time updates
  final StreamController<List<Customer>> _mockCustomersController =
      StreamController<List<Customer>>.broadcast();
  final StreamController<List<CustomerTransaction>>
  _mockTransactionsController =
      StreamController<List<CustomerTransaction>>.broadcast();

  FirebaseService() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
        _auth = FirebaseAuth.instance;
      } else {
        _isMock = true;
      }
    } catch (e) {
      _isMock = true;
    }
  }

  // Notify mock streams when data changes
  void _notifyMockCustomersChanged() {
    if (_isMock) {
      _mockCustomersController.add(_mockCustomers.values.toList());
    }
  }

  void _notifyMockTransactionsChanged() {
    if (_isMock) {
      final transactions = _mockTransactions.values.toList();
      transactions.sort((a, b) => b.date.compareTo(a.date));
      _mockTransactionsController.add(transactions);
    }
  }

  void setMockMode(bool isMock) {
    _isMock = isMock;
    if (isMock) {
      // Initialize some dummy data for demo
      _mockCustomers.clear();
      _mockTransactions.clear();

      final demoCustomer = Customer(
        id: 'demo_cust_1',
        name: 'Rahul Sharma',
        phone: '+919876543210',
        shopName: 'Sharma General Store',
        totalCredit: 5000,
        totalDebit: 2000,
        latitude: 28.6139,
        longitude: 77.2090,
        radius: 100,
        createdAt: DateTime.now(),
      );
      _mockCustomers[demoCustomer.id] = demoCustomer;
    }
  }

  // Get current user ID
  String? get currentUserId =>
      _isMock ? 'demo_user_123' : _auth?.currentUser?.uid;

  // ==================== USER PROFILE ====================

  // Get user profile
  Future<UserProfile?> getUserProfile() async {
    if (_isMock) {
      return UserProfile(
        id: 'demo_user_123',
        email: 'demo@bookala.com',
        name: 'Demo Admin',
        createdAt: DateTime.now(),
        businessName: 'Demo Business',
      );
    }

    if (currentUserId == null || _firestore == null) return null;

    try {
      final doc = await _firestore!
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .get();

      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
    } catch (e) {
      print('Firestore error: $e');
    }
    return null;
  }

  // Create or update user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    if (_isMock) return;
    if (currentUserId == null || _firestore == null) return;

    await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .set(profile.toFirestore(), SetOptions(merge: true));
  }

  // Update last login
  Future<void> updateLastLogin() async {
    if (_isMock) return;
    if (currentUserId == null || _firestore == null) return;

    await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .update({'lastLogin': Timestamp.now()});
  }

  // ==================== CUSTOMERS ====================

  // Get all customers stream
  Stream<List<Customer>> getCustomersStream() {
    if (_isMock) {
      // Return broadcast stream and emit initial data
      Future.microtask(() => _notifyMockCustomersChanged());
      return _mockCustomersController.stream;
    }
    if (currentUserId == null || _firestore == null) return Stream.value([]);

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

  // Get all customers (one-time fetch)
  Future<List<Customer>> getCustomers() async {
    if (_isMock) {
      return _mockCustomers.values.toList();
    }
    if (currentUserId == null || _firestore == null) return [];

    final snapshot = await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .orderBy('name')
        .get();

    return snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();
  }

  // Get single customer
  Future<Customer?> getCustomer(String customerId) async {
    if (_isMock) {
      return _mockCustomers[customerId];
    }
    if (currentUserId == null || _firestore == null) return null;

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

  // Get customer stream
  Stream<Customer?> getCustomerStream(String customerId) {
    if (_isMock) {
      return Stream.value(_mockCustomers[customerId]);
    }
    if (currentUserId == null || _firestore == null) return Stream.value(null);

    return _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .doc(customerId)
        .snapshots()
        .map((doc) => doc.exists ? Customer.fromFirestore(doc) : null);
  }

  // Add customer
  Future<String> addCustomer(Customer customer) async {
    if (_isMock) {
      _mockCustomers[customer.id] = customer;
      _notifyMockCustomersChanged(); // Notify UI
      return customer.id;
    }

    if (currentUserId == null || _firestore == null) {
      throw Exception('User not logged in');
    }

    final docRef = await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .add(customer.toFirestore());

    return docRef.id;
  }

  // Update customer
  Future<void> updateCustomer(Customer customer) async {
    if (_isMock) {
      _mockCustomers[customer.id] = customer;
      _notifyMockCustomersChanged(); // Notify UI
      return;
    }

    if (currentUserId == null || _firestore == null) return;

    await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .doc(customer.id)
        .update(customer.toFirestore());
  }

  // Delete customer
  Future<void> deleteCustomer(String customerId) async {
    if (_isMock) {
      _mockCustomers.remove(customerId);
      _notifyMockCustomersChanged(); // Notify UI
      return;
    }

    if (currentUserId == null || _firestore == null) return;

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

    // Delete customer
    await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.customersCollection)
        .doc(customerId)
        .delete();
  }

  // ==================== TRANSACTIONS ====================

  // Get transactions stream for a customer
  Stream<List<CustomerTransaction>> getTransactionsStream(String customerId) {
    if (_isMock) {
      // Return filtered stream from broadcast controller
      Future.microtask(() => _notifyMockTransactionsChanged());
      return _mockTransactionsController.stream.map(
        (transactions) =>
            transactions.where((t) => t.customerId == customerId).toList(),
      );
    }

    if (currentUserId == null || _firestore == null) return Stream.value([]);

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

  // Get all transactions stream
  Stream<List<CustomerTransaction>> getAllTransactionsStream() {
    if (_isMock) {
      Future.microtask(() => _notifyMockTransactionsChanged());
      return _mockTransactionsController.stream;
    }

    if (currentUserId == null || _firestore == null) return Stream.value([]);

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

  // Add transaction and update customer balance
  Future<String> addTransaction(CustomerTransaction transaction) async {
    if (_isMock) {
      _mockTransactions[transaction.id] = transaction;

      // Update local customer
      if (_mockCustomers.containsKey(transaction.customerId)) {
        final cust = _mockCustomers[transaction.customerId]!;
        _mockCustomers[transaction.customerId] = cust.copyWith(
          totalCredit:
              cust.totalCredit +
              (transaction.type == TransactionType.credit
                  ? transaction.amount
                  : 0),
          totalDebit:
              cust.totalDebit +
              (transaction.type == TransactionType.debit
                  ? transaction.amount
                  : 0),
        );
        _notifyMockCustomersChanged(); // Notify customer UI
      }
      _notifyMockTransactionsChanged(); // Notify transaction UI
      return transaction.id;
    }

    if (currentUserId == null || _firestore == null) {
      throw Exception('User not logged in');
    }

    // Add transaction
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

  // Delete transaction and update customer balance
  Future<void> deleteTransaction(CustomerTransaction transaction) async {
    if (_isMock) {
      _mockTransactions.remove(transaction.id);

      // Update local customer
      if (_mockCustomers.containsKey(transaction.customerId)) {
        final cust = _mockCustomers[transaction.customerId]!;
        _mockCustomers[transaction.customerId] = cust.copyWith(
          totalCredit:
              cust.totalCredit -
              (transaction.type == TransactionType.credit
                  ? transaction.amount
                  : 0),
          totalDebit:
              cust.totalDebit -
              (transaction.type == TransactionType.debit
                  ? transaction.amount
                  : 0),
        );
        _notifyMockCustomersChanged(); // Notify customer UI
      }
      _notifyMockTransactionsChanged(); // Notify transaction UI
      return;
    }

    if (currentUserId == null || _firestore == null) return;

    // Delete transaction
    await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .collection(AppConstants.transactionsCollection)
        .doc(transaction.id)
        .delete();

    // Update customer totals
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

  // ==================== ANALYTICS ====================

  // Get dashboard totals
  Future<Map<String, double>> getDashboardTotals() async {
    if (_isMock) {
      double totalCredit = 0;
      double totalDebit = 0;
      for (var c in _mockCustomers.values) {
        totalCredit += c.totalCredit;
        totalDebit += c.totalDebit;
      }
      return {
        'credit': totalCredit,
        'debit': totalDebit,
        'balance': totalCredit - totalDebit,
      };
    }

    if (currentUserId == null || _firestore == null) {
      return {'credit': 0, 'debit': 0};
    }

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
