import 'transaction_item.dart';

class Transaction {
  final int? id;
  final String transactionId;
  final String? customerId;
  final String cashierId;
  final String? outletId;
  final List<TransactionItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String paymentMethod; // 'cash', 'debit', 'credit', 'qris', 'gopay', 'ovo', 'dana'
  final double? paymentAmount;
  final double? change;
  final String status; // 'pending', 'completed', 'cancelled', 'held'
  final String? notes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isSynced;

  Transaction({
    this.id,
    required this.transactionId,
    this.customerId,
    required this.cashierId,
    this.outletId,
    required this.items,
    required this.subtotal,
    this.tax = 0.0,
    this.discount = 0.0,
    required this.total,
    required this.paymentMethod,
    this.paymentAmount,
    this.change,
    this.status = 'pending',
    this.notes,
    required this.createdAt,
    this.completedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'customer_id': customerId,
      'cashier_id': cashierId,
      'outlet_id': outletId,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'payment_amount': paymentAmount,
      'change': change,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map, List<TransactionItem> items) {
    return Transaction(
      id: map['id'],
      transactionId: map['transaction_id'],
      customerId: map['customer_id'],
      cashierId: map['cashier_id'],
      outletId: map['outlet_id'],
      items: items,
      subtotal: map['subtotal'],
      tax: map['tax'],
      discount: map['discount'],
      total: map['total'],
      paymentMethod: map['payment_method'],
      paymentAmount: map['payment_amount'],
      change: map['change'],
      status: map['status'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at']) : null,
      isSynced: map['is_synced'] == 1,
    );
  }
}