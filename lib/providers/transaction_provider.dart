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

  // Getters
  List<CustomerTransaction> get transactions => _transactions;
  List<CustomerTransaction> get allTransactions => _allTransactions;
  List<CustomerTransaction> get recentTransactions =>
      _allTransactions.take(10).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Start listening to all transactions
  void init() {
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
            _errorMessage = 'Error loading transactions';
            notifyListeners();
          },
        );
  }

  // Start listening to transactions for a specific customer
  void listenToCustomerTransactions(String customerId) {
    _transactionsSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _transactionsSubscription = _firebaseService
        .getTransactionsStream(customerId)
        .listen(
          (transactions) {
            _transactions = transactions;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Error loading transactions';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Stop listening to customer transactions
  void stopListeningToCustomer() {
    _transactionsSubscription?.cancel();
    _transactions = [];
    notifyListeners();
  }

  // Add a new transaction
  Future<bool> addTransaction({
    required CustomerTransaction transaction,
    required Customer customer,
    required bool sendSms,
    required String businessName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.addTransaction(transaction);

      // Send SMS if enabled
      if (sendSms && customer.phone.isNotEmpty) {
        await _smsService.sendTransactionSms(
          customer: customer,
          transaction: transaction,
          businessName: businessName,
        );
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Error adding transaction';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a transaction
  Future<bool> deleteTransaction(CustomerTransaction transaction) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.deleteTransaction(transaction);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Error deleting transaction';
      _isLoading = false;
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
    super.dispose();
  }
}
