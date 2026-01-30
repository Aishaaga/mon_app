import 'package:cloud_firestore/cloud_firestore.dart';

class Request {
  final String? id;
  final String clientId;
  final String category;
  final String description;
  final List<String> photos;
  final Timestamp preferredDate;
  final double estimatedBudget;
  final String address;
  final String status;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Request({
    this.id,
    required this.clientId,
    required this.category,
    required this.description,
    required this.photos,
    required this.preferredDate,
    required this.estimatedBudget,
    required this.address,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'category': category,
      'description': description,
      'photos': photos,
      'preferredDate': preferredDate,
      'estimatedBudget': estimatedBudget,
      'address': address,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Créer depuis Map de Firestore
  factory Request.fromMap(Map<String, dynamic> map, String? id) {
    return Request(
      id: id,
      clientId: map['clientId'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      preferredDate: map['preferredDate'] ?? Timestamp.now(),
      estimatedBudget: (map['estimatedBudget'] ?? 0).toDouble(),
      address: map['address'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }

  // Copier avec modifications
  Request copyWith({
    String? id,
    String? clientId,
    String? category,
    String? description,
    List<String>? photos,
    Timestamp? preferredDate,
    double? estimatedBudget,
    String? address,
    String? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Request(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      category: category ?? this.category,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      preferredDate: preferredDate ?? this.preferredDate,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      address: address ?? this.address,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Obtenir le statut formaté en français
  String get statusFormatted {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Acceptée';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }
}