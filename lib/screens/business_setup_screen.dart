import 'package:flutter/material.dart';
import '../services/auth_services.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});
  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final PageController _pages = PageController();
  final AuthService _auth = AuthService();

  // Controllers
  final bName = TextEditingController();
  final bEmail = TextEditingController();
  final bAddr = TextEditingController();
  final oName = TextEditingController();
  final oPhone = TextEditingController();
  final oEmail = TextEditingController();
  final pass = TextEditingController();
  final confirmPass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Business Setup")),
      body: PageView(
        controller: _pages,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _stepOne(),
          _stepTwo(),
        ],
      ),
    );
  }

  Widget _stepOne() => ListView(padding: const EdgeInsets.all(24), children: [
        const Text("Business Details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _input(bName, "Business Name"),
        _input(bEmail, "Business Email"),
        _input(bAddr, "Address"),
        const SizedBox(height: 30),
        const Text("Owner Details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _input(oName, "Owner Name"),
        _input(oPhone, "Phone"),
        _input(oEmail, "Email"),
        const SizedBox(height: 30),
        ElevatedButton(
            onPressed: () => _pages.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease),
            child: const Text("Next"))
      ]);

  Widget _stepTwo() => ListView(padding: const EdgeInsets.all(24), children: [
        const Text("Set Security",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _input(pass, "Password", hide: true),
        _input(confirmPass, "Confirm Password", hide: true),
        const SizedBox(height: 30),
        ElevatedButton(
            onPressed: _finishSetup, child: const Text("Confirm & Register"))
      ]);

  void _finishSetup() async {
    if (pass.text != confirmPass.text) return;
    String bizId = _auth.generateBusinessId();

    await _auth.registerBusiness({
      'businessId': bizId,
      'businessName': bName.text,
      'businessEmail': bEmail.text,
      'address': bAddr.text,
      'ownerName': oName.text,
      'ownerPhone': oPhone.text,
      'ownerEmail': oEmail.text,
      'password': pass.text,
    });

    _showIdPopup(bizId);
  }

  void _showIdPopup(String id) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
              title: const Text("Business Registered!"),
              content: Text("Your unique Business ID is:\n\n$id",
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(c);
                      Navigator.pop(context);
                    },
                    child: const Text("OK"))
              ],
            ));
  }

  Widget _input(TextEditingController c, String l, {bool hide = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: TextField(
            controller: c,
            obscureText: hide,
            decoration: InputDecoration(
                labelText: l, border: const OutlineInputBorder())),
      );
}
