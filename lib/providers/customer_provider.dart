import 'dart:async';
import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/firebase_service.dart';

class CustomerProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _customersSubscription;
  StreamSubscription? _selectedCustomerSubscription;
  String _searchQuery = '';

  // Getters
  List<Customer> get customers => _searchQuery.isEmpty
      ? _customers
      : _customers
            .where(
              (c) =>
                  c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  c.shopName.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  c.phone.contains(_searchQuery),
            )
            .toList();

  List<Customer> get allCustomers => _customers;
  Customer? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  // Statistics
  int get totalCustomers => _customers.length;
  double get totalCredit => _customers.fold(0, (sum, c) => sum + c.totalCredit);
  double get totalDebit => _customers.fold(0, (sum, c) => sum + c.totalDebit);
  double get totalBalance => totalCredit - totalDebit;
  int get customersWithOutstandingBalance =>
      _customers.where((c) => c.balance > 0).length;

  // Initialize and start listening to customers
  void init() {
    _startListening();
  }

  void _startListening() {
    _customersSubscription?.cancel();
    _customersSubscription = _firebaseService.getCustomersStream().listen(
      (customers) {
        _customers = customers;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Error loading customers';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // Select a customer and start listening to updates
  void selectCustomer(String customerId) {
    _selectedCustomerSubscription?.cancel();
    _selectedCustomerSubscription = _firebaseService
        .getCustomerStream(customerId)
        .listen(
          (customer) {
            _selectedCustomer = customer;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Error loading customer';
            notifyListeners();
          },
        );
  }

  // Clear selected customer
  void clearSelectedCustomer() {
    _selectedCustomerSubscription?.cancel();
    _selectedCustomer = null;
    notifyListeners();
  }

  // Add a new customer
  Future<String?> addCustomer(Customer customer) async {
    try {
      _isLoading = true;
      notifyListeners();

      final id = await _firebaseService.addCustomer(customer);

      _isLoading = false;
      notifyListeners();

      return id;
    } catch (e) {
      _errorMessage = 'Error adding customer';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update a customer
  Future<bool> updateCustomer(Customer customer) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.updateCustomer(customer);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Error updating customer';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a customer
  Future<bool> deleteCustomer(String customerId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.deleteCustomer(customerId);

      if (_selectedCustomer?.id == customerId) {
        clearSelectedCustomer();
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Error deleting customer';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh customers
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      _customers = await _firebaseService.getCustomers();
    } catch (e) {
      _errorMessage = 'Error refreshing customers';
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _customersSubscription?.cancel();
    _selectedCustomerSubscription?.cancel();
    super.dispose();
  }
}
