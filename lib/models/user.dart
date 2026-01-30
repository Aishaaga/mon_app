import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  String id;
  String firstName;
  String lastName;
  String email;
  String phone;
  String address;
  String userType; // 'client' ou 'artisan'
  DateTime createdAt;
  DateTime? updatedAt;
  String? profileImageUrl;

  AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.userType,
    required this.createdAt,
    this.updatedAt,
    this.profileImageUrl,
  });

  // Factory constructor pour créer un User depuis Firestore
  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      userType: data['userType'] ?? 'client',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      profileImageUrl: data['profileImageUrl'],
    );
  }

  // Convertir User en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'userType': userType,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    };
  }

  // Getter pour le nom complet
  String get fullName => '$firstName $lastName';
}
