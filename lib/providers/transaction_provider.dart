import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/transaction.dart';
import '../models/customer.dart';
import '../services/firebase_service.dart';
import '../services/sms_service.dart';
import '../services/local_storage_service.dart';

class TransactionProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final SmsService _smsService = SmsService();
  final LocalStorageService _localStorage = LocalStorageService();

  List<CustomerTransaction> _transactions = [];
  List<CustomerTransaction> _allTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _allTransactionsSubscription;
  StreamSubscription? _connectivitySubscription;
  bool _isOnline = true;
  String? _currentCustomerId;

  // Getters
  List<CustomerTransaction> get transactions => _transactions;
  List<CustomerTransaction> get allTransactions => _allTransactions;
  List<CustomerTransaction> get recentTransactions =>
      _allTransactions.take(10).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _isOnline;

  // Initialize with local storage first
  Future<void> init() async {
    await _localStorage.init();

    // Monitor connectivity
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      _isOnline = result.first != ConnectivityResult.none;
      if (_isOnline) {
        _syncPendingTransactions();
      }
      notifyListeners();
    });

    _startListeningToAll();
  }

  void _startListeningToAll() {
    _allTransactionsSubscription?.cancel();
    _allTransactionsSubscription = _firebaseService
        .getAllTransactionsStream()
        .listen(
          (transactions) {
            _allTransactions = transactions;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Transaction stream error: $error');
          },
        );
  }

  // Background sync pending transactions
  Future<void> _syncPendingTransactions() async {
    final pending = _localStorage.getPendingSyncItems();

    for (final item in pending) {
      try {
        if (item['type'] == 'transaction') {
          final id = item['id'] as String;
          final action = item['action'] as String;

          if (action == 'add') {
            // Find the transaction in local storage
            if (_currentCustomerId != null) {
              final localTransactions = _localStorage.getTransactions(
                _currentCustomerId!,
              );
              final transaction = localTransactions.firstWhere(
                (t) => t.id == id,
                orElse: () => CustomerTransaction(
                  id: '',
                  customerId: '',
                  type: TransactionType.credit,
                  amount: 0,
                  date: DateTime.now(),
                  createdAt: DateTime.now(),
                ),
              );
              if (transaction.id.isNotEmpty) {
                await _firebaseService.addTransaction(transaction);
              }
            }
          } else if (action == 'delete') {
            // Already deleted from Firebase or will be handled
          }

          await _localStorage.removePendingSyncItem(id);
        }
      } catch (e) {
        debugPrint('Transaction sync error: $e');
      }
    }
  }

  // Start listening to transactions for a specific customer
  void listenToCustomerTransactions(String customerId) {
    _currentCustomerId = customerId;

    // Load from local storage first (instant)
    _transactions = _localStorage.getTransactions(customerId);
    notifyListeners();

    // Then listen to Firebase
    _transactionsSubscription?.cancel();
    _transactionsSubscription = _firebaseService
        .getTransactionsStream(customerId)
        .listen(
          (transactions) {
            if (transactions.isNotEmpty) {
              _transactions = transactions;
              _localStorage.saveTransactions(customerId, transactions);
            }
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Customer transactions error: $error');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Stop listening to customer transactions
  void stopListeningToCustomer() {
    _transactionsSubscription?.cancel();
    _currentCustomerId = null;
    _transactions = [];
    notifyListeners();
  }

  // Add a new transaction - LOCAL FIRST (instant)
  Future<bool> addTransaction({
    required CustomerTransaction transaction,
    required Customer customer,
    required bool sendSms,
    required String businessName,
  }) async {
    try {
      // Save locally first - INSTANT response
      final localId = await _localStorage.addTransactionLocally(transaction);

      // Add to in-memory list immediately
      final newTransaction = CustomerTransaction(
        id: localId,
        customerId: transaction.customerId,
        type: transaction.type,
        amount: transaction.amount,
        description: transaction.description,
        date: transaction.date,
        createdAt: DateTime.now(),
      );
      _transactions.insert(0, newTransaction);
      notifyListeners();

      // Send SMS in background (non-blocking, fully automatic)
      if (sendSms && customer.phone.isNotEmpty) {
        _sendSmsInBackground(customer, transaction, businessName);
      }

      // Sync to Firebase in background (non-blocking)
      if (_isOnline) {
        _firebaseService
            .addTransaction(transaction)
            .then((_) {
              _localStorage.removePendingSyncItem(localId);
            })
            .catchError((e) {
              debugPrint('Background transaction sync failed: $e');
            });
      }

      return true;
    } catch (e) {
      _errorMessage = 'Error adding transaction';
      notifyListeners();
      return false;
    }
  }

  // Send SMS completely in background (no user interaction)
  void _sendSmsInBackground(
    Customer customer,
    CustomerTransaction transaction,
    String businessName,
  ) {
    // Fire and forget - don't wait for it
    Future(() async {
      try {
        await _smsService.sendTransactionSms(
          customer: customer,
          transaction: transaction,
          businessName: businessName,
        );
        debugPrint('SMS sent successfully to ${customer.phone}');
      } catch (e) {
        debugPrint('Background SMS failed: $e');
      }
    });
  }

  // Delete a transaction - LOCAL FIRST
  Future<bool> deleteTransaction(CustomerTransaction transaction) async {
    try {
      // Delete locally first
      await _localStorage.deleteTransactionLocally(transaction);

      // Update in-memory
      _transactions.removeWhere((t) => t.id == transaction.id);
      notifyListeners();

      // Sync to Firebase in background
      if (_isOnline) {
        _firebaseService.deleteTransaction(transaction).catchError((e) {
          debugPrint('Background delete failed: $e');
        });
      }

      return true;
    } catch (e) {
      _errorMessage = 'Error deleting transaction';
      notifyListeners();
      return false;
    }
  }

  // Get transactions summary for a date range
  Map<String, double> getTransactionsSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final filteredTransactions = _allTransactions.where((t) {
      if (startDate != null && t.date.isBefore(startDate)) return false;
      if (endDate != null && t.date.isAfter(endDate)) return false;
      return true;
    });

    double totalCredit = 0;
    double totalDebit = 0;

    for (final t in filteredTransactions) {
      if (t.type == TransactionType.credit) {
        totalCredit += t.amount;
      } else {
        totalDebit += t.amount;
      }
    }

    return {
      'credit': totalCredit,
      'debit': totalDebit,
      'net': totalCredit - totalDebit,
    };
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    _allTransactionsSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
