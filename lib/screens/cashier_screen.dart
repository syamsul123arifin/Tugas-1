import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/customer.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _paymentController = TextEditingController();
  bool _isScanning = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _paymentController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _searchProduct(String query) async {
    if (query.isEmpty) return;

    try {
      final db = DatabaseHelper();
      Product? product;

      // Try to find by barcode first
      product = await db.getProductByBarcode(query);

      // If not found by barcode, search by name (simplified)
      if (product == null) {
        final products = await db.getAllProducts();
        product = products.where((p) =>
          p.name.toLowerCase().contains(query.toLowerCase()) ||
          (p.barcode != null && p.barcode!.contains(query))
        ).firstOrNull;
      }

      if (product != null && mounted) {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        final quantity = int.tryParse(_quantityController.text) ?? 1;
        cartProvider.addProduct(product, quantity: quantity);

        _searchController.clear();
        _quantityController.text = '1';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${product.name} to cart')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error searching product')),
      );
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first.rawValue;
      if (barcode != null) {
        _searchController.text = barcode;
        _searchProduct(barcode);
        setState(() {
          _isScanning = false;
        });
        _scannerController?.stop();
      }
    }
  }

  Future<void> _selectCustomer() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    try {
      final db = DatabaseHelper();
      final customers = await db.getAllCustomers();

      if (!mounted) return;

      final selectedCustomer = await showDialog<Customer>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Customer'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: customers.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    title: const Text('Walk-in Customer'),
                    onTap: () => Navigator.of(context).pop(null),
                  );
                }

                final customer = customers[index - 1];
                return ListTile(
                  title: Text(customer.name),
                  subtitle: customer.phone != null ? Text(customer.phone!) : null,
                  onTap: () => Navigator.of(context).pop(customer),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selectedCustomer != null) {
        cartProvider.setCustomer(selectedCustomer);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading customers')),
      );
    }
  }

  Future<void> _processPayment() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    final success = await cartProvider.processPayment();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment processed successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Show receipt dialog
      _showReceiptDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment processing failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReceiptDialog() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receipt'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Transaction Complete', style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              ...cartProvider.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.productName} x${item.quantity}')),
                    Text('Rp ${item.total.toStringAsFixed(0)}'),
                  ],
                ),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:'),
                  Text('Rp ${cartProvider.subtotal.toStringAsFixed(0)}'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tax:'),
                  Text('Rp ${cartProvider.tax.toStringAsFixed(0)}'),
                ],
              ),
              if (cartProvider.discount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount:'),
                    Text('-Rp ${cartProvider.discount.toStringAsFixed(0)}'),
                  ],
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Rp ${cartProvider.total.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Payment (${cartProvider.paymentMethod}):'),
                  Text('Rp ${cartProvider.paymentAmount.toStringAsFixed(0)}'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Change:'),
                  Text('Rp ${cartProvider.change.toStringAsFixed(0)}'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement receipt printing
              Navigator.of(context).pop();
            },
            child: const Text('Print Receipt'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Row(
        children: [
          // Left panel - Product search and cart
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search product by name or scan barcode...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: _searchProduct,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            hintText: 'Qty',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () {
                          setState(() {
                            _isScanning = !_isScanning;
                          });
                          if (_isScanning) {
                            _scannerController?.start();
                          } else {
                            _scannerController?.stop();
                          }
                        },
                        tooltip: 'Scan Barcode',
                      ),
                    ],
                  ),
                ),

                // Scanner view
                if (_isScanning)
                  Container(
                    height: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: MobileScanner(
                      controller: _scannerController!,
                      onDetect: _onBarcodeDetected,
                    ),
                  ),

                // Cart items
                Expanded(
                  child: ListView.builder(
                    itemCount: cartProvider.items.length,
                    itemBuilder: (context, index) {
                      final item = cartProvider.items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(item.productName),
                          subtitle: Text('Rp ${item.unitPrice.toStringAsFixed(0)} x ${item.quantity}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Rp ${item.total.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => cartProvider.removeItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right panel - Payment
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Customer info
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(cartProvider.selectedCustomer?.name ?? 'Walk-in Customer'),
                      subtitle: cartProvider.selectedCustomer?.phone != null
                          ? Text(cartProvider.selectedCustomer!.phone!)
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _selectCustomer,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Order summary
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('Rp ${cartProvider.subtotal.toStringAsFixed(0)}'),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tax (10%):'),
                      Text('Rp ${cartProvider.tax.toStringAsFixed(0)}'),
                    ],
                  ),

                  if (cartProvider.discount > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:'),
                        Text('-Rp ${cartProvider.discount.toStringAsFixed(0)}'),
                      ],
                    ),

                  const Divider(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rp ${cartProvider.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Payment method
                  const Text('Payment Method'),
                  DropdownButton<String>(
                    value: cartProvider.paymentMethod,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'debit', child: Text('Debit Card')),
                      DropdownMenuItem(value: 'credit', child: Text('Credit Card')),
                      DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                      DropdownMenuItem(value: 'gopay', child: Text('GoPay')),
                      DropdownMenuItem(value: 'ovo', child: Text('OVO')),
                      DropdownMenuItem(value: 'dana', child: Text('Dana')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        cartProvider.setPaymentMethod(value);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Payment amount
                  TextField(
                    controller: _paymentController,
                    decoration: const InputDecoration(
                      labelText: 'Payment Amount',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final amount = double.tryParse(value.replaceAll('Rp ', '')) ?? 0;
                      cartProvider.setPaymentAmount(amount);
                    },
                  ),

                  const SizedBox(height: 8),

                  // Change
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Change:'),
                      Text(
                        'Rp ${cartProvider.change.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: cartProvider.change >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: cartProvider.items.isNotEmpty
                              ? () async {
                                  final success = await cartProvider.holdOrder();
                                  if (success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Order held successfully')),
                                    );
                                  }
                                }
                              : null,
                          child: const Text('Hold Order'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: cartProvider.canProcessPayment && !cartProvider.isProcessing
                              ? _processPayment
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: cartProvider.isProcessing
                              ? const CircularProgressIndicator()
                              : const Text('Process Payment'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  OutlinedButton(
                    onPressed: cartProvider.items.isNotEmpty
                        ? () => cartProvider.clearCart()
                        : null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text(
                      'Clear Cart',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}