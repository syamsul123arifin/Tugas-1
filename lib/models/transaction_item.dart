class TransactionItem {
  final int? id;
  final String transactionId;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double discount;
  final double total;
  final String? notes;

  TransactionItem({
    this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.discount = 0.0,
    required this.total,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'discount': discount,
      'total': total,
      'notes': notes,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      transactionId: map['transaction_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      unitPrice: map['unit_price'],
      quantity: map['quantity'],
      discount: map['discount'],
      total: map['total'],
      notes: map['notes'],
    );
  }

  TransactionItem copyWith({
    int? id,
    String? transactionId,
    String? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
    double? discount,
    double? total,
    String? notes,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      notes: notes ?? this.notes,
    );
  }
}