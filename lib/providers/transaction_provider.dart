import 'dart:async';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/customer.dart';
import '../services/firebase_service.dart';
import '../services/sms_service.dart';

class TransactionProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final SmsService _smsService = SmsService();

  List<CustomerTransaction> _transactions = [];
  List<CustomerTransaction> _allTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _allTransactionsSubscription;
  String? _currentCustomerId;

  // Getters
  List<CustomerTransaction> get transactions => _transactions;
  List<CustomerTransaction> get allTransactions => _allTransactions;
  List<CustomerTransaction> get recentTransactions =>
      _allTransactions.take(10).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize
  Future<void> init() async {
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

  // Start listening to transactions for a specific customer
  void listenToCustomerTransactions(String customerId) {
    _currentCustomerId = customerId;
    _isLoading = true;
    notifyListeners();

    _transactionsSubscription?.cancel();
    _transactionsSubscription = _firebaseService
        .getTransactionsStream(customerId)
        .listen(
          (transactions) {
            _transactions = transactions;
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

  // Add a new transaction - FIREBASE DIRECT
  Future<bool> addTransaction({
    required CustomerTransaction transaction,
    required Customer customer,
    required bool sendSms,
    required String businessName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Save to Firebase
      await _firebaseService.addTransaction(transaction);

      _isLoading = false;
      notifyListeners();

      // Send SMS in background (non-blocking)
      if (sendSms && customer.phone.isNotEmpty) {
        _sendSmsInBackground(customer, transaction, businessName);
      }

      return true;
    } catch (e) {
      _errorMessage = 'Error adding transaction: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Send SMS in background
  void _sendSmsInBackground(
    Customer customer,
    CustomerTransaction transaction,
    String businessName,
  ) {
    Future(() async {
      try {
        final success = await _smsService.sendTransactionSms(
          customer: customer,
          transaction: transaction,
          businessName: businessName,
        );
        if (success) {
          debugPrint('SMS sent successfully to ${customer.phone}');
        } else {
          debugPrint('SMS sending failed for ${customer.phone}');
        }
      } catch (e) {
        debugPrint('SMS error: $e');
      }
    });
  }

  // Delete a transaction - FIREBASE DIRECT
  Future<bool> deleteTransaction(CustomerTransaction transaction) async {
    try {
      await _firebaseService.deleteTransaction(transaction);
      return true;
    } catch (e) {
      _errorMessage = 'Error deleting transaction';
      notifyListeners();
      return false;
    }
  }

  // Get transactions summary for a customer
  Map<String, double> getCustomerSummary(String customerId) {
    final customerTxns = _transactions
        .where((t) => t.customerId == customerId)
        .toList();

    double totalCredit = 0;
    double totalDebit = 0;

    for (var t in customerTxns) {
      if (t.type == TransactionType.credit) {
        totalCredit += t.amount;
      } else {
        totalDebit += t.amount;
      }
    }

    return {
      'totalCredit': totalCredit,
      'totalDebit': totalDebit,
      'balance': totalCredit - totalDebit,
    };
  }

  // Get transactions by date range
  List<CustomerTransaction> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return _allTransactions
        .where((t) => t.date.isAfter(start) && t.date.isBefore(end))
        .toList();
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
    super.dispose();
  }
}
