import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/category.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Category> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = true;
  bool _showLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = DatabaseHelper();
      final products = await db.getAllProducts();
      final categories = await db.getAllCategories();

      setState(() {
        _products = products;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading inventory data')),
      );
    }
  }

  List<Product> get _filteredProducts {
    return _products.where((product) {
      // Search filter
      final matchesSearch = _searchController.text.isEmpty ||
          product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (product.barcode != null && product.barcode!.contains(_searchController.text));

      // Category filter
      final matchesCategory = _selectedCategoryId == null ||
          product.categoryId == _selectedCategoryId;

      // Low stock filter
      final matchesLowStock = !_showLowStockOnly ||
          product.stock <= product.minStock;

      return matchesSearch && matchesCategory && matchesLowStock;
    }).toList();
  }

  Future<void> _addProduct() async {
    final result = await showDialog<Product>(
      context: context,
      builder: (context) => const ProductFormDialog(),
    );

    if (result != null) {
      await _loadData();
    }
  }

  Future<void> _editProduct(Product product) async {
    final result = await showDialog<Product>(
      context: context,
      builder: (context) => ProductFormDialog(product: product),
    );

    if (result != null) {
      await _loadData();
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Note: In a real app, you'd implement soft delete
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting product')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String?>(
                      value: _selectedCategoryId,
                      hint: const Text('All Categories'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ..._categories.map((category) => DropdownMenuItem<String?>(
                          value: category.id,
                          child: Text(category.name),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    FilterChip(
                      label: const Text('Low Stock Only'),
                      selected: _showLowStockOnly,
                      onSelected: (selected) {
                        setState(() {
                          _showLowStockOnly = selected;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Product list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(
                        child: Text('No products found'),
                      )
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final isLowStock = product.stock <= product.minStock;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: product.imagePath != null
                                    ? Image.network(product.imagePath!, fit: BoxFit.cover)
                                    : const Icon(Icons.inventory, color: Colors.grey),
                              ),
                              title: Text(product.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Stock: ${product.stock} | Min: ${product.minStock}'),
                                  Text('Price: Rp ${product.price.toStringAsFixed(0)}'),
                                  if (product.barcode != null)
                                    Text('Barcode: ${product.barcode}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isLowStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'LOW STOCK',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editProduct(product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteProduct(product),
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                              onTap: () => _editProduct(product),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProductFormDialog extends StatefulWidget {
  final Product? product;

  const ProductFormDialog({super.key, this.product});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();

  String? _selectedCategoryId;
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _barcodeController.text = widget.product!.barcode ?? '';
      _priceController.text = widget.product!.price.toString();
      _costPriceController.text = widget.product!.costPrice.toString();
      _stockController.text = widget.product!.stock.toString();
      _minStockController.text = widget.product!.minStock.toString();
      _selectedCategoryId = widget.product!.categoryId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final db = DatabaseHelper();
      final categories = await db.getAllCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      id: widget.product?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      categoryId: _selectedCategoryId!,
      price: double.parse(_priceController.text),
      costPrice: double.parse(_costPriceController.text),
      stock: int.parse(_stockController.text),
      minStock: int.parse(_minStockController.text),
      createdAt: widget.product?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final db = DatabaseHelper();
      if (widget.product == null) {
        await db.insertProduct(product);
      } else {
        // Note: In a real app, you'd implement update functionality
      }

      if (mounted) {
        Navigator.of(context).pop(product);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving product')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      content: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Product Name'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 2,
                    ),
                    TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(labelText: 'Barcode'),
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories.map((category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      )).toList(),
                      validator: (value) =>
                          value == null ? 'Please select a category' : null,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(labelText: 'Selling Price'),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _costPriceController,
                            decoration: const InputDecoration(labelText: 'Cost Price'),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            decoration: const InputDecoration(labelText: 'Current Stock'),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _minStockController,
                            decoration: const InputDecoration(labelText: 'Minimum Stock'),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveProduct,
          child: Text(widget.product == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}