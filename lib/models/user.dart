class User {
  final int? id;
  final String username;
  final String password;
  final String name;
  final String role; // 'admin', 'cashier', 'manager'
  final String? outletId;
  final bool isActive;
  final DateTime? createdAt;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.role,
    this.outletId,
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'name': name,
      'role': role,
      'outlet_id': outletId,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      name: map['name'],
      role: map['role'],
      outletId: map['outlet_id'],
      isActive: map['is_active'] == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }
}