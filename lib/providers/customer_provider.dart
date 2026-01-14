import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/customer.dart';
import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';

class CustomerProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final LocalStorageService _localStorage = LocalStorageService();

  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _customersSubscription;
  StreamSubscription? _selectedCustomerSubscription;
  StreamSubscription? _connectivitySubscription;
  String _searchQuery = '';
  bool _isOnline = true;

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
  bool get isOnline => _isOnline;

  // Statistics
  int get totalCustomers => _customers.length;
  double get totalCredit => _customers.fold(0, (sum, c) => sum + c.totalCredit);
  double get totalDebit => _customers.fold(0, (sum, c) => sum + c.totalDebit);
  double get totalBalance => totalCredit - totalDebit;
  int get customersWithOutstandingBalance =>
      _customers.where((c) => c.balance > 0).length;

  // Initialize with local storage first
  Future<void> init() async {
    await _localStorage.init();

    // Load from local storage first (instant)
    _customers = _localStorage.getCustomers();
    notifyListeners();

    // Monitor connectivity
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      _isOnline = result.first != ConnectivityResult.none;
      if (_isOnline) {
        _syncPendingChanges();
      }
      notifyListeners();
    });

    // Then try to sync with Firebase in background
    _startListening();
  }

  void _startListening() {
    _customersSubscription?.cancel();
    _customersSubscription = _firebaseService.getCustomersStream().listen(
      (customers) {
        // Merge Firebase data with local
        if (customers.isNotEmpty) {
          _customers = customers;
          _localStorage.saveCustomers(customers); // Cache locally
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        // If Firebase fails, keep using local data
        debugPrint('Firebase sync error: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Background sync pending changes to Firebase
  Future<void> _syncPendingChanges() async {
    final pending = _localStorage.getPendingSyncItems();

    for (final item in pending) {
      try {
        final type = item['type'] as String;
        final id = item['id'] as String;
        final action = item['action'] as String;

        if (type == 'customer') {
          if (action == 'add' || action == 'update') {
            final customer = _customers.firstWhere(
              (c) => c.id == id,
              orElse: () => Customer(
                id: '',
                name: '',
                shopName: '',
                phone: '',
                latitude: 0,
                longitude: 0,
                radius: 100,
                createdAt: DateTime.now(),
              ),
            );
            if (customer.id.isNotEmpty) {
              if (action == 'add') {
                await _firebaseService.addCustomer(customer);
              } else {
                await _firebaseService.updateCustomer(customer);
              }
            }
          } else if (action == 'delete') {
            await _firebaseService.deleteCustomer(id);
          }
        }

        // Remove from pending after successful sync
        await _localStorage.removePendingSyncItem(id);
      } catch (e) {
        debugPrint('Sync error for ${item['id']}: $e');
        // Keep in pending queue, will retry later
      }
    }
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
    // First try to find in local list
    try {
      _selectedCustomer = _customers.firstWhere((c) => c.id == customerId);
    } catch (e) {
      // Not found in local list, set to null temporarily
      _selectedCustomer = null;
    }
    notifyListeners();

    // Then listen for Firebase updates
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
            // Keep local data if Firebase fails
          },
        );
  }

  // Clear selected customer
  void clearSelectedCustomer() {
    _selectedCustomerSubscription?.cancel();
    _selectedCustomer = null;
    notifyListeners();
  }

  // Add a new customer - LOCAL FIRST (instant)
  Future<String?> addCustomer(Customer customer) async {
    try {
      // Save locally first - INSTANT response
      final localId = await _localStorage.addCustomerLocally(customer);

      // Update in-memory list immediately
      final newCustomer = Customer(
        id: localId,
        name: customer.name,
        shopName: customer.shopName,
        phone: customer.phone,
        latitude: customer.latitude,
        longitude: customer.longitude,
        radius: customer.radius,
        createdAt: customer.createdAt,
      );
      _customers.add(newCustomer);
      notifyListeners();

      // Sync to Firebase in background (non-blocking)
      if (_isOnline) {
        _firebaseService
            .addCustomer(customer)
            .then((firebaseId) {
              // Update local ID with Firebase ID if different
              if (firebaseId != null && firebaseId != localId) {
                final index = _customers.indexWhere((c) => c.id == localId);
                if (index != -1) {
                  _customers[index] = Customer(
                    id: firebaseId,
                    name: customer.name,
                    shopName: customer.shopName,
                    phone: customer.phone,
                    latitude: customer.latitude,
                    longitude: customer.longitude,
                    radius: customer.radius,
                    createdAt: customer.createdAt,
                  );
                  _localStorage.saveCustomers(_customers);
                  _localStorage.removePendingSyncItem(localId);
                  notifyListeners();
                }
              }
            })
            .catchError((e) {
              debugPrint('Background sync failed: $e');
              // Data is safe locally, will sync later
            });
      }

      return localId;
    } catch (e) {
      _errorMessage = 'Error adding customer';
      notifyListeners();
      return null;
    }
  }

  // Update a customer - LOCAL FIRST
  Future<bool> updateCustomer(Customer customer) async {
    try {
      // Update locally first
      await _localStorage.updateCustomerLocally(customer);

      // Update in-memory
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
        notifyListeners();
      }

      // Sync to Firebase in background
      if (_isOnline) {
        _firebaseService.updateCustomer(customer).catchError((e) {
          debugPrint('Background update failed: $e');
        });
      }

      return true;
    } catch (e) {
      _errorMessage = 'Error updating customer';
      notifyListeners();
      return false;
    }
  }

  // Delete a customer - LOCAL FIRST
  Future<bool> deleteCustomer(String customerId) async {
    try {
      // Delete locally first
      await _localStorage.deleteCustomerLocally(customerId);

      // Update in-memory
      _customers.removeWhere((c) => c.id == customerId);

      if (_selectedCustomer?.id == customerId) {
        clearSelectedCustomer();
      }
      notifyListeners();

      // Sync to Firebase in background
      if (_isOnline) {
        _firebaseService.deleteCustomer(customerId).catchError((e) {
          debugPrint('Background delete failed: $e');
        });
      }

      return true;
    } catch (e) {
      _errorMessage = 'Error deleting customer';
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
      if (_isOnline) {
        _customers = await _firebaseService.getCustomers();
        await _localStorage.saveCustomers(_customers);
      } else {
        _customers = _localStorage.getCustomers();
      }
    } catch (e) {
      _customers = _localStorage.getCustomers();
      _errorMessage = 'Using offline data';
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _customersSubscription?.cancel();
    _selectedCustomerSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
