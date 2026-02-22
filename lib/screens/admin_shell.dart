import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../models/menu_item.dart';
import '../models/order_model.dart';
import 'package:intl/intl.dart';
import 'admin_employee_screen.dart';
import 'dart:math' as math;
import '../services/storage_service.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("FLASH BUSINESS BI",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          bottom: const TabBar(
              labelColor: Colors.orange,
              indicatorColor: Colors.orange,
              tabs: [
                Tab(text: "ANALYTICS"),
                Tab(text: "MENU MANAGEMENT"),
                Tab(text: "EMPLOYEES")
              ]),
        ),
        body: TabBarView(children: [
          const AdminAnalytics(),
          const AdminMenuEditor(),
          AdminEmployeeScreen()
        ]),
      ),
    );
  }
}

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
    if (state.orders.isEmpty)
      return const Center(child: Text("No Sales Data Yet"));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(children: [
          _tile("Today Revenue", "\$${state.todayRevenue.toInt()}",
              Colors.green, Icons.money),
          const SizedBox(width: 15),
          _tile("Today Profit", "\$${state.todayProfit.toInt()}", Colors.blue,
              Icons.trending_up),
          const SizedBox(width: 15),
          _tile("Today Orders", "${state.todayOrdersCount}", Colors.orange,
              Icons.shopping_basket),
        ]),
        const SizedBox(height: 32),
        _header("Daily Activity (Orders per Hour)"),
        _graphCard(_buildBarChart(state)),
        const SizedBox(height: 32),
        _header("7-Day Revenue Trend (Log Scale)"),
        _graphCard(_buildLineChart(state)),
        const SizedBox(height: 32),
        _header("Weekly Peak Hours (Staffing)"),
        _buildWeeklyPeakHeatmap(state),
        const SizedBox(height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _header("Recent Orders Today"),
          Row(children: [
            IconButton(
                icon: const Icon(Icons.calendar_month, color: Colors.orange),
                onPressed: () => _openHistoryExplorer(context, state)),
            TextButton(
                onPressed: () => _openHistoryExplorer(context, state),
                child: const Text("View All Today",
                    style: TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold)))
          ])
        ]),
        _buildOrderList(context, state.ordersToday, limit: 5),
        const SizedBox(height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Expanded(flex: 3, child: _buildRankingColumn(state)),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: _buildFinanceTable(state)),
        ]),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[900],
              minimumSize: const Size(double.infinity, 60)),
          onPressed: () => state.downloadBusinessReport(),
          icon: const Icon(Icons.download, color: Colors.white),
          label: const Text("DOWNLOAD ANALYTICS REPORT (.CSV)",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  void _openHistoryExplorer(BuildContext context, AppState state) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => OrderHistoryExplorer(
                state: state,
                range: DateTimeRange(
                    start: DateTime.now(), end: DateTime.now()))));
  }

  Widget _tile(String t, String v, Color c, IconData i) => Expanded(
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: c.withOpacity(0.1))),
          child: Row(children: [
            Icon(i, color: c, size: 20),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(v,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold))
            ])
          ])));
  Widget _header(String t) => Text(t,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey));
  Widget _graphCard(Widget c) => Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: c);

  Widget _buildOrderList(BuildContext ctx, List<OrderModel> list,
      {int? limit, bool showDate = false}) {
    var display =
        limit != null && list.length > limit ? list.take(limit).toList() : list;
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!)),
      child: Column(
          children: display
              .map((o) => ListTile(
                    onTap: () => _showDetail(ctx, o),
                    leading: const Icon(Icons.receipt_long,
                        color: Colors.orange, size: 20),
                    title: Text("Order #${o.id.substring(o.id.length - 6)}",
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        showDate
                            ? DateFormat('dd MMM, hh:mm a').format(o.timestamp)
                            : DateFormat('hh:mm a').format(o.timestamp),
                        style: const TextStyle(fontSize: 11)),
                    trailing: Text("\$${o.total.toStringAsFixed(2)}",
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                  ))
              .toList()),
    );
  }

  void _showDetail(BuildContext ctx, OrderModel o) {
    showDialog(
        context: ctx,
        builder: (c) => AlertDialog(
              title: Text("Order Receipt #${o.id.substring(o.id.length - 6)}"),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: o.itemQuantities.entries.map((e) {
                    final item = o.items.firstWhere((i) => i.id == e.key,
                        orElse: () => MenuItem(
                            id: '',
                            name: 'Removed',
                            price: 0,
                            costPrice: 0,
                            category: '',
                            description: '',
                            imageUrl: ''));
                    return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${e.value}x ${item.name}"),
                          Text("\$${(item.price * e.value).toStringAsFixed(2)}")
                        ]);
                  }).toList()),
            ));
  }

  Widget _buildRankingColumn(AppState s) => Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        ListTile(
            title: const Text("Top Sellers",
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (v) => v == "View All"
                    ? _showFullRank(context, s)
                    : setState(() => _rankingFilter = v),
                itemBuilder: (c) => [
                      const PopupMenuItem(
                          value: "Best-selling", child: Text("Best")),
                      const PopupMenuItem(
                          value: "Least-selling", child: Text("Least")),
                      const PopupMenuItem(
                          value: "View All", child: Text("View All"))
                    ])),
        ...s.todayRankedItems.take(5).toList().asMap().entries.map((e) =>
            ListTile(
                leading: CircleAvatar(
                    radius: 12,
                    backgroundColor:
                        e.key == 0 ? Colors.amber : Colors.grey[100],
                    child: Text("${e.key + 1}",
                        style: const TextStyle(fontSize: 10))),
                title: Text(e.value['name']),
                trailing: Text("${e.value['qty']} sold")))
      ]));

  void _showFullRank(BuildContext ctx, AppState s) {
    Navigator.push(
        ctx,
        MaterialPageRoute(
            builder: (c) => DefaultTabController(
                length: 2,
                child: Scaffold(
                    appBar: AppBar(
                        title: const Text("Full Rankings"),
                        bottom: const TabBar(
                            tabs: [Tab(text: "Today"), Tab(text: "All-Time")])),
                    body: TabBarView(children: [
                      _rankTab(s.todayRankedItems),
                      _rankTab(s.rankedItems)
                    ])))));
  }

  Widget _rankTab(List<Map<String, dynamic>> d) =>
      ListView(padding: const EdgeInsets.all(16), children: [
        DataTable(
            columns: const [
              DataColumn(label: Text("Item")),
              DataColumn(label: Text("Qty")),
              DataColumn(label: Text("Rev"))
            ],
            rows: d
                .map((e) => DataRow(cells: [
                      DataCell(Text(e['name'])),
                      DataCell(Text("${e['qty']}")),
                      DataCell(Text("\$${(e['rev'] ?? 0).toInt()}"))
                    ]))
                .toList())
      ]);

  Widget _buildBarChart(AppState s) {
    var d = s.hourlyOrderCounts;
    double a =
        d.values.isEmpty ? 0 : d.values.reduce((a, b) => a + b) / d.length;
    return BarChart(BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (v, m) => Text("${v.toInt()}h",
                        style: const TextStyle(fontSize: 8)))),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false))),
        barGroups: d.entries
            .map((e) => BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                      toY: e.value.toDouble(),
                      color: e.value > a ? Colors.red : Colors.orange,
                      width: 10)
                ]))
            .toList()));
  }

  Widget _buildLineChart(AppState s) {
    var t = s.weeklyTrendData;
    List<FlSpot> spots = t.asMap().entries.map((e) {
      double a = e.value['amount'] as double;
      return FlSpot(e.key.toDouble(), a > 0 ? math.log(a) / math.ln10 : 0);
    }).toList();
    return LineChart(LineChartData(
        lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (s) => Colors.blueGrey.withOpacity(0.8),
                fitInsideHorizontally: true,
                getTooltipItems: (ts) => ts
                    .map((s) => LineTooltipItem(
                        '${t[s.x.toInt()]['day']}: \$${t[s.x.toInt()]['amount'].toInt()}',
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)))
                    .toList())),
        gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: Colors.grey[200], strokeWidth: 1)),
        titlesData: FlTitlesData(
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (v, m) {
                      int i = v.toInt();
                      return (i >= 0 && i < t.length)
                          ? Text(t[i]['day'],
                              style: const TextStyle(fontSize: 8))
                          : const Text('');
                    })),
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 1,
                    getTitlesWidget: (v, m) => Text(
                        '\$${math.pow(10, v).toInt()}',
                        style: const TextStyle(fontSize: 7))))),
        lineBarsData: [
          LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData:
                  BarAreaData(show: true, color: Colors.blue.withOpacity(0.05)))
        ],
        minY: 0,
        maxY: 5));
  }

  Widget _buildWeeklyPeakHeatmap(AppState s) {
    var d = s.weeklyPeakHeatmap;
    int th = (s.endHour - s.startHour) + 1;
    List<String> dy = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(children: [
          Row(children: [
            const SizedBox(width: 40),
            ...List.generate(
                th,
                (i) => Expanded(
                    child: Text("${s.startHour + i}h",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey))))
          ]),
          const Divider(),
          ...List.generate(7, (idx) {
            int dn = idx + 1;
            return Row(children: [
              SizedBox(
                  width: 40,
                  child: Text(dy[dn], style: const TextStyle(fontSize: 8))),
              ...List.generate(th, (i) {
                int v = d[dn]?[s.startHour + i] ?? 0;
                return Expanded(
                    child: Container(
                        height: 18,
                        margin: const EdgeInsets.all(0.5),
                        decoration: BoxDecoration(
                            color: Colors.deepPurple
                                .withOpacity((v / 5).clamp(0.0, 1.0)),
                            borderRadius: BorderRadius.circular(2)),
                        child: Center(
                            child: Text(v > 0 ? "$v" : "",
                                style: const TextStyle(
                                    fontSize: 7, color: Colors.white)))));
              })
            ]);
          })
        ]));
  }

  Widget _buildFinanceTable(AppState s) {
    var r = s.dailyFinanceReport;
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(children: [
          const Text("Finance History",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const Divider(),
          ...r
              .take(5)
              .map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(d['date'], style: const TextStyle(fontSize: 10)),
                        Text("\$${d['revenue'].toInt()}",
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold)),
                        Text("\$${d['profit'].toInt()}",
                            style: const TextStyle(
                                fontSize: 10, color: Colors.green))
                      ])))
              .toList()
        ]));
  }

  Widget _buildHeatmap(AppState s) {
    return Container();
  }
}

