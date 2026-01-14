import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer.dart';
import '../models/transaction.dart';

/// LocalStorageService - Offline-first data storage
///
/// Stores all data locally first for fast access,
/// then syncs to Firebase in the background.
class LocalStorageService {
  static const String _customersKey = 'local_customers';
  static const String _transactionsKey = 'local_transactions';
  static const String _pendingSyncKey = 'pending_sync';
  static const String _userProfileKey = 'user_profile';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception(
        'LocalStorageService not initialized. Call init() first.',
      );
    }
    return _prefs!;
  }

  // ==================== CUSTOMERS ====================

  /// Save all customers to local storage
  Future<void> saveCustomers(List<Customer> customers) async {
    final List<String> jsonList = customers
        .map((c) => jsonEncode(c.toJson()))
        .toList();
    await prefs.setStringList(_customersKey, jsonList);
  }

  /// Get all customers from local storage
  List<Customer> getCustomers() {
    final List<String>? jsonList = prefs.getStringList(_customersKey);
    if (jsonList == null || jsonList.isEmpty) return [];

    return jsonList.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return Customer.fromJson(map);
    }).toList();
  }

  /// Add a single customer locally
  Future<String> addCustomerLocally(Customer customer) async {
    final customers = getCustomers();

    // Generate local ID if not present
    final localId = customer.id.isEmpty
        ? 'local_${DateTime.now().millisecondsSinceEpoch}'
        : customer.id;

    final newCustomer = Customer(
      id: localId,
      name: customer.name,
      shopName: customer.shopName,
      phone: customer.phone,
      latitude: customer.latitude,
      longitude: customer.longitude,
      radius: customer.radius,
      totalCredit: customer.totalCredit,
      totalDebit: customer.totalDebit,
      createdAt: customer.createdAt,
    );

    customers.add(newCustomer);
    await saveCustomers(customers);

    // Mark for sync
    await _addToPendingSync('customer', localId, 'add');

    return localId;
  }

  /// Update a customer locally
  Future<void> updateCustomerLocally(Customer customer) async {
    final customers = getCustomers();
    final index = customers.indexWhere((c) => c.id == customer.id);

    if (index != -1) {
      customers[index] = customer;
      await saveCustomers(customers);
      await _addToPendingSync('customer', customer.id, 'update');
    }
  }

  /// Delete a customer locally
  Future<void> deleteCustomerLocally(String customerId) async {
    final customers = getCustomers();
    customers.removeWhere((c) => c.id == customerId);
    await saveCustomers(customers);
    await _addToPendingSync('customer', customerId, 'delete');
  }

  // ==================== TRANSACTIONS ====================

  /// Save all transactions to local storage
  Future<void> saveTransactions(
    String customerId,
    List<CustomerTransaction> transactions,
  ) async {
    final key = '${_transactionsKey}_$customerId';
    final List<String> jsonList = transactions
        .map((t) => jsonEncode(t.toJson()))
        .toList();
    await prefs.setStringList(key, jsonList);
  }

  /// Get all transactions for a customer from local storage
  List<CustomerTransaction> getTransactions(String customerId) {
    final key = '${_transactionsKey}_$customerId';
    final List<String>? jsonList = prefs.getStringList(key);
    if (jsonList == null || jsonList.isEmpty) return [];

    return jsonList.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return CustomerTransaction.fromJson(map);
    }).toList();
  }

  /// Add a transaction locally
  Future<String> addTransactionLocally(CustomerTransaction transaction) async {
    final transactions = getTransactions(transaction.customerId);

    // Generate local ID if not present
    final localId = transaction.id.isEmpty
        ? 'local_${DateTime.now().millisecondsSinceEpoch}'
        : transaction.id;

    final newTransaction = CustomerTransaction(
      id: localId,
      customerId: transaction.customerId,
      amount: transaction.amount,
      type: transaction.type,
      description: transaction.description,
      date: transaction.date,
      createdAt: DateTime.now(),
    );

    transactions.add(newTransaction);
    await saveTransactions(transaction.customerId, transactions);

    // Update customer balance locally
    await _updateCustomerBalanceLocally(
      transaction.customerId,
      transaction.amount,
      transaction.type,
    );

    // Mark for sync
    await _addToPendingSync('transaction', localId, 'add');

    return localId;
  }

  /// Update customer balance after transaction
  Future<void> _updateCustomerBalanceLocally(
    String customerId,
    double amount,
    TransactionType type,
  ) async {
    final customers = getCustomers();
    final index = customers.indexWhere((c) => c.id == customerId);

    if (index != -1) {
      final customer = customers[index];
      double newCredit = customer.totalCredit;
      double newDebit = customer.totalDebit;

      if (type == TransactionType.credit) {
        newCredit += amount;
      } else {
        newDebit += amount;
      }

      customers[index] = Customer(
        id: customer.id,
        name: customer.name,
        shopName: customer.shopName,
        phone: customer.phone,
        latitude: customer.latitude,
        longitude: customer.longitude,
        radius: customer.radius,
        totalCredit: newCredit,
        totalDebit: newDebit,
        createdAt: customer.createdAt,
      );

      await saveCustomers(customers);
    }
  }

  /// Delete a transaction locally
  Future<void> deleteTransactionLocally(CustomerTransaction transaction) async {
    final transactions = getTransactions(transaction.customerId);
    transactions.removeWhere((t) => t.id == transaction.id);
    await saveTransactions(transaction.customerId, transactions);

    // Reverse the balance change
    await _updateCustomerBalanceLocally(
      transaction.customerId,
      -transaction.amount, // Negative to reverse
      transaction.type,
    );

    await _addToPendingSync('transaction', transaction.id, 'delete');
  }

  // ==================== PENDING SYNC ====================

  /// Add item to pending sync queue
  Future<void> _addToPendingSync(String type, String id, String action) async {
    final pending = getPendingSyncItems();
    pending.add({
      'type': type,
      'id': id,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });

    final jsonList = pending.map((p) => jsonEncode(p)).toList();
    await prefs.setStringList(_pendingSyncKey, jsonList);
  }

  /// Get all pending sync items
  List<Map<String, dynamic>> getPendingSyncItems() {
    final List<String>? jsonList = prefs.getStringList(_pendingSyncKey);
    if (jsonList == null || jsonList.isEmpty) return [];

    return jsonList
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
  }

  /// Clear pending sync queue after successful sync
  Future<void> clearPendingSync() async {
    await prefs.setStringList(_pendingSyncKey, []);
  }

  /// Remove specific item from pending sync
  Future<void> removePendingSyncItem(String id) async {
    final pending = getPendingSyncItems();
    pending.removeWhere((p) => p['id'] == id);

    final jsonList = pending.map((p) => jsonEncode(p)).toList();
    await prefs.setStringList(_pendingSyncKey, jsonList);
  }

  // ==================== USER PROFILE ====================

  /// Save user profile locally
  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    await prefs.setString(_userProfileKey, jsonEncode(profile));
  }

  /// Get user profile from local storage
  Map<String, dynamic>? getUserProfile() {
    final json = prefs.getString(_userProfileKey);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  /// Clear all local data (for logout)
  Future<void> clearAll() async {
    await prefs.remove(_customersKey);
    await prefs.remove(_pendingSyncKey);
    await prefs.remove(_userProfileKey);

    // Clear all transaction keys
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_transactionsKey)) {
        await prefs.remove(key);
      }
    }
  }
}
