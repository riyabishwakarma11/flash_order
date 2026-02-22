class BusinessModel {
  final String businessId;
  final String businessName;
  final String businessEmail;
  final String address;
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final String password;

  BusinessModel({
    required this.businessId, required this.businessName, required this.businessEmail,
    required this.address, required this.ownerName, required this.ownerPhone,
    required this.ownerEmail, required this.password,
  });

  Map<String, dynamic> toMap() => {
    'businessId': businessId, 'businessName': businessName, 'businessEmail': businessEmail,
    'address': address, 'ownerName': ownerName, 'ownerPhone': ownerPhone,
    'ownerEmail': ownerEmail, 'password': password,
  };

  factory BusinessModel.fromMap(Map<String, dynamic> map) {
    return BusinessModel(
      businessId: map['businessId'] ?? '',
      businessName: map['businessName'] ?? '',
      businessEmail: map['businessEmail'] ?? '',
      address: map['address'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerPhone: map['ownerPhone'] ?? '',
      ownerEmail: map['ownerEmail'] ?? '',
      password: map['password'] ?? '',
    );
  }
}