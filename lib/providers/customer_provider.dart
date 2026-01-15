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
  String _searchQuery = '';
  StreamSubscription? _customersSubscription;
  StreamSubscription? _selectedCustomerSubscription;

  // Getters
  List<Customer> get customers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers
        .where(
          (c) =>
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.shopName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.phone.contains(_searchQuery),
        )
        .toList();
  }

  // All customers without filtering (for location-based features)
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

  // Initialize - Start listening to Firebase
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
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
        debugPrint('Firebase customers error: $error');
        _errorMessage = 'Failed to load customers';
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

  // Select a customer
  void selectCustomer(String customerId) {
    // Find in current list first
    try {
      _selectedCustomer = _customers.firstWhere((c) => c.id == customerId);
    } catch (e) {
      _selectedCustomer = null;
    }
    notifyListeners();

    // Listen for real-time updates
    _selectedCustomerSubscription?.cancel();
    _selectedCustomerSubscription = _firebaseService
        .getCustomerStream(customerId)
        .listen(
          (customer) {
            _selectedCustomer = customer;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Customer stream error: $error');
          },
        );
  }

  // Clear selected customer
  void clearSelectedCustomer() {
    _selectedCustomerSubscription?.cancel();
    _selectedCustomer = null;
    notifyListeners();
  }

  // Add a new customer - FIREBASE DIRECT
  Future<String?> addCustomer(Customer customer) async {
    try {
      _isLoading = true;
      notifyListeners();

      final id = await _firebaseService.addCustomer(customer);

      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _errorMessage = 'Error adding customer: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update a customer - FIREBASE DIRECT
  Future<bool> updateCustomer(Customer customer) async {
    try {
      await _firebaseService.updateCustomer(customer);

      // Update selected customer if it's the same
      if (_selectedCustomer?.id == customer.id) {
        _selectedCustomer = customer;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error updating customer';
      notifyListeners();
      return false;
    }
  }

  // Delete a customer - FIREBASE DIRECT
  Future<bool> deleteCustomer(String customerId) async {
    try {
      await _firebaseService.deleteCustomer(customerId);

      if (_selectedCustomer?.id == customerId) {
        clearSelectedCustomer();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Error deleting customer';
      notifyListeners();
      return false;
    }
  }

  // Get customers sorted by balance (for reports)
  List<Customer> getCustomersByBalance({bool descending = true}) {
    final sorted = List<Customer>.from(_customers);
    sorted.sort(
      (a, b) => descending
          ? b.balance.compareTo(a.balance)
          : a.balance.compareTo(b.balance),
    );
    return sorted;
  }

  // Get customers with outstanding balance
  List<Customer> getCustomersWithOutstanding() {
    return _customers.where((c) => c.balance > 0).toList();
  }

  // Check if customer is nearby (for location-based features)
  bool isCustomerNearby(Customer customer, double userLat, double userLng) {
    if (customer.latitude == 0 && customer.longitude == 0) return false;

    // Simple distance calculation (approximate)
    final latDiff = (customer.latitude - userLat).abs();
    final lngDiff = (customer.longitude - userLng).abs();
    final approxDistance = (latDiff + lngDiff) * 111000; // roughly in meters

    return approxDistance <= customer.radius;
  }

  // Get nearby customers
  List<Customer> getNearbyCustomers(double userLat, double userLng) {
    return _customers
        .where((c) => isCustomerNearby(c, userLat, userLng))
        .toList();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _customersSubscription?.cancel();
    _selectedCustomerSubscription?.cancel();
    super.dispose();
  }
}
