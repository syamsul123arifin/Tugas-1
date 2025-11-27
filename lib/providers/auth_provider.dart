import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isCashier => _currentUser?.role == 'cashier';
  bool get isManager => _currentUser?.role == 'manager';

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseHelper();
      final user = await db.getUser(username, password);

      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> createUser({
    required String username,
    required String password,
    required String name,
    required String role,
    String? outletId,
  }) async {
    if (!isAdmin) return false; // Only admin can create users

    try {
      final db = DatabaseHelper();
      final user = User(
        username: username,
        password: password,
        name: name,
        role: role,
        outletId: outletId,
        createdAt: DateTime.now(),
      );

      await db.insertUser(user);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<User>> getAllUsers() async {
    if (!isAdmin) return []; // Only admin can view all users

    try {
      final db = DatabaseHelper();
      return await db.getAllUsers();
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateUser(User user) async {
    if (!isAdmin && _currentUser?.id != user.id) return false; // Only admin or self can update

    // Note: In a real app, you'd implement update in DatabaseHelper
    // For now, we'll just return true
    notifyListeners();
    return true;
  }

  Future<bool> deleteUser(int userId) async {
    if (!isAdmin) return false; // Only admin can delete users

    // Note: In a real app, you'd implement soft delete in DatabaseHelper
    // For now, we'll just return true
    notifyListeners();
    return true;
  }

  // Check if user has permission for a specific action
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;

    switch (_currentUser!.role) {
      case 'admin':
        return true; // Admin has all permissions
      case 'manager':
        return !['create_user', 'delete_user'].contains(permission);
      case 'cashier':
        return ['create_transaction', 'view_products', 'view_customers'].contains(permission);
      default:
        return false;
    }
  }

  // Role-based access control methods
  bool canManageUsers() => hasPermission('manage_users');
  bool canManageProducts() => hasPermission('manage_products');
  bool canManageInventory() => hasPermission('manage_inventory');
  bool canViewReports() => hasPermission('view_reports');
  bool canManageCustomers() => hasPermission('manage_customers');
  bool canCreateTransactions() => hasPermission('create_transaction');
}