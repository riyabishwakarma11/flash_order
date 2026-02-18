import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart'; 
import '../providers/app_state.dart';
import '../models/menu_item.dart';
import '../models/order_model.dart';
import 'package:intl/intl.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("FLASH BUSINESS BI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          bottom: const TabBar(
            labelColor: Colors.orange, 
            indicatorColor: Colors.orange,
            tabs: [Tab(text: "ANALYTICS"), Tab(text: "MENU MANAGEMENT")]
          ),
        ),
        body: TabBarView(children: [const AdminAnalytics(), const AdminMenuEditor()]),
      ),
    );
  }
}

// --- CLASS 1: ANALYTICS TAB ---
class AdminAnalytics extends StatefulWidget {
  const AdminAnalytics({super.key});
  @override
  State<AdminAnalytics> createState() => _AdminAnalyticsState();
}

class _AdminAnalyticsState extends State<AdminAnalytics> {
  String _rankingFilter = "Best-selling"; 

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    if (state.orders.isEmpty) return const Center(child: Text("No Sales Data Yet"));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. KPI TILES
        Row(children: [
          _tile("Revenue", "\$${state.totalRevenue.toInt()}", Colors.green, Icons.money),
          _tile("Profit", "\$${state.totalProfit.toInt()}", Colors.blue, Icons.trending_up),
          _tile("Orders", "${state.orders.length}", Colors.orange, Icons.shopping_cart),
        ]),
        const SizedBox(height: 25),

        _header("Daily Activity (Orders per Hour)"),
        SizedBox(height: 180, child: _buildBarChart(state)),
        const SizedBox(height: 30),

        _header("7-Day Revenue Trend"),
        SizedBox(height: 180, child: _buildLineChart(state)),
        const SizedBox(height: 30),

        _header("Weekly Peak Hours (Staffing Insights)"),
        _buildWeeklyPeakHeatmap(state),
        const SizedBox(height: 30),

        // 2. ORDER HISTORY SECTION
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _header("Recent Order History"),
          TextButton(onPressed: () => _showAllOrders(context, state), child: const Text("View All Today", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)))
        ]),
        _buildOrderHistoryTable(context, state, limit: 10),
        const SizedBox(height: 30),

        // 3. RANKING SECTION WITH FILTERS (FIXED IDENTIFIER ERROR HERE)
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _header("Product Performance ($_rankingFilter)"), // Fixed the $ error here
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.orange),
            onSelected: (val) => val == "View All" ? _showAllRankings(context, state) : setState(() => _rankingFilter = val),
            itemBuilder: (c) => [
              const PopupMenuItem(value: "Best-selling", child: Text("Top 5 Best Sellers")),
              const PopupMenuItem(value: "Least-selling", child: Text("Top 5 Least Sellers")),
              const PopupMenuDivider(),
              const PopupMenuItem(value: "View All", child: Text("View All Today")),
            ],
          )
        ]),
        _buildFilteredRanking(state),
        const SizedBox(height: 30),

        _header("Category Activity (Today)"),
        _buildHeatmap(state),
        const SizedBox(height: 30),

        _header("Financial Overview"),
        _buildFinanceTable(state),
        const SizedBox(height: 50),
      ],
    );
  }

  // --- ANALYTICS UI BUILDERS ---

  Widget _buildOrderHistoryTable(BuildContext context, AppState state, {int? limit}) {
    var orders = limit != null ? state.orders.take(limit).toList() : state.orders;
    return Card(
      elevation: 0, shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(10)),
      child: Column(children: orders.map((o) => ListTile(
        onTap: () => _showOrderDetail(context, o),
        title: Text("Order #${o.id.substring(o.id.length - 6)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('hh:mm a').format(o.timestamp), style: const TextStyle(fontSize: 11)),
        trailing: Text("\$${o.total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      )).toList()),
    );
  }

  void _showOrderDetail(BuildContext context, OrderModel order) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text("Detail #${order.id.substring(order.id.length - 6)}"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ...order.itemQuantities.entries.map((e) {
          final item = order.items.firstWhere((i) => i.id == e.key, orElse: () => MenuItem(id: '', name: 'Deleted', price: 0, costPrice: 0, category: '', description: '', imageUrl: ''));
          return ListTile(dense: true, title: Text(item.name), trailing: Text("${e.value} x \$${item.price}"));
        }).toList(),
        const Divider(),
        ListTile(title: const Text("Total"), trailing: Text("\$${order.total}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Close"))],
    ));
  }

  Widget _buildFilteredRanking(AppState state) {
    var items = List<Map<String, dynamic>>.from(state.rankedItems);
    if (_rankingFilter == "Least-selling") {
      items.sort((a, b) => (a['qty'] as int).compareTo(b['qty'] as int));
    } else {
      items.sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));
    }
    var display = items.take(5).toList();
    return Card(
      elevation: 0, shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(10)),
      child: Column(children: display.asMap().entries.map((e) => ListTile(dense: true, leading: CircleAvatar(radius: 10, backgroundColor: _rankingFilter == "Best-selling" && e.key < 3 ? Colors.amber : Colors.grey[200], child: Text("${e.key + 1}", style: const TextStyle(fontSize: 8))), title: Text(e.value['name'], style: const TextStyle(fontSize: 12)), trailing: Text("${e.value['qty']} sold", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))).toList()),
    );
  }

  void _showAllOrders(BuildContext context, AppState state) {
    Navigator.push(context, MaterialPageRoute(builder: (c) => Scaffold(appBar: AppBar(title: const Text("Full History")), body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: _buildOrderHistoryTable(context, state))))));
  }

  void _showAllRankings(BuildContext context, AppState state) {
    Navigator.push(context, MaterialPageRoute(builder: (c) => Scaffold(appBar: AppBar(title: const Text("Full Today Ranking")), body: ListView(padding: const EdgeInsets.all(16), children: [DataTable(columns: const [DataColumn(label: Text("Rank")), DataColumn(label: Text("Item")), DataColumn(label: Text("Qty"))], rows: state.todayRankedItems.asMap().entries.map((e) => DataRow(cells: [DataCell(Text("${e.key+1}")), DataCell(Text(e.value['name'])), DataCell(Text("${e.value['qty']}"))])).toList())]))));
  }

  // --- HELPER METHODS ---
  Widget _header(String t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)));
  Widget _tile(String t, String v, Color c, IconData i) => Expanded(child: Card(elevation: 0, color: c.withOpacity(0.1), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Icon(i, color: c, size: 16), Text(t, style: TextStyle(color: c, fontSize: 10)), Text(v, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c))]))));
  Widget _buildBarChart(AppState state) { var data = state.hourlyOrderCounts; double avg = data.values.isEmpty ? 0 : data.values.reduce((a, b) => a + b) / data.length; return BarChart(BarChartData(gridData: const FlGridData(show: false), borderData: FlBorderData(show: false), titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (v, m) => Text("${v.toInt()}h", style: const TextStyle(fontSize: 8)))), leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))), barGroups: data.entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.toDouble(), color: e.value > avg ? Colors.redAccent : Colors.orange, width: 10, borderRadius: BorderRadius.circular(2))])).toList())); }
  Widget _buildLineChart(AppState state) { var trend = state.weeklyTrendData; double max = trend.map((e) => e['amount'] as double).fold(0, (p, e) => e > p ? e : p); return LineChart(LineChartData(lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(getTooltipColor: (s) => Colors.blueGrey.withOpacity(0.8), getTooltipItems: (ts) => ts.map((s) => LineTooltipItem('${trend[s.x.toInt()]['day']}: \$${s.y.toInt()}', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))).toList())), gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey[200], strokeWidth: 1)), titlesData: FlTitlesData(rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, reservedSize: 30, getTitlesWidget: (v, m) { int i = v.toInt(); return (i >= 0 && i < trend.length) ? Text(trend[i]['day'], style: const TextStyle(fontSize: 9, color: Colors.grey)) : const Text(''); })), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => Text('\$${v.toInt()}', style: const TextStyle(fontSize: 8, color: Colors.grey))))), borderData: FlBorderData(show: false), lineBarsData: [LineChartBarData(spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['amount'])).toList(), isCurved: true, preventCurveOverShooting: true, color: Colors.blue, barWidth: 3, dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 3, color: Colors.white, strokeWidth: 2, strokeColor: Colors.blue)), belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)))], maxY: (max == 0 ? 1000 : max * 1.3))); }
  Widget _buildWeeklyPeakHeatmap(AppState state) { var data = state.weeklyPeakHeatmap; int totalHours = (state.endHour - state.startHour) + 1; List<String> days = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]; return Card(elevation: 0, shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(10)), child: Padding(padding: const EdgeInsets.all(12.0), child: Column(children: [Row(children: [const SizedBox(width: 40), ...List.generate(totalHours, (i) => Expanded(child: Text("${state.startHour + i}h", textAlign: TextAlign.center, style: const TextStyle(fontSize: 7, color: Colors.grey, fontWeight: FontWeight.bold))))]), const Divider(height: 10), ...List.generate(7, (idx) { int dayNum = idx + 1; return Padding(padding: const EdgeInsets.symmetric(vertical: 1), child: Row(children: [SizedBox(width: 40, child: Text(days[dayNum], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey))), ...List.generate(totalHours, (i) { int val = data[dayNum]?[state.startHour + i] ?? 0; return Expanded(child: Container(height: 18, margin: const EdgeInsets.all(0.5), decoration: BoxDecoration(color: Colors.deepPurple.withOpacity((val / 5).clamp(0.0, 1.0)), borderRadius: BorderRadius.circular(2)), child: Center(child: Text(val > 0 ? "$val" : "", style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold))))); })])); })]))); }
  Widget _buildHeatmap(AppState state) { var data = state.categoryHeatmap; int totalHours = (state.endHour - state.startHour) + 1; return Card(child: Padding(padding: const EdgeInsets.all(12.0), child: Column(children: [Row(children: [const SizedBox(width: 70), ...List.generate(totalHours, (i) => SizedBox(width: 25, child: Text("${state.startHour + i}h", textAlign: TextAlign.center, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.grey))))]), const Divider(), ...data.entries.map((cat) => Row(children: [SizedBox(width: 70, child: Text(cat.key, style: const TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis)), ...List.generate(totalHours, (i) { int val = cat.value[state.startHour + i] ?? 0; return Container(width: 23, height: 23, margin: const EdgeInsets.all(1), decoration: BoxDecoration(color: Colors.orange.withOpacity((val / 5).clamp(0.0, 1.0)), borderRadius: BorderRadius.circular(2)), child: Center(child: Text(val > 0 ? "$val" : "", style: const TextStyle(fontSize: 7)))); })])).toList()]))); }
  Widget _buildFinanceTable(AppState state) { var report = state.dailyFinanceReport; return Card(child: Padding(padding: const EdgeInsets.all(12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Finance History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const Divider(), const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(flex: 2, child: Text("Date", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))), Expanded(child: Text("Rev", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))), Expanded(child: Text("Profit", textAlign: TextAlign.right, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)))])), const Divider(), ...report.take(5).map((data) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(flex: 2, child: Text(data['date'], style: const TextStyle(fontSize: 10))), Expanded(child: Text("\$${data['revenue'].toInt()}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))), Expanded(child: Text("\$${data['profit'].toInt()}", textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)))]))).toList()]))); }
}

// --- CLASS 2: MENU MANAGEMENT TAB ---
class AdminMenuEditor extends StatefulWidget {
  const AdminMenuEditor({super.key});
  @override
  State<AdminMenuEditor> createState() => _AdminMenuEditorState();
}

class _AdminMenuEditorState extends State<AdminMenuEditor> {
  String selectedCategory = "All";

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    List<MenuItem> filteredItems = selectedCategory == "All" ? state.menu : state.menu.where((i) => i.category == selectedCategory).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(children: [
          Padding(padding: const EdgeInsets.all(24.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Menu Management", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Row(children: [
                  ElevatedButton.icon(onPressed: () => _showAddCat(context, state), icon: const Icon(Icons.category, size: 16), label: const Text("New Category"), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black)),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(onPressed: () => _showEdit(context, state), icon: const Icon(Icons.add, size: 16), label: const Text("Add Item"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white)),
                ])
              ])),
          SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 24), children: ["All", ...state.categories].map((cat) {
                bool isSel = selectedCategory == cat;
                return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(cat, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : Colors.black87)), selected: isSel, onSelected: (s) => setState(() => selectedCategory = cat), selectedColor: Colors.orange));
              }).toList())),
          Expanded(child: GridView.builder(padding: const EdgeInsets.all(24), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.85, crossAxisSpacing: 16, mainAxisSpacing: 16), itemCount: filteredItems.length, itemBuilder: (c, i) => _buildCard(context, filteredItems[i], state))),
      ]),
    );
  }

  Widget _buildCard(BuildContext context, MenuItem item, AppState state) => Card(
    clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
    color: Colors.white,
    child: Column(children: [
        SizedBox(height: 100, width: double.infinity, child: Image.network(item.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[100], child: const Icon(Icons.fastfood, color: Colors.grey, size: 30)))),
        Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Sell:", style: TextStyle(fontSize: 10)), Text("\$${item.price.toInt()}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Cost:", style: TextStyle(fontSize: 10)), Text("\$${item.costPrice.toInt()}", style: const TextStyle(fontSize: 10))]),
              const SizedBox(height: 10),
              Row(children: [
                  Expanded(child: SizedBox(height: 25, child: ElevatedButton(onPressed: () => _showEdit(context, state, item: item), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[100], foregroundColor: Colors.black, elevation: 0), child: const Text("Edit", style: TextStyle(fontSize: 10))))),
                  const SizedBox(width: 4),
                  Expanded(child: SizedBox(height: 25, child: ElevatedButton(onPressed: () => state.removeMenuItem(item.id), style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red, elevation: 0), child: const Text("Del", style: TextStyle(fontSize: 10))))),
              ])
        ]))
    ]),
  );

  void _showAddCat(BuildContext context, AppState state) {
    final c = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("New Category"), content: TextField(controller: c), actions: [ElevatedButton(onPressed: () { if(c.text.isNotEmpty) state.addCategory(c.text); Navigator.pop(ctx); }, child: const Text("Create"))]));
  }

  void _showEdit(BuildContext context, AppState state, {MenuItem? item}) {
    final n = TextEditingController(text: item?.name ?? ""); final p = TextEditingController(text: item?.price.toString() ?? ""); final cp = TextEditingController(text: item?.costPrice.toString() ?? ""); final img = TextEditingController(text: item?.imageUrl ?? "");
    String cat = item?.category ?? (state.categories.isNotEmpty ? state.categories[0] : "General");
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => AlertDialog(
        title: Text(item == null ? "Add Item" : "Edit Item"),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: n, decoration: const InputDecoration(labelText: "Name")), TextField(controller: p, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number), TextField(controller: cp, decoration: const InputDecoration(labelText: "Cost"), keyboardType: TextInputType.number), DropdownButtonFormField<String>(value: cat, items: state.categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => ss(() => cat = v!)), TextField(controller: img, decoration: const InputDecoration(labelText: "Image URL"))])),
        actions: [ElevatedButton(onPressed: () { state.addMenuItem(MenuItem(id: item?.id ?? const Uuid().v4(), name: n.text, price: double.parse(p.text), costPrice: double.parse(cp.text), category: cat, description: "", imageUrl: img.text)); Navigator.pop(ctx); }, child: const Text("Save"))],
    )));
  }
}