class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final int loyaltyPoints;
  final double totalSpent;
  final DateTime? lastVisit;
  final DateTime? createdAt;
  final bool isActive;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.loyaltyPoints = 0,
    this.totalSpent = 0.0,
    this.lastVisit,
    this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'loyalty_points': loyaltyPoints,
      'total_spent': totalSpent,
      'last_visit': lastVisit?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      loyaltyPoints: map['loyalty_points'],
      totalSpent: map['total_spent'],
      lastVisit: map['last_visit'] != null ? DateTime.parse(map['last_visit']) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      isActive: map['is_active'] == 1,
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    int? loyaltyPoints,
    double? totalSpent,
    DateTime? lastVisit,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalSpent: totalSpent ?? this.totalSpent,
      lastVisit: lastVisit ?? this.lastVisit,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}