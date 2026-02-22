import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🔥 Added for AppState
import '../models/employee_model.dart';
import '../services/employee_service.dart';
import '../providers/app_state.dart'; // 🔥 Added for currentBizId

class AdminEmployeeScreen extends StatelessWidget {
  AdminEmployeeScreen({super.key});

  final EmployeeService _service = EmployeeService();

  @override
  Widget build(BuildContext context) {
    // 🔥 Get the currently logged in Business ID from the Brain
    final state = Provider.of<AppState>(context);
    final String bizId = state.currentBizId ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context, bizId),
        label: const Text("Add Employee", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.person_add_alt_1),
        backgroundColor: Colors.blueAccent,
      ),
      body: bizId.isEmpty 
      ? const Center(child: Text("Error: No Business Logged In"))
      : StreamBuilder<List<EmployeeModel>>(
        // 🔥 Now filtering by bizId
        stream: _service.getEmployees(bizId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final emps = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text("Staff Management", 
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
              const SizedBox(height: 20),
              
              emps.isEmpty 
              ? const Center(child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Text("No employees registered yet.", style: TextStyle(color: Colors.grey)),
                ))
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, 
                    childAspectRatio: 1.6,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: emps.length,
                  itemBuilder: (context, index) => _buildEmployeeCard(context, emps[index], bizId),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, EmployeeModel emp, String bizId) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE1E2E5)),
        borderRadius: BorderRadius.circular(15)
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text("ID: ${emp.id}", style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(emp.shift, style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _actionBtn("Edit", const Color(0xFFF1F3F4), Colors.black87, () => _showAddEditDialog(context, bizId, emp: emp))),
                const SizedBox(width: 8),
                Expanded(child: _actionBtn("Delete", const Color(0xFFFFEBEE), Colors.red, () => _confirmDelete(context, emp, bizId))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color bg, Color text, VoidCallback press) => SizedBox(
    height: 32,
    child: ElevatedButton(
      onPressed: press,
      style: ElevatedButton.styleFrom(backgroundColor: bg, foregroundColor: text, elevation: 0, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ),
  );

  void _confirmDelete(BuildContext context, EmployeeModel emp, String bizId) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Remove Employee?"),
      content: Text("Are you sure you want to delete ${emp.name}?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
        TextButton(onPressed: () { _service.deleteEmployee(bizId, emp.id); Navigator.pop(c); }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  void _showAddEditDialog(BuildContext context, String bizId, {EmployeeModel? emp}) {
    final name = TextEditingController(text: emp?.name ?? "");
    final ph = TextEditingController(text: emp?.phone ?? "");
    final mail = TextEditingController(text: emp?.email ?? "");
    final pass = TextEditingController(text: emp?.password ?? "");
    
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(emp == null ? "Register Staff" : "Edit Staff"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(name, "Full Name", Icons.person),
                _field(ph, "Phone", Icons.phone, isNum: true),
                _field(mail, "Email", Icons.email),
                _field(pass, "Set Password", Icons.lock_outline),
                const Divider(),
                const Align(alignment: Alignment.centerLeft, child: Text("Shift Timing", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _timeBtn(context, "In: ${startTime.format(context)}", () async {
                      final p = await showTimePicker(context: context, initialTime: startTime);
                      if (p != null) setDialogState(() => startTime = p);
                    }),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("-")),
                    _timeBtn(context, "Out: ${endTime.format(context)}", () async {
                      final p = await showTimePicker(context: context, initialTime: endTime);
                      if (p != null) setDialogState(() => endTime = p);
                    }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              onPressed: () async {
                if(name.text.isEmpty || pass.text.isEmpty) return; 
                String id = emp?.id ?? _service.generateId();
                String formattedShift = "${startTime.format(context)} - ${endTime.format(context)}";
                final staff = EmployeeModel(id: id, name: name.text, phone: ph.text, email: mail.text, shift: formattedShift, password: pass.text);
                
                // 🔥 Saving inside the specific business sub-collection
                await _service.saveEmployee(bizId, staff);
                
                Navigator.pop(c);
                if (emp == null) _showIdSuccess(context, id);
              }, 
              child: const Text("Finish"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeBtn(BuildContext context, String text, VoidCallback press) => Expanded(
    child: OutlinedButton(
      onPressed: press,
      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.black87)),
    ),
  );

  Widget _field(TextEditingController c, String l, IconData i, {bool isNum = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(prefixIcon: Icon(i, size: 18), labelText: l, labelStyle: const TextStyle(fontSize: 12), border: const OutlineInputBorder()),
    ),
  );

  void _showIdSuccess(BuildContext context, String id) {
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: Colors.blueAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 60),
          const SizedBox(height: 20),
          const Text("STAFF REGISTERED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Generated ID:", style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Text(id, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ),
          const SizedBox(height: 25),
          SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blueAccent), onPressed: () => Navigator.pop(c), child: const Text("OK"))),
        ],
      ),
    ));
  }
}