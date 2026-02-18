class MenuItem {
  final String id;
  final String name;
  final double price;
  final double costPrice; 
  final String category;
  final String description;
  final String imageUrl;

  MenuItem({
    required this.id, required this.name, required this.price,
    required this.costPrice, required this.category,
    required this.description, required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'name': name, 'price': price, 'costPrice': costPrice,
      'category': category, 'description': description, 'imageUrl': imageUrl,
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map, String docId) {
    return MenuItem(
      id: docId,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      costPrice: (map['costPrice'] ?? (map['price'] ?? 0) * 0.6).toDouble(),
      category: map['category'] ?? 'General',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? 'https://cdn-icons-png.flaticon.com/512/706/706164.png',
    );
  }
}