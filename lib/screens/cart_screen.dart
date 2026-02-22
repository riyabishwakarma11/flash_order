import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'package:intl/intl.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final items = state.cartItems;

    return Scaffold(
      appBar: AppBar(title: const Text("Billing Preview"), elevation: 0),
      body: items.isEmpty
          ? const Center(child: Text("Cart is empty"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final qty = state.getQuantity(item.id);
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text("$qty x \$${item.price}"),
                        trailing:
                            Text("\$${(item.price * qty).toStringAsFixed(2)}"),
                      );
                    },
                  ),
                ),
                _buildTotalSection(context, state),
              ],
            ),
    );
  }

  Widget _buildTotalSection(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("GRAND TOTAL",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("\$${state.cartTotal.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15))),
            onPressed: () async {
              await state.placeOrder();
              _showBillDialog(context, state);
            },
            child: const Text("GENERATE BILL & PAY",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showBillDialog(BuildContext context, AppState state) {
    final order = state.lastPlacedOrder;
    if (order == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0)), // Classic bill shape
        title: const Center(child: Text("ORDER SUCCESSFUL")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("------- RECEIPT -------",
                style: TextStyle(fontFamily: 'monospace')),
            const SizedBox(height: 10),
            Text(
                "Date: ${DateFormat('dd/MM/yyyy HH:mm').format(order.timestamp)}"),
            Text("Order ID: ${order.id.substring(0, 8)}"),
            const Divider(),
            ...order.itemQuantities.entries.map((e) {
              final item = order.items.firstWhere((i) => i.id == e.key);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${e.value}x ${item.name}"),
                  Text("\$${(item.price * e.value).toInt()}")
                ],
              );
            }).toList(),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TOTAL"),
                Text("\$${order.total}",
                    style: const TextStyle(fontWeight: FontWeight.bold))
              ],
            ),
            const SizedBox(height: 20),
            const Text("Thank you for choosing us!",
                style: TextStyle(fontSize: 10)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c); // Close Dialog
              Navigator.pop(context); // Go back to Menu
            },
            child: const Text("PRINT & DONE"),
          )
        ],
      ),
    );
  }
}
