class Category {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final String? icon;
  final bool isActive;
  final DateTime? createdAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.icon,
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      color: map['color'],
      icon: map['icon'],
      isActive: map['is_active'] == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }
}