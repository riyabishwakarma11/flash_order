import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/menu_item.dart';
import 'cart_screen.dart';

class CustomerMenu extends StatelessWidget {
  const CustomerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    List<String> categories = ["All", ...state.categories];

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text("POS TERMINAL",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            tabs:
                categories.map((cat) => Tab(text: cat.toUpperCase())).toList(),
          ),
        ),
        body: TabBarView(
          children: categories.map((cat) {
            List<MenuItem> items = cat == "All"
                ? state.menu
                : state.menu.where((i) => i.category == cat).toList();

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // 5 items per row for professional POS look
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  _buildPOSCard(context, items[index], state),
            );
          }).toList(),
        ),
        bottomNavigationBar:
            state.cartTotal > 0 ? _buildCheckoutBar(context, state) : null,
      ),
    );
  }

  Widget _buildPOSCard(BuildContext context, MenuItem item, AppState state) {
    int qty = state.getQuantity(item.id);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // IMAGE SECTION
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                item.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.fastfood, color: Colors.grey, size: 30),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1),
                Text("\$${item.price.toStringAsFixed(2)}",
                    style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        onPressed: () => state.decrementItem(item.id),
                        icon:
                            const Icon(Icons.remove_circle_outline, size: 20)),
                    Text("$qty",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                        onPressed: () => state.incrementItem(item.id),
                        icon: const Icon(Icons.add_circle,
                            color: Colors.orange, size: 20)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15))),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (c) => const CartScreen())),
        child: Text(
            "PROCEED TO BILLING (\$${state.cartTotal.toStringAsFixed(2)})",
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
    );
  }
}
