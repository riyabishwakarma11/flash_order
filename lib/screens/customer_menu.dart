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
    
    // Dynamically get categories from the current menu
    List<String> categories = ["All", ...state.menu.map((e) => e.category).toSet().toList()];

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Menu", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            tabs: categories.map((cat) => Tab(text: cat)).toList(),
          ),
        ),
        body: TabBarView(
          children: categories.map((cat) {
            List<MenuItem> items = cat == "All" 
                ? state.menu 
                : state.menu.where((i) => i.category == cat).toList();
            
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // Compact view
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) => _buildFoodCard(context, items[index], state),
            );
          }).toList(),
        ),
        bottomNavigationBar: state.cartTotal > 0 ? _buildOrderButton(context, state) : null,
      ),
    );
  }

  Widget _buildFoodCard(BuildContext context, MenuItem item, AppState state) {
    int qty = state.getQuantity(item.id);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                item.imageUrl, 
                width: double.infinity, 
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.fastfood, color: Colors.orange),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text("\$${item.price.toStringAsFixed(2)}", style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => state.decrementItem(item.id), 
                icon: const Icon(Icons.remove_circle_outline, size: 18)
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text("$qty", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => state.incrementItem(item.id), 
                icon: const Icon(Icons.add_circle, color: Colors.orange, size: 18)
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildOrderButton(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange, 
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
        ),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CartScreen())),
        child: Text("VIEW CART (\$${state.cartTotal.toStringAsFixed(2)})", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}