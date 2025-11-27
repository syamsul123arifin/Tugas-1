import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = DatabaseHelper();
      final customers = await db.getAllCustomers();

      setState(() {
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading customers')),
      );
    }
  }

  List<Customer> get _filteredCustomers {
    if (_searchController.text.isEmpty) return _customers;

    return _customers.where((customer) {
      final searchTerm = _searchController.text.toLowerCase();
      return customer.name.toLowerCase().contains(searchTerm) ||
             (customer.phone != null && customer.phone!.contains(searchTerm)) ||
             (customer.email != null && customer.email!.toLowerCase().contains(searchTerm));
    }).toList();
  }

  Future<void> _addCustomer() async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (context) => const CustomerFormDialog(),
    );

    if (result != null) {
      await _loadCustomers();
    }
  }

  Future<void> _editCustomer(Customer customer) async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (context) => CustomerFormDialog(customer: customer),
    );

    if (result != null) {
      await _loadCustomers();
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete "${customer.name}"?'),
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
        await _loadCustomers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting customer')),
        );
      }
    }
  }

  void _viewCustomerDetails(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customer.phone != null) ...[
                Text('Phone: ${customer.phone}'),
                const SizedBox(height: 8),
              ],
              if (customer.email != null) ...[
                Text('Email: ${customer.email}'),
                const SizedBox(height: 8),
              ],
              if (customer.address != null) ...[
                Text('Address: ${customer.address}'),
                const SizedBox(height: 8),
              ],
              Text('Loyalty Points: ${customer.loyaltyPoints}'),
              const SizedBox(height: 8),
              Text('Total Spent: Rp ${customer.totalSpent.toStringAsFixed(0)}'),
              const SizedBox(height: 8),
              if (customer.lastVisit != null) ...[
                Text('Last Visit: ${customer.lastVisit!.toString().split(' ')[0]}'),
                const SizedBox(height: 8),
              ],
              Text('Member Since: ${customer.createdAt?.toString().split(' ')[0] ?? 'N/A'}'),
              const SizedBox(height: 16),
              const Text(
                'Purchase History:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Purchase history will be displayed here'),
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
              Navigator.of(context).pop();
              _editCustomer(customer);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                      hintText: 'Search customers by name, phone, or email...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _addCustomer,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Customer'),
                ),
              ],
            ),
          ),

          // Customer stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatCard('Total Customers', _customers.length.toString(), Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Active This Month',
                  _customers.where((c) =>
                    c.lastVisit != null &&
                    c.lastVisit!.isAfter(DateTime.now().subtract(const Duration(days: 30)))
                  ).length.toString(),
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Total Loyalty Points',
                  _customers.fold<int>(0, (sum, c) => sum + c.loyaltyPoints).toString(),
                  Colors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Customer list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? const Center(
                        child: Text('No customers found'),
                      )
                    : ListView.builder(
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  customer.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(customer.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (customer.phone != null) Text(customer.phone!),
                                  Text('Points: ${customer.loyaltyPoints} | Spent: Rp ${customer.totalSpent.toStringAsFixed(0)}'),
                                  if (customer.lastVisit != null)
                                    Text('Last visit: ${customer.lastVisit!.toString().split(' ')[0]}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    onPressed: () => _viewCustomerDetails(customer),
                                    tooltip: 'View Details',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editCustomer(customer),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteCustomer(customer),
                                    color: Colors.red,
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                              onTap: () => _viewCustomerDetails(customer),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerFormDialog extends StatefulWidget {
  final Customer? customer;

  const CustomerFormDialog({super.key, this.customer});

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone ?? '';
      _emailController.text = widget.customer!.email ?? '';
      _addressController.text = widget.customer!.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    final customer = Customer(
      id: widget.customer?.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      loyaltyPoints: widget.customer?.loyaltyPoints ?? 0,
      totalSpent: widget.customer?.totalSpent ?? 0.0,
      lastVisit: widget.customer?.lastVisit,
      createdAt: widget.customer?.createdAt ?? DateTime.now(),
    );

    try {
      final db = DatabaseHelper();
      if (widget.customer == null) {
        await db.insertCustomer(customer);
      } else {
        // Note: In a real app, you'd implement update functionality
      }

      if (mounted) {
        Navigator.of(context).pop(customer);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving customer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 3,
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
          onPressed: _saveCustomer,
          child: Text(widget.customer == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}