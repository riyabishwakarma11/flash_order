class EmployeeModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String shift;
  final String password; // NEW FIELD

  EmployeeModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.shift,
    required this.password, // ADDED HERE
  });

  Map<String, dynamic> toMap() => {
    'id': id, 
    'name': name, 
    'phone': phone, 
    'email': email, 
    'shift': shift,
    'password': password, // ADDED HERE
  };

  factory EmployeeModel.fromMap(Map<String, dynamic> map, String docId) {
    return EmployeeModel(
      id: docId,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      shift: map['shift'] ?? '',
      password: map['password'] ?? '', // ADDED HERE
    );
  }
}