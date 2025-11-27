import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/transaction_item.dart';
import '../models/transaction.dart' as models;
import '../database/database_helper.dart';
import 'auth_provider.dart';

class CartProvider with ChangeNotifier {
  final List<TransactionItem> _items = [];
  Customer? _selectedCustomer;
  double _discount = 0.0;
  String _paymentMethod = 'cash';
  double _paymentAmount = 0.0;
  bool _isProcessing = false;

  List<TransactionItem> get items => _items;
  Customer? get selectedCustomer => _selectedCustomer;
  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get discount => _discount;
  double get tax => subtotal * 0.1; // 10% tax
  double get total => subtotal + tax - discount;
  String get paymentMethod => _paymentMethod;
  double get paymentAmount => _paymentAmount;
  double get change => _paymentAmount - total;
  bool get isProcessing => _isProcessing;
  bool get canProcessPayment => _items.isNotEmpty && _paymentAmount >= total;

  void addProduct(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere(
      (item) => item.productId == product.id.toString(),
    );

    if (existingIndex >= 0) {
      // Update existing item
      final existingItem = _items[existingIndex];
      final newQuantity = existingItem.quantity + quantity;
      final newTotal = existingItem.unitPrice * newQuantity;

      _items[existingIndex] = existingItem.copyWith(
        quantity: newQuantity,
        total: newTotal,
      );
    } else {
      // Add new item
      final item = TransactionItem(
        transactionId: '', // Will be set when processing
        productId: product.id.toString(),
        productName: product.name,
        unitPrice: product.price,
        quantity: quantity,
        total: product.price * quantity,
      );
      _items.add(item);
    }

    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void updateItemQuantity(int index, int quantity) {
    if (index >= 0 && index < _items.length && quantity > 0) {
      final item = _items[index];
      final newTotal = item.unitPrice * quantity;

      _items[index] = item.copyWith(
        quantity: quantity,
        total: newTotal,
      );
      notifyListeners();
    }
  }

  void setDiscount(double discount) {
    _discount = discount;
    notifyListeners();
  }

  void setCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setPaymentAmount(double amount) {
    _paymentAmount = amount;
    notifyListeners();
  }

  Future<bool> processPayment() async {
    if (!canProcessPayment) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final db = DatabaseHelper();
      final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';

      // Update transaction IDs for items
      final itemsWithTransactionId = _items.map((item) =>
        item.copyWith(transactionId: transactionId)
      ).toList();

      // Create transaction
      final transaction = models.Transaction(
        transactionId: transactionId,
        customerId: _selectedCustomer?.id?.toString(),
        cashierId: 'cashier', // Default cashier ID
        outletId: 'main', // Default outlet ID
        items: itemsWithTransactionId,
        subtotal: subtotal,
        tax: tax,
        discount: discount,
        total: total,
        paymentMethod: paymentMethod,
        paymentAmount: paymentAmount,
        change: change,
        status: 'completed',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      // Save to database
      await db.insertTransaction(transaction);

      // Update product stock
      for (var item in itemsWithTransactionId) {
        final product = await db.getProductByBarcode(item.productId);
        if (product != null) {
          await db.updateProductStock(product.id!, product.stock - item.quantity);
        }
      }

      // Update customer loyalty points if applicable
      if (_selectedCustomer != null) {
        // Add points based on transaction total (1 point per 1000 spent)
        final pointsEarned = (total ~/ 1000);
        // Note: In a real app, you'd update customer points in database
      }

      // Clear cart
      clearCart();

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  void clearCart() {
    _items.clear();
    _selectedCustomer = null;
    _discount = 0.0;
    _paymentAmount = 0.0;
    _paymentMethod = 'cash';
    notifyListeners();
  }

  // Hold order functionality
  Future<bool> holdOrder() async {
    if (_items.isEmpty) return false;

    try {
      final db = DatabaseHelper();
      final transactionId = 'HOLD${DateTime.now().millisecondsSinceEpoch}';

      // Update transaction IDs for items
      final itemsWithTransactionId = _items.map((item) =>
        item.copyWith(transactionId: transactionId)
      ).toList();

      // Create held transaction
      final transaction = models.Transaction(
        transactionId: transactionId,
        customerId: _selectedCustomer?.id?.toString(),
        cashierId: 'cashier', // Default cashier ID
        outletId: 'main', // Default outlet ID
        items: itemsWithTransactionId,
        subtotal: subtotal,
        tax: tax,
        discount: discount,
        total: total,
        paymentMethod: paymentMethod,
        status: 'held',
        createdAt: DateTime.now(),
      );

      await db.insertTransaction(transaction);
      clearCart();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Resume held order
  void resumeHeldOrder(models.Transaction heldTransaction) {
    clearCart();

    _items.addAll(heldTransaction.items);
    _discount = heldTransaction.discount;
    _paymentMethod = heldTransaction.paymentMethod;

    // Note: Customer selection would need to be restored from database
    notifyListeners();
  }
}