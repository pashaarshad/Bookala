import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/transaction.dart';
import '../models/user_profile.dart';

// This is a MOCK service that works without Firebase
// Will be replaced with real Firebase after proper setup

class FirebaseService {
  // Mock Data Store
  final Map<String, Customer> _mockCustomers = {};
  final Map<String, CustomerTransaction> _mockTransactions = {};
  UserProfile? _mockUserProfile;

  FirebaseService() {
    debugPrint('FirebaseService: Running in MOCK mode');
    _initDemoData();
  }

  void _initDemoData() {
    // Add demo customer
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

  // Get current user ID
  String? get currentUserId => 'demo_user_123';
  bool get isAvailable => true;

  // ==================== USER PROFILE ====================

  Future<UserProfile?> getUserProfile() async {
    return _mockUserProfile;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    _mockUserProfile = profile;
  }

  Future<void> updateLastLogin() async {
    // Mock update
  }

  // ==================== CUSTOMERS ====================

  Stream<List<Customer>> getCustomersStream() {
    return Stream.value(_mockCustomers.values.toList());
  }

  Future<List<Customer>> getCustomers() async {
    return _mockCustomers.values.toList();
  }

  Future<Customer?> getCustomer(String customerId) async {
    return _mockCustomers[customerId];
  }

  Stream<Customer?> getCustomerStream(String customerId) {
    return Stream.value(_mockCustomers[customerId]);
  }

  Future<String> addCustomer(Customer customer) async {
    final id = 'cust_${DateTime.now().millisecondsSinceEpoch}';
    final newCustomer = Customer(
      id: id,
      name: customer.name,
      phone: customer.phone,
      shopName: customer.shopName,
      totalCredit: customer.totalCredit,
      totalDebit: customer.totalDebit,
      latitude: customer.latitude,
      longitude: customer.longitude,
      radius: customer.radius,
      createdAt: DateTime.now(),
    );
    _mockCustomers[id] = newCustomer;
    return id;
  }

  Future<void> updateCustomer(Customer customer) async {
    _mockCustomers[customer.id] = customer;
  }

  Future<void> deleteCustomer(String customerId) async {
    _mockCustomers.remove(customerId);
    _mockTransactions.removeWhere((_, t) => t.customerId == customerId);
  }

  // ==================== TRANSACTIONS ====================

  Stream<List<CustomerTransaction>> getTransactionsStream(String customerId) {
    final transactions = _mockTransactions.values
        .where((t) => t.customerId == customerId)
        .toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return Stream.value(transactions);
  }

  Stream<List<CustomerTransaction>> getAllTransactionsStream() {
    final transactions = _mockTransactions.values.toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return Stream.value(transactions);
  }

  Future<String> addTransaction(CustomerTransaction transaction) async {
    final id = 'txn_${DateTime.now().millisecondsSinceEpoch}';
    final newTxn = CustomerTransaction(
      id: id,
      customerId: transaction.customerId,
      amount: transaction.amount,
      type: transaction.type,
      description: transaction.description,
      date: transaction.date,
      createdAt: DateTime.now(),
    );
    _mockTransactions[id] = newTxn;

    // Update customer totals
    if (_mockCustomers.containsKey(transaction.customerId)) {
      final customer = _mockCustomers[transaction.customerId]!;
      if (transaction.type == TransactionType.credit) {
        _mockCustomers[transaction.customerId] = customer.copyWith(
          totalCredit: customer.totalCredit + transaction.amount,
        );
      } else {
        _mockCustomers[transaction.customerId] = customer.copyWith(
          totalDebit: customer.totalDebit + transaction.amount,
        );
      }
    }
    return id;
  }

  Future<void> deleteTransaction(CustomerTransaction transaction) async {
    _mockTransactions.remove(transaction.id);

    // Update customer totals
    if (_mockCustomers.containsKey(transaction.customerId)) {
      final customer = _mockCustomers[transaction.customerId]!;
      if (transaction.type == TransactionType.credit) {
        _mockCustomers[transaction.customerId] = customer.copyWith(
          totalCredit: customer.totalCredit - transaction.amount,
        );
      } else {
        _mockCustomers[transaction.customerId] = customer.copyWith(
          totalDebit: customer.totalDebit - transaction.amount,
        );
      }
    }
  }

  Future<List<CustomerTransaction>> getTransactions(String customerId) async {
    final transactions = _mockTransactions.values
        .where((t) => t.customerId == customerId)
        .toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }
}
