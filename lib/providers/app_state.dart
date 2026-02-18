import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/menu_item.dart';
import '../models/order_model.dart';

class AppState extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<MenuItem> _menu = [];
  List<OrderModel> _orders = [];
  List<String> _categories = ["General"];
  final Map<String, int> _cartQuantities = {};

  List<MenuItem> get menu => _menu;
  List<OrderModel> get orders => _orders;
  List<String> get categories => _categories;
  Map<String, int> get cart => _cartQuantities;

  int startHour = 8; 
  int endHour = 22;

  AppState() {
    _listenToMenu();
    _listenToOrders();
    _listenToCategories();
  }

  // --- CLOUD LISTENERS ---

  void _listenToMenu() {
    _db.collection('menu').snapshots().listen((snap) {
      _menu = snap.docs.map((doc) => MenuItem.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    });
  }

  void _listenToOrders() {
    _db.collection('orders').orderBy('timestamp', descending: true).snapshots().listen((snap) {
      _orders = snap.docs.map((doc) => OrderModel.fromMap(doc.data(), doc.id, _menu)).toList();
      notifyListeners();
    });
  }

  void _listenToCategories() {
    _db.collection('categories').snapshots().listen((snap) {
      if (snap.docs.isNotEmpty) {
        _categories = snap.docs.map((doc) => doc['name'] as String).toList();
      } else {
        _categories = ["General"];
      }
      notifyListeners();
    });
  }

  // --- ACTIONS ---

  Future<void> addMenuItem(MenuItem item) async {
    await _db.collection('menu').doc(item.id).set(item.toMap());
  }

  Future<void> removeMenuItem(String id) async {
    await _db.collection('menu').doc(id).delete();
  }

  Future<void> addCategory(String name) async {
    await _db.collection('categories').doc(name).set({'name': name});
  }

  Future<void> placeOrder() async {
    if (_cartQuantities.isEmpty) return;
    final order = OrderModel(
      id: '', 
      items: cartItems, 
      itemQuantities: Map.from(_cartQuantities), 
      total: cartTotal, 
      timestamp: DateTime.now()
    );
    await _db.collection('orders').add(order.toMap());
    _cartQuantities.clear();
    notifyListeners();
  }

  // --- BI ANALYTICS GETTERS ---

  double get totalRevenue => _orders.fold(0.0, (s, o) => s + o.total);

  double get totalProfit => _orders.fold(0.0, (s, o) {
    double p = 0;
    o.itemQuantities.forEach((id, q) {
      final item = _menu.firstWhere((m) => m.id == id, orElse: () => MenuItem(id: '0', name: '', price: 0, costPrice: 0, category: '', description: '', imageUrl: ''));
      p += (item.price - item.costPrice) * q;
    });
    return s + p;
  });

  List<Map<String, dynamic>> get dailyFinanceReport {
    Map<String, Map<String, dynamic>> dailyMap = {};
    for (var o in _orders) {
      String dateKey = DateFormat('dd MMM yyyy').format(o.timestamp);
      if (!dailyMap.containsKey(dateKey)) {
        dailyMap[dateKey] = {'date': dateKey, 'revenue': 0.0, 'profit': 0.0, 'rawDate': o.timestamp};
      }
      dailyMap[dateKey]!['revenue'] += o.total;
    }
    var reportList = dailyMap.values.toList();
    reportList.sort((a, b) => (b['rawDate'] as DateTime).compareTo(a['rawDate'] as DateTime));
    return reportList;
  }

  Map<int, int> get hourlyOrderCounts {
    Map<int, int> counts = {};
    for (int i = startHour; i <= endHour; i++) counts[i] = 0;
    for (var o in _orders) {
      if (o.timestamp.day == DateTime.now().day) {
        int h = o.timestamp.hour;
        if (h >= startHour && h <= endHour) counts[h] = (counts[h] ?? 0) + 1;
      }
    }
    return counts;
  }

  Map<int, Map<int, int>> get weeklyPeakHeatmap {
    Map<int, Map<int, int>> heatmap = {};
    for (int i = 1; i <= 7; i++) {
      heatmap[i] = {};
      for (int h = startHour; h <= endHour; h++) heatmap[i]![h] = 0;
    }
    DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    for (var o in _orders) {
      if (o.timestamp.isAfter(sevenDaysAgo)) {
        int day = o.timestamp.weekday;
        int hr = o.timestamp.hour;
        if (hr >= startHour && hr <= endHour) heatmap[day]![hr] = (heatmap[day]![hr] ?? 0) + 1;
      }
    }
    return heatmap;
  }

  List<Map<String, dynamic>> get weeklyTrendData {
    List<Map<String, dynamic>> trend = [];
    for (int i = 6; i >= 0; i--) {
      DateTime d = DateTime.now().subtract(Duration(days: i));
      double val = _orders.where((o) => o.timestamp.day == d.day && o.timestamp.month == d.month).fold(0.0, (s, o) => s + o.total);
      trend.add({'day': DateFormat('E').format(d), 'amount': val});
    }
    return trend;
  }

  List<Map<String, dynamic>> get rankedItems {
    Map<String, int> counts = {};
    for (var o in _orders) {
      o.itemQuantities.forEach((id, q) {
        final name = _menu.firstWhere((m) => m.id == id, orElse: () => MenuItem(id: '0', name: 'Deleted', price: 0, costPrice: 0, category: '', description: '', imageUrl: '')).name;
        counts[name] = (counts[name] ?? 0) + q;
      });
    }
    var list = counts.entries.map((e) => {'name': e.key, 'qty': e.value}).toList();
    list.sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));
    return list;
  }

  List<Map<String, dynamic>> get todayRankedItems {
    Map<String, Map<String, dynamic>> ranking = {};
    DateTime now = DateTime.now();
    for (var o in _orders) {
      if (o.timestamp.day == now.day && o.timestamp.month == now.month) {
        o.itemQuantities.forEach((id, q) {
          final item = _menu.firstWhere((m) => m.id == id, orElse: () => MenuItem(id: '0', name: 'Deleted', price: 0, costPrice: 0, category: '', description: '', imageUrl: ''));
          ranking.putIfAbsent(item.name, () => {'name': item.name, 'qty': 0, 'rev': 0.0});
          ranking[item.name]!['qty'] += q;
          ranking[item.name]!['rev'] += (item.price * q);
        });
      }
    }
    var list = ranking.values.toList();
    list.sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));
    return list;
  }

  Map<String, Map<int, int>> get categoryHeatmap {
    Map<String, Map<int, int>> heatmap = {};
    for (var o in _orders) {
      if (o.timestamp.day == DateTime.now().day) {
        int h = o.timestamp.hour;
        o.itemQuantities.forEach((id, q) {
          final item = _menu.firstWhere((m) => m.id == id, orElse: () => MenuItem(id: '0', name: '', price: 0, costPrice: 0, category: '', description: '', imageUrl: ''));
          if (item.category.isNotEmpty) {
            heatmap.putIfAbsent(item.category, () => {});
            heatmap[item.category]![h] = (heatmap[item.category]![h] ?? 0) + q;
          }
        });
      }
    }
    return heatmap;
  }

  // --- HELPERS ---

  List<MenuItem> get cartItems => _cartQuantities.keys.map((id) => _menu.firstWhere((m) => m.id == id, orElse: () => MenuItem(id: '0', name: '?', price: 0, costPrice: 0, category: '', description: '', imageUrl: ''))).where((i) => i.id != '0').toList();
  int getQuantity(String id) => _cartQuantities[id] ?? 0;
  void incrementItem(String id) { _cartQuantities[id] = (getQuantity(id)) + 1; notifyListeners(); }
  void decrementItem(String id) { if (_cartQuantities.containsKey(id)) { _cartQuantities[id] = _cartQuantities[id]! - 1; if (_cartQuantities[id] == 0) _cartQuantities.remove(id); notifyListeners(); } }
  
  double get cartTotal {
    double total = 0;
    _cartQuantities.forEach((id, qty) {
      try {
        final item = _menu.firstWhere((m) => m.id == id);
        total += item.price * qty;
      } catch (e) {}
    });
    return total;
  }
}