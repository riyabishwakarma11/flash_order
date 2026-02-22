import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../models/menu_item.dart';
import '../models/order_model.dart';

class AppState extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _currentBizId;
  String? get currentBizId => _currentBizId;

  List<MenuItem> _menu = [];
  List<OrderModel> _orders = [];
  List<String> _categories = ["General"];
  final Map<String, int> _cartQuantities = {};

  OrderModel? _lastPlacedOrder;
  OrderModel? get lastPlacedOrder => _lastPlacedOrder;

  List<MenuItem> get menu => _menu;
  List<OrderModel> get orders => _orders;
  List<String> get categories => _categories;
  Map<String, int> get cart => _cartQuantities;

  int startHour = 8;
  int endHour = 22;

  void initializeBusiness(String bizId) {
    _currentBizId = bizId;
    _listenToMenu();
    _listenToOrders();
    _listenToCategories();
    notifyListeners();
  }

  void _listenToMenu() {
    if (_currentBizId == null) return;
    _db
        .collection('businesses')
        .doc(_currentBizId)
        .collection('menu')
        .snapshots()
        .listen((snap) {
      _menu =
          snap.docs.map((doc) => MenuItem.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    });
  }

  void _listenToOrders() {
    if (_currentBizId == null) return;
    _db
        .collection('businesses')
        .doc(_currentBizId)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
      _orders = snap.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id, _menu))
          .toList();
      notifyListeners();
    });
  }

  void _listenToCategories() {
    if (_currentBizId == null) return;
    _db
        .collection('businesses')
        .doc(_currentBizId)
        .collection('categories')
        .snapshots()
        .listen((snap) {
      _categories = snap.docs.isNotEmpty
          ? snap.docs.map((doc) => doc['name'] as String).toList()
          : ["General"];
      notifyListeners();
    });
  }

  // --- ACTIONS ---

  Future<void> addMenuItem(MenuItem item) async {
    if (_currentBizId == null) return;
    await _db
        .collection('businesses')
        .doc(_currentBizId)
        .collection('menu')
        .doc(item.id)
        .set(item.toMap());
  }

  Future<void> removeMenuItem(String id) async {
    if (_currentBizId == null) return;
    await _db
        .collection('businesses')
        .doc(_currentBizId)
        .collection('menu')
        .doc(id)
        .delete();
  }

  Future<void> addCategory(String name) async {
    if (_currentBizId == null) return;
    await _db
        .collection('businesses')
        .doc(_currentBizId)
        .collection('categories')
        .doc(name)
        .set({'name': name});
  }

  Future<void> placeOrder() async {
    if (_cartQuantities.isEmpty || _currentBizId == null) return;
    final order = OrderModel(
        id: const Uuid().v4(),
        items: cartItems,
        itemQuantities: Map.from(_cartQuantities),
        total: cartTotal,
        timestamp: DateTime.now());
    await _db
        .collection('businesses')
        .doc(_currentBizId)
        .collection('orders')
        .add(order.toMap());
    _lastPlacedOrder = order;
    _cartQuantities.clear();
    notifyListeners();
  }

  // --- CSV DOWNLOAD ---
  void downloadBusinessReport() {
    List<Map<String, dynamic>> dailyData = dailyFinanceReport;
    if (dailyData.isEmpty) return;
    double totalDays = dailyData.length.toDouble();
    double avgOrders = _orders.length / totalDays;
    double avgProfit = totalProfit / totalDays;
    List<List<dynamic>> rows = [
      [
        "Date",
        "Orders",
        "Revenue",
        "Profit",
        "Top Product",
        "Least Selling",
        "Top Category",
        "Peak Hour",
        "Traffic",
        "Profitability"
      ]
    ];
    for (var day in dailyData) {
      DateTime date = day['rawDate'];
      var dayOrders = _orders
          .where((o) =>
              o.timestamp.day == date.day && o.timestamp.month == date.month)
          .toList();
      Map<String, int> iCounts = {};
      Map<String, int> cCounts = {};
      Map<int, int> hCounts = {};
      for (var o in dayOrders) {
        hCounts[o.timestamp.hour] = (hCounts[o.timestamp.hour] ?? 0) + 1;
        o.itemQuantities.forEach((id, q) {
          final item = _menu.firstWhere((m) => m.id == id,
              orElse: () => MenuItem(
                  id: '0',
                  name: '?',
                  price: 0,
                  costPrice: 0,
                  category: '?',
                  description: '',
                  imageUrl: ''));
          iCounts[item.name] = (iCounts[item.name] ?? 0) + q;
          cCounts[item.category] = (cCounts[item.category] ?? 0) + q;
        });
      }
      var sI = iCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      var sC = cCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      var sH = hCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      String traffic = dayOrders.length > avgOrders + 10
          ? "High"
          : (dayOrders.length < avgOrders - 10 ? "Low" : "Medium");
      String profStatus = day['profit'] > avgProfit * 1.2
          ? "High"
          : (day['profit'] < avgProfit * 0.8 ? "Low" : "Medium");
      rows.add([
        day['date'],
        dayOrders.length,
        day['revenue'].toInt(),
        day['profit'].toInt(),
        sI.isNotEmpty ? sI.first.key : "N/A",
        sI.isNotEmpty ? sI.last.key : "N/A",
        sC.isNotEmpty ? sC.first.key : "N/A",
        sH.isNotEmpty ? "${sH.first.key}h" : "N/A",
        traffic,
        profStatus
      ]);
    }
    String csv = const ListToCsvConverter().convert(rows);
    final anchor = html.AnchorElement(
        href: html.Url.createObjectUrlFromBlob(html.Blob([utf8.encode(csv)])))
      ..setAttribute("download", "Report_${_currentBizId}.csv")
      ..click();
  }

  // --- ANALYTICS ---
  List<OrderModel> get ordersToday {
    DateTime now = DateTime.now();
    return _orders
        .where((o) =>
            o.timestamp.day == now.day &&
            o.timestamp.month == now.month &&
            o.timestamp.year == now.year)
        .toList();
  }

  double get todayRevenue => ordersToday.fold(0.0, (s, o) => s + o.total);
  int get todayOrdersCount => ordersToday.length;
  double get totalRevenue => _orders.fold(0.0, (s, o) => s + o.total);

  double get totalProfit => _orders.fold(0.0, (s, o) {
        double p = 0;
        o.itemQuantities.forEach((id, q) {
          try {
            final item = _menu.firstWhere((m) => m.id == id);
            p += (item.price - item.costPrice) * q;
          } catch (e) {}
        });
        return s + p;
      });

  double get todayProfit {
    double profit = 0;
    for (var o in ordersToday) {
      o.itemQuantities.forEach((id, q) {
        try {
          final item = _menu.firstWhere((m) => m.id == id);
          profit += (item.price - item.costPrice) * q;
        } catch (e) {}
      });
    }
    return profit;
  }

  List<Map<String, dynamic>> get dailyFinanceReport {
    Map<String, Map<String, dynamic>> dailyMap = {};
    for (var o in _orders) {
      String d = DateFormat('dd MMM yyyy').format(o.timestamp);
      double dp = 0;
      o.itemQuantities.forEach((id, q) {
        try {
          final item = _menu.firstWhere((m) => m.id == id);
          dp += (item.price - item.costPrice) * q;
        } catch (e) {}
      });
      if (!dailyMap.containsKey(d)) {
        dailyMap[d] = {
          'date': d,
          'revenue': 0.0,
          'profit': 0.0,
          'rawDate': o.timestamp
        };
      }
      dailyMap[d]!['revenue'] += o.total;
      dailyMap[d]!['profit'] += dp;
    }
    return dailyMap.values.toList()
      ..sort((a, b) =>
          (b['rawDate'] as DateTime).compareTo(a['rawDate'] as DateTime));
  }

  Map<int, int> get hourlyOrderCounts {
    Map<int, int> counts = {};
    for (int i = startHour; i <= endHour; i++) counts[i] = 0;
    for (var o in ordersToday) {
      if (o.timestamp.hour >= startHour && o.timestamp.hour <= endHour)
        counts[o.timestamp.hour] = (counts[o.timestamp.hour] ?? 0) + 1;
    }
    return counts;
  }

  Map<int, Map<int, int>> get weeklyPeakHeatmap {
    Map<int, Map<int, int>> heatmap = {};
    for (int i = 1; i <= 7; i++) {
      heatmap[i] = {};
      for (int h = startHour; h <= endHour; h++) heatmap[i]![h] = 0;
    }
    for (var o in _orders) {
      if (o.timestamp
          .isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
        int d = o.timestamp.weekday;
        int hr = o.timestamp.hour;
        if (hr >= startHour && hr <= endHour)
          heatmap[d]![hr] = (heatmap[d]![hr] ?? 0) + 1;
      }
    }
    return heatmap;
  }

  List<Map<String, dynamic>> get weeklyTrendData {
    List<Map<String, dynamic>> trend = [];
    for (int i = 6; i >= 0; i--) {
      DateTime d = DateTime.now().subtract(Duration(days: i));
      trend.add({
        'day': DateFormat('E').format(d),
        'amount': _orders
            .where(
                (o) => o.timestamp.day == d.day && o.timestamp.month == d.month)
            .fold(0.0, (s, o) => s + o.total)
      });
    }
    return trend;
  }

  List<Map<String, dynamic>> get rankedItems {
    Map<String, int> counts = {};
    Map<String, double> revs = {};
    for (var o in _orders) {
      o.itemQuantities.forEach((id, q) {
        try {
          final item = _menu.firstWhere((m) => m.id == id);
          counts[item.name] = (counts[item.name] ?? 0) + q;
          revs[item.name] = (revs[item.name] ?? 0.0) + (item.price * q);
        } catch (e) {}
      });
    }
    return counts.entries
        .map((e) => {'name': e.key, 'qty': e.value, 'rev': revs[e.key] ?? 0.0})
        .toList()
      ..sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));
  }

  List<Map<String, dynamic>> get todayRankedItems {
    Map<String, int> counts = {};
    Map<String, double> revs = {};
    for (var o in ordersToday) {
      o.itemQuantities.forEach((id, q) {
        try {
          final item = _menu.firstWhere((m) => m.id == id);
          counts[item.name] = (counts[item.name] ?? 0) + q;
          revs[item.name] = (revs[item.name] ?? 0.0) + (item.price * q);
        } catch (e) {}
      });
    }
    return counts.entries
        .map((e) => {'name': e.key, 'qty': e.value, 'rev': revs[e.key] ?? 0.0})
        .toList()
      ..sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));
  }

  Map<String, Map<int, int>> get categoryHeatmap {
    Map<String, Map<int, int>> heatmap = {};
    for (var o in ordersToday) {
      int h = o.timestamp.hour;
      o.itemQuantities.forEach((id, q) {
        try {
          final item = _menu.firstWhere((m) => m.id == id);
          if (item.category.isNotEmpty) {
            heatmap.putIfAbsent(item.category, () => {});
            heatmap[item.category]![h] = (heatmap[item.category]![h] ?? 0) + q;
          }
        } catch (e) {}
      });
    }
    return heatmap;
  }

  // --- HELPERS ---
  List<MenuItem> get cartItems => _cartQuantities.keys
      .map((id) => _menu.firstWhere((m) => m.id == id))
      .toList();
  int getQuantity(String id) => _cartQuantities[id] ?? 0;
  void incrementItem(String id) {
    _cartQuantities[id] = (getQuantity(id)) + 1;
    notifyListeners();
  }

  void decrementItem(String id) {
    if (_cartQuantities.containsKey(id)) {
      _cartQuantities[id] = _cartQuantities[id]! - 1;
      if (_cartQuantities[id] == 0) _cartQuantities.remove(id);
      notifyListeners();
    }
  }

  double get cartTotal {
    double total = 0;
    _cartQuantities.forEach((id, qty) {
      try {
        total += _menu.firstWhere((m) => m.id == id).price * qty;
      } catch (e) {}
    });
    return total;
  }

  Future<void> migrateOldDataToNewBusiness(String targetBizId) async {
    List<String> collections = ['menu', 'orders', 'employees', 'categories'];
    for (String col in collections) {
      var rootData = await _db.collection(col).get();
      for (var doc in rootData.docs) {
        await _db
            .collection('businesses')
            .doc(targetBizId)
            .collection(col)
            .doc(doc.id)
            .set(doc.data());
      }
    }
  }
}
