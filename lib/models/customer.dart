import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String shopName;
  final String phone;
  final double latitude;
  final double longitude;
  final double radius; // geofence radius in meters
  final double totalCredit;
  final double totalDebit;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.shopName,
    required this.phone,
    required this.latitude,
    required this.longitude,
    this.radius = 100.0,
    this.totalCredit = 0.0,
    this.totalDebit = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  // Calculate balance (positive = customer owes, negative = overpaid)
  double get balance => totalCredit - totalDebit;

  // Check if customer owes money
  bool get hasOutstandingBalance => balance > 0;

  // Format balance for display
  String get formattedBalance {
    final absBalance = balance.abs();
    if (balance > 0) {
      return '₹${absBalance.toStringAsFixed(2)} due';
    } else if (balance < 0) {
      return '₹${absBalance.toStringAsFixed(2)} advance';
    }
    return 'Settled';
  }

  // Create from Firestore document
  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      name: data['name'] ?? '',
      shopName: data['shopName'] ?? '',
      phone: data['phone'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      radius: (data['radius'] ?? 100.0).toDouble(),
      totalCredit: (data['totalCredit'] ?? 0.0).toDouble(),
      totalDebit: (data['totalDebit'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'shopName': shopName,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'totalCredit': totalCredit,
      'totalDebit': totalDebit,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create a copy with updated values
  Customer copyWith({
    String? id,
    String? name,
    String? shopName,
    String? phone,
    double? latitude,
    double? longitude,
    double? radius,
    double? totalCredit,
    double? totalDebit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      shopName: shopName ?? this.shopName,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      totalCredit: totalCredit ?? this.totalCredit,
      totalDebit: totalDebit ?? this.totalDebit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // For offline storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shopName': shopName,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'totalCredit': totalCredit,
      'totalDebit': totalDebit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      shopName: json['shopName'],
      phone: json['phone'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      radius: json['radius'] ?? 100.0,
      totalCredit: json['totalCredit'] ?? 0.0,
      totalDebit: json['totalDebit'] ?? 0.0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}
