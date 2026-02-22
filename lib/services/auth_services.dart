import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AuthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- BUSINESS SETUP LOGIC (Required for your Setup Screen) ---
  String generateBusinessId() => "BIZ-${Random().nextInt(9000) + 1000}";

  Future<void> registerBusiness(Map<String, dynamic> data) async {
    await _db.collection('businesses').doc(data['businessId']).set(data);
  }

  // --- ADMIN LOGIN LOGIC ---
  Future<bool> adminLogin(String bizId, String pass) async {
    try {
      print("🔎 Checking Admin Login for: $bizId");
      var doc = await _db.collection('businesses').doc(bizId).get();

      if (!doc.exists) {
        print("❌ Business ID $bizId not found.");
        return false;
      }

      var data = doc.data();
      // Use .toString() to be safe with types
      if (data?['password'].toString() == pass.toString()) {
        print("✅ Admin Login Success!");
        return true;
      } else {
        print("❌ Password mismatch.");
        return false;
      }
    } catch (e) {
      print("❌ Admin Login Error: $e");
      return false;
    }
  }

  // --- EMPLOYEE LOGIN LOGIC ---
  Future<Map<String, dynamic>?> employeeLogin(String empId, String pass) async {
    print("🔍 Searching for Employee: $empId");
    try {
      var query = await _db
          .collectionGroup('employees')
          .where('id', isEqualTo: empId)
          .get();

      if (query.docs.isEmpty) {
        print("❌ Employee not found.");
        return null;
      }

      var empData = query.docs.first.data();
      if (empData['password'].toString() == pass.toString()) {
        String bizId = query.docs.first.reference.parent.parent!.id;
        print("✅ Employee Verified! Business: $bizId");
        return {'success': true, 'bizId': bizId};
      }
    } catch (e) {
      print("❌ Employee Auth Error: $e");
    }
    return null;
  }
}