class OrderHistoryExplorer extends StatelessWidget {
  final AppState state;
  final DateTimeRange range;
  const OrderHistoryExplorer(
      {super.key, required this.state, required this.range});
  @override
  Widget build(BuildContext context) {
    final filtered = state.orders.where((o) {
      final start =
          DateTime(range.start.year, range.start.month, range.start.day);
      final end =
          DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
      return o.timestamp.isAfter(start) && o.timestamp.isBefore(end);
    }).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
          title: const Text("History Explorer"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black),
      body: Column(children: [
        Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(children: [
              const Icon(Icons.date_range, color: Colors.orange),
              const SizedBox(width: 15),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("ACTIVE FILTER",
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold)),
                Text(
                    "${DateFormat('dd MMM').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
              const Spacer(),
              ElevatedButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text("GET HISTORY"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white)),
            ])),
        Expanded(
            child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: filtered.length,
                itemBuilder: (c, i) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                        onTap: () => _AdminAnalyticsState()
                            ._showDetail(context, filtered[i]),
                        leading: const Icon(Icons.receipt_long,
                            color: Colors.orange),
                        title: Text(
                            "Order #${filtered[i].id.substring(filtered[i].id.length - 6)}",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('dd MMM, hh:mm a')
                            .format(filtered[i].timestamp)),
                        trailing: Text("\$${filtered[i].total.toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)))))),
      ]),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: DateTime.now(),
        saveText: "GET HISTORY");
    if (picked != null)
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (c) =>
                  OrderHistoryExplorer(state: state, range: picked)));
  }
}

// --- CLASS 2: MENU MANAGEMENT TAB (COMPACT & FIXED) ---
class AdminMenuEditor extends StatefulWidget {
  const AdminMenuEditor({super.key});
  @override
  State<AdminMenuEditor> createState() => _AdminMenuEditorState();
}

class _AdminMenuEditorState extends State<AdminMenuEditor> {
  String selectedCategory = "All";

// Add this line at the top of AdminMenuEditor class
  final StorageService _storage = StorageService();

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    List<MenuItem> filteredItems = selectedCategory == "All"
        ? state.menu
        : state.menu.where((i) => i.category == selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Top Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Manage Menu",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey)),
                Row(children: [
                  _headerBtn("New Cat", Icons.category, Colors.white,
                      Colors.black, () => _showAddCat(context, state)),
                  const SizedBox(width: 10),
                  _headerBtn("Add Item", Icons.add, Colors.blueAccent,
                      Colors.white, () => _showEdit(context, state)),
                ])
              ],
            ),
          ),

          // Horizontal Category Tabs
          SizedBox(
            height: 45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: ["All", ...state.categories].map((cat) {
                bool isSel = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat,
                        style: TextStyle(
                            fontSize: 12,
                            color: isSel ? Colors.white : Colors.black87)),
                    selected: isSel,
                    onSelected: (s) => setState(() => selectedCategory = cat),
                    selectedColor: Colors.orange,
                  ),
                );
              }).toList(),
            ),
          ),

          // --- COMPACT GRID ---
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredItems.length,
              itemBuilder: (c, i) =>
                  _buildCompactCard(context, filteredItems[i], state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerBtn(String l, IconData i, Color bg, Color tx, VoidCallback p) =>
      ElevatedButton.icon(
        onPressed: p,
        icon: Icon(i, size: 14),
        label: Text(l, style: const TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: tx,
            elevation: 0,
            side: bg == Colors.white
                ? BorderSide(color: Colors.grey[300]!)
                : null),
      );

  Widget _buildCompactCard(BuildContext ctx, MenuItem item, AppState s) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(12)),
            child: SizedBox(
              width: 90,
              height: double.infinity,
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                    color: Colors.grey[50],
                    child: const Icon(Icons.fastfood, color: Colors.grey)),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  _miniRow("Sell:", "\$${item.price.toInt()}"),
                  _miniRow("Cost:", "\$${item.costPrice.toInt()}"),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _smallActionBtn("Edit", Colors.blue,
                          () => _showEdit(ctx, s, item: item)),
                      const SizedBox(width: 8),
                      _smallActionBtn(
                          "Del", Colors.red, () => s.removeMenuItem(item.id)),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniRow(String l, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          Text(v,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _smallActionBtn(String l, Color c, VoidCallback p) => InkWell(
        onTap: p,
        child: Text(l,
            style:
                TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c)),
      );

  // --- LOGIC FUNCTIONS (NAMES ARE NOW CORRECT) ---

  void _showAddCat(BuildContext ctx, AppState s) {
    final c = TextEditingController();
    showDialog(
        context: ctx,
        builder: (t) => AlertDialog(
                title: const Text("New Category"),
                content: TextField(controller: c),
                actions: [
                  ElevatedButton(
                      onPressed: () {
                        if (c.text.isNotEmpty) s.addCategory(c.text);
                        Navigator.pop(t);
                      },
                      child: const Text("Create"))
                ]));
  }

  void _showEdit(BuildContext context, AppState state, {MenuItem? item}) {
    final n = TextEditingController(text: item?.name ?? "");
    final p = TextEditingController(text: item?.price.toString() ?? "");
    final cp = TextEditingController(text: item?.costPrice.toString() ?? "");
    final img = TextEditingController(text: item?.imageUrl ?? "");
    String selectedCat = item?.category ??
        (state.categories.isNotEmpty ? state.categories[0] : "General");

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: Text(item == null ? "Add New Item" : "Edit Item"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🖼️ INSTANT IMAGE PREVIEW
                Container(
                  height: 80,
                  width: 80,
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10)),
                  child: img.text.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(img.text,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(
                                  Icons.broken_image,
                                  color: Colors.red)))
                      : const Icon(Icons.image_search, color: Colors.grey),
                ),

                TextField(
                    controller: n,
                    decoration: const InputDecoration(labelText: "Name")),
                TextField(
                    controller: p,
                    decoration:
                        const InputDecoration(labelText: "Selling Price"),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: cp,
                    decoration: const InputDecoration(labelText: "Cost"),
                    keyboardType: TextInputType.number),

                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  items: state.categories
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => ss(() => selectedCat = v!),
                  decoration: const InputDecoration(labelText: "Category"),
                ),

                // 🔗 IMAGE URL BOX
                TextField(
                  controller: img,
                  decoration:
                      const InputDecoration(labelText: "Paste Image URL here"),
                  onChanged: (v) =>
                      ss(() {}), // Refresh preview when typing/pasting
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () {
                  if (n.text.isEmpty || p.text.isEmpty) return;
                  state.addMenuItem(MenuItem(
                      id: item?.id ?? const Uuid().v4(),
                      name: n.text,
                      price: double.parse(p.text),
                      costPrice: double.parse(cp.text),
                      category: selectedCat,
                      description: "",
                      imageUrl: img.text));
                  Navigator.pop(ctx);
                },
                child: const Text("Save"))
          ],
        ),
      ),
    );
  }
}
