class Product {
  final int? id;
  final String name;
  final String? description;
  final String? barcode;
  final String categoryId;
  final double price;
  final double costPrice;
  final int stock;
  final int minStock;
  final String? imagePath;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.name,
    this.description,
    this.barcode,
    required this.categoryId,
    required this.price,
    required this.costPrice,
    required this.stock,
    this.minStock = 0,
    this.imagePath,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'barcode': barcode,
      'category_id': categoryId,
      'price': price,
      'cost_price': costPrice,
      'stock': stock,
      'min_stock': minStock,
      'image_path': imagePath,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      barcode: map['barcode'],
      categoryId: map['category_id'],
      price: map['price'],
      costPrice: map['cost_price'],
      stock: map['stock'],
      minStock: map['min_stock'],
      imagePath: map['image_path'],
      isActive: map['is_active'] == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    String? barcode,
    String? categoryId,
    double? price,
    double? costPrice,
    int? stock,
    int? minStock,
    String? imagePath,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      imagePath: imagePath ?? this.imagePath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}