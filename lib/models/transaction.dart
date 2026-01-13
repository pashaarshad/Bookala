import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { credit, debit }

class CustomerTransaction {
  final String id;
  final String customerId;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime date;
  final bool smsSent;
  final DateTime createdAt;
  final bool synced; // For offline support

  CustomerTransaction({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    this.description = '',
    required this.date,
    this.smsSent = false,
    required this.createdAt,
    this.synced = true,
  });

  // Check if this is income for the shop owner
  bool get isIncome => type == TransactionType.credit;

  // Format amount for display
  String get formattedAmount {
    final prefix = type == TransactionType.credit ? '+' : '-';
    return '$prefix₹${amount.toStringAsFixed(2)}';
  }

  // Get display color
  String get typeLabel => type == TransactionType.credit ? 'Credit' : 'Debit';

  // Create from Firestore document
  factory CustomerTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerTransaction(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      type: data['type'] == 'credit'
          ? TransactionType.credit
          : TransactionType.debit,
      amount: (data['amount'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      smsSent: data['smsSent'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      synced: true,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'type': type == TransactionType.credit ? 'credit' : 'debit',
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
      'smsSent': smsSent,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a copy with updated values
  CustomerTransaction copyWith({
    String? id,
    String? customerId,
    TransactionType? type,
    double? amount,
    String? description,
    DateTime? date,
    bool? smsSent,
    DateTime? createdAt,
    bool? synced,
  }) {
    return CustomerTransaction(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      smsSent: smsSent ?? this.smsSent,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  // For offline storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'type': type == TransactionType.credit ? 'credit' : 'debit',
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'smsSent': smsSent,
      'createdAt': createdAt.toIso8601String(),
      'synced': synced,
    };
  }

  factory CustomerTransaction.fromJson(Map<String, dynamic> json) {
    return CustomerTransaction(
      id: json['id'],
      customerId: json['customerId'],
      type: json['type'] == 'credit'
          ? TransactionType.credit
          : TransactionType.debit,
      amount: json['amount'],
      description: json['description'] ?? '',
      date: DateTime.parse(json['date']),
      smsSent: json['smsSent'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      synced: json['synced'] ?? false,
    );
  }
}
