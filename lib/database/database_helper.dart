import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/transaction.dart' as models;
import '../models/transaction_item.dart';
import '../models/customer.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static sqflite.Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<sqflite.Database> _initDatabase() async {
    String path = join(await sqflite.getDatabasesPath(), 'kasir.db');
    
    // PERUBAHAN 1: Membuka database
    var db = await sqflite.openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );

    // PERUBAHAN 2: Memastikan Admin SELALU ada (Fix Login Problem)
    await _ensureAdminExists(db);
    
    return db;
  }

  // PERUBAHAN 3: Fungsi Pengecekan & Pembuatan Admin Otomatis
  Future<void> _ensureAdminExists(sqflite.Database db) async {
    // Cek apakah tabel users sudah ada (untuk menghindari error saat pertama kali install)
    var tableCheck = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='users'");
    
    if (tableCheck.isNotEmpty) {
      // Cek apakah user admin sudah ada
      final List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: ['admin'],
      );

      // Jika admin tidak ditemukan, buat baru!
      if (result.isEmpty) {
        print("--- FIX: User Admin tidak ditemukan, membuat user baru... ---");
        await db.insert('users', {
          'username': 'admin',
          'password': 'admin123', 
          'name': 'Administrator',
          'role': 'admin',
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        });
        print("--- FIX: User Admin berhasil dibuat (Pass: admin123) ---");
      }
    }
  }

  Future<void> _onCreate(sqflite.Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        outlet_id TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT
      )
    ''');

    // Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        color TEXT,
        icon TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT
      )
    ''');

    // Create products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        barcode TEXT UNIQUE,
        category_id TEXT NOT NULL,
        price REAL NOT NULL,
        cost_price REAL NOT NULL,
        stock INTEGER DEFAULT 0,
        min_stock INTEGER DEFAULT 0,
        image_path TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Create customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        loyalty_points INTEGER DEFAULT 0,
        total_spent REAL DEFAULT 0.0,
        last_visit TEXT,
        created_at TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT UNIQUE NOT NULL,
        customer_id INTEGER,
        cashier_id TEXT NOT NULL,
        outlet_id TEXT,
        subtotal REAL NOT NULL,
        tax REAL DEFAULT 0.0,
        discount REAL DEFAULT 0.0,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        payment_amount REAL,
        change REAL,
        status TEXT DEFAULT 'pending',
        notes TEXT,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // Create transaction_items table
    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        discount REAL DEFAULT 0.0,
        total REAL NOT NULL,
        notes TEXT,
        FOREIGN KEY (transaction_id) REFERENCES transactions (transaction_id) ON DELETE CASCADE
      )
    ''');

    // Insert default categories (Admin insert dipindah ke _ensureAdminExists agar lebih aman)
    await db.insert('categories', {
      'id': 'food',
      'name': 'Food & Beverage',
      'description': 'Food and drink items',
      'color': '#FF6B6B',
      'icon': 'restaurant',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('categories', {
      'id': 'retail',
      'name': 'Retail',
      'description': 'General retail items',
      'color': '#4ECDC4',
      'icon': 'shopping_bag',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // --- User Operations ---
  
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUser(String username, String password) async {
    final db = await database;
    // Debugging print untuk melihat apa yang terjadi saat login
    print("Mencoba login dengan User: $username, Pass: $password");
    
    final maps = await db.query(
      'users',
      where: 'username = ? AND password = ? AND is_active = 1',
      whereArgs: [username, password],
    );

    if (maps.isNotEmpty) {
      print("Login Berhasil! User ditemukan.");
      return User.fromMap(maps.first);
    } else {
      print("Login Gagal! User tidak ditemukan di database.");
      return null;
    }
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  // ... (Sisa kode ke bawah sama persis dengan kode Anda) ...
  // Category operations, Product operations, dll biarkan tetap sama
  
  // Category operations
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories', where: 'is_active = 1');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  // Product operations
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', where: 'is_active = 1');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'barcode = ? AND is_active = 1',
      whereArgs: [barcode],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProductStock(int productId, int newStock) async {
    final db = await database;
    return await db.update(
      'products',
      {'stock': newStock, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Customer operations
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final maps = await db.query('customers', where: 'is_active = 1');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomerByPhone(String phone) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'phone = ? AND is_active = 1',
      whereArgs: [phone],
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  // Transaction operations
  Future<int> insertTransaction(models.Transaction transaction) async {
    final db = await database;
    final batch = db.batch();

    // Insert transaction
    batch.insert('transactions', transaction.toMap());

    // Insert transaction items
    for (var item in transaction.items) {
      batch.insert('transaction_items', item.toMap());
    }

    await batch.commit();
    return 1; // Return success
  }

  Future<List<models.Transaction>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'created_at DESC');

    List<models.Transaction> transactions = [];
    for (var map in maps) {
      final items = await getTransactionItems(map['transaction_id'] as String);
      transactions.add(models.Transaction.fromMap(map, items));
    }

    return transactions;
  }

  Future<List<TransactionItem>> getTransactionItems(String transactionId) async {
    final db = await database;
    final maps = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return maps.map((map) => TransactionItem.fromMap(map)).toList();
  }

  Future<int> updateTransactionStatus(String transactionId, String status) async {
    final db = await database;
    return await db.update(
      'transactions',
      {
        'status': status,
        'completed_at': status == 'completed' ? DateTime.now().toIso8601String() : null,
      },
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  // Analytics queries
  Future<Map<String, dynamic>> getSalesAnalytics(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total_transactions,
        SUM(total) as total_sales,
        AVG(total) as average_transaction,
        SUM((SELECT SUM((ti.unit_price - p.cost_price) * ti.quantity)
             FROM transaction_items ti
             JOIN products p ON ti.product_id = p.id
             WHERE ti.transaction_id = t.transaction_id)) as total_profit
      FROM transactions t
      WHERE t.status = 'completed'
      AND t.created_at BETWEEN ? AND ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    if (result.isNotEmpty) {
      return result.first;
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> getBestSellingProducts(DateTime startDate, DateTime endDate) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        p.name,
        SUM(ti.quantity) as total_quantity,
        SUM(ti.total) as total_sales
      FROM transaction_items ti
      JOIN transactions t ON ti.transaction_id = t.transaction_id
      JOIN products p ON ti.product_id = p.id
      WHERE t.status = 'completed'
      AND t.created_at BETWEEN ? AND ?
      GROUP BY p.id, p.name
      ORDER BY total_quantity DESC
      LIMIT 10
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}