import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_item.dart';

class OrderModel {
  final String id;
  final List<MenuItem> items;
  final Map<String, int> itemQuantities;
  final double total;
  final DateTime timestamp;

  OrderModel({
    required this.id, required this.items, required this.itemQuantities,
    required this.total, required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemQuantities': itemQuantities,
      'total': total,
      'timestamp': timestamp,
      'itemIds': items.map((i) => i.id).toList(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId, List<MenuItem> availableMenu) {
    List<String> ids = List<String>.from(map['itemIds'] ?? []);
    List<MenuItem> reconstructedItems = ids.map((id) {
      return availableMenu.firstWhere(
        (m) => m.id == id,
        orElse: () => MenuItem(id: id, name: 'Removed', price: 0, costPrice: 0, category: '', description: '', imageUrl: ''),
      );
    }).toList();

    return OrderModel(
      id: docId,
      items: reconstructedItems,
      itemQuantities: Map<String, int>.from(map['itemQuantities'] ?? {}),
      total: (map['total'] ?? 0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}