import 'database_helper.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/customer.dart';

class SampleData {
  static Future<void> populateSampleData() async {
    final db = DatabaseHelper();

    // Check if data already exists
    final existingProducts = await db.getAllProducts();
    if (existingProducts.isNotEmpty) return;

    // Create sample categories
    final foodCategory = Category(
      id: 'food',
      name: 'Food & Beverage',
      description: 'Food and drink items',
      color: '#FF6B6B',
      icon: 'restaurant',
      createdAt: DateTime.now(),
    );

    final retailCategory = Category(
      id: 'retail',
      name: 'Retail',
      description: 'General retail items',
      color: '#4ECDC4',
      icon: 'shopping_bag',
      createdAt: DateTime.now(),
    );

    await db.insertCategory(foodCategory);
    await db.insertCategory(retailCategory);

    // Create sample products
    final products = [
      Product(
        name: 'Nasi Goreng Special',
        description: 'Fried rice with chicken, egg, and vegetables',
        barcode: '1001',
        categoryId: 'food',
        price: 25000,
        costPrice: 15000,
        stock: 50,
        minStock: 10,
        createdAt: DateTime.now(),
      ),
      Product(
        name: 'Ayam Bakar',
        description: 'Grilled chicken with sambal',
        barcode: '1002',
        categoryId: 'food',
        price: 30000,
        costPrice: 18000,
        stock: 30,
        minStock: 5,
        createdAt: DateTime.now(),
      ),
      Product(
        name: 'Es Teh Manis',
        description: 'Sweet iced tea',
        barcode: '1003',
        categoryId: 'food',
        price: 5000,
        costPrice: 2000,
        stock: 100,
        minStock: 20,
        createdAt: DateTime.now(),
      ),
      Product(
        name: 'Kopi Hitam',
        description: 'Black coffee',
        barcode: '1004',
        categoryId: 'food',
        price: 8000,
        costPrice: 3000,
        stock: 80,
        minStock: 15,
        createdAt: DateTime.now(),
      ),
      Product(
        name: 'Indomie Goreng',
        description: 'Fried instant noodles',
        barcode: '2001',
        categoryId: 'retail',
        price: 3500,
        costPrice: 2500,
        stock: 200,
        minStock: 50,
        createdAt: DateTime.now(),
      ),
      Product(
        name: 'Sabun Mandi Lifebuoy',
        description: 'Lifebuoy bath soap 75g',
        barcode: '2002',
        categoryId: 'retail',
        price: 3000,
        costPrice: 2000,
        stock: 150,
        minStock: 30,
        createdAt: DateTime.now(),
      ),
      Product(
        name: 'Shampoo Clear',
        description: 'Clear shampoo 170ml',
        barcode: '2003',
        categoryId: 'retail',
        price: 15000,
        costPrice: 10000,
        stock: 75,
        minStock: 15,
        createdAt: DateTime.now(),
      ),
      Product(
        name: 'Roti Tawar',
        description: 'White bread loaf',
        barcode: '2004',
        categoryId: 'retail',
        price: 12000,
        costPrice: 8000,
        stock: 40,
        minStock: 10,
        createdAt: DateTime.now(),
      ),
    ];

    for (final product in products) {
      await db.insertProduct(product);
    }

    // Create sample customers
    final customers = [
      Customer(
        name: 'John Doe',
        phone: '081234567890',
        email: 'john@example.com',
        address: 'Jl. Sudirman No. 123',
        loyaltyPoints: 150,
        totalSpent: 250000,
        lastVisit: DateTime.now().subtract(const Duration(days: 7)),
        createdAt: DateTime.now(),
      ),
      Customer(
        name: 'Jane Smith',
        phone: '081987654321',
        email: 'jane@example.com',
        address: 'Jl. Thamrin No. 456',
        loyaltyPoints: 200,
        totalSpent: 350000,
        lastVisit: DateTime.now().subtract(const Duration(days: 3)),
        createdAt: DateTime.now(),
      ),
      Customer(
        name: 'Bob Johnson',
        phone: '081555666777',
        email: 'bob@example.com',
        address: 'Jl. Gatot Subroto No. 789',
        loyaltyPoints: 75,
        totalSpent: 125000,
        lastVisit: DateTime.now().subtract(const Duration(days: 14)),
        createdAt: DateTime.now(),
      ),
    ];

    for (final customer in customers) {
      await db.insertCustomer(customer);
    }
  }
}