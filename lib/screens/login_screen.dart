import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/auth_services.dart';
import 'customer_menu.dart';
import 'admin_shell.dart';
import 'business_setup_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🌈 GRADIENT BACKGROUND
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 76, 55, 90),
              Colors.orange.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ⚡ LOGO SECTION
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 122, 110, 177)
                            .withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: const Icon(Icons.flash_on_rounded,
                      size: 80, color: Colors.orange),
                ),
                const SizedBox(height: 20),
                const Text("FLASH ORDER",
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        color: Color(0xFF1A1C1E))),
                const Text("The Future of Business Intelligence",
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500)),

                const SizedBox(height: 60),

                // 🏢 LOGIN CARD (Glassmorphism effect)
                Container(
                  width: 400,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      _loginBtn(context, "RECEPTIONIST LOGIN", Colors.orange,
                          true, Icons.restaurant_menu),
                      const SizedBox(height: 16),
                      _loginBtn(
                          context,
                          "ADMIN DASHBOARD",
                          const Color(0xFF2C3E50),
                          false,
                          Icons.admin_panel_settings),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text("New to Flash Order?",
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const BusinessSetupScreen())),
                        child: const Text("Register Your Business Now",
                            style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginBtn(BuildContext context, String title, Color color,
      bool isEmployee, IconData icon) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () => _showLoginPopup(context, isEmployee),
      ),
    );
  }

  void _showLoginPopup(BuildContext context, bool isEmployee) {
    final idCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Column(
          children: [
            Icon(
                isEmployee
                    ? Icons.badge_outlined
                    : Icons.business_center_outlined,
                color: Colors.orange,
                size: 40),
            const SizedBox(height: 15),
            Text(isEmployee ? "Staff Access" : "Owner Login",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: idCtrl,
                decoration: InputDecoration(
                    labelText: isEmployee ? "Employee ID" : "Business ID",
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_person_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  String id = idCtrl.text.trim();
                  String pass = passCtrl.text.trim();
                  if (isEmployee) {
                    var result = await _auth.employeeLogin(id, pass);
                    if (result != null) {
                      Provider.of<AppState>(context, listen: false)
                          .initializeBusiness(result['bizId']);
                      Navigator.pop(c);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => const CustomerMenu()));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Access Denied: Invalid Staff ID")));
                    }
                  } else {
                    bool success = await _auth.adminLogin(id, pass);
                    if (success) {
                      Provider.of<AppState>(context, listen: false)
                          .initializeBusiness(id);
                      Navigator.pop(c);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => const AdminShell()));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Access Denied: Invalid Admin ID")));
                    }
                  }
                },
                child: const Text("Verify & Enter")),
          )
        ],
      ),
    );
  }
}
