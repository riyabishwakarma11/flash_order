import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/employee_model.dart';

class EmployeeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔥 Now requires bizId
  Stream<List<EmployeeModel>> getEmployees(String bizId) {
    return _db.collection('businesses').doc(bizId).collection('employees').snapshots().map((snap) =>
        snap.docs.map((doc) => EmployeeModel.fromMap(doc.data(), doc.id)).toList());
  }

  String generateId() => "EMP-${Random().nextInt(9000) + 1000}";

  // 🔥 Now requires bizId
  Future<void> saveEmployee(String bizId, EmployeeModel emp) async {
    await _db.collection('businesses').doc(bizId).collection('employees').doc(emp.id).set(emp.toMap());
  }

  Future<void> deleteEmployee(String bizId, String id) async {
    await _db.collection('businesses').doc(bizId).collection('employees').doc(id).delete();
  }
}