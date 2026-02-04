import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String? id;
  final String requestId;
  final String artisanId;
  final String clientId;
  final String category;
  final String description;
  final List<String> photos;
  final double estimatedBudget;
  final String address;
  final String status; // accepted, in_progress, completed, cancelled
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final Timestamp? startedAt;
  final Timestamp? completedAt;
  final double? quotePrice;
  final String? quoteDescription;
  final int? quoteDuration;
  final List<String>? quoteMaterials;
  final String? quoteNotes;
  final Timestamp? quotedAt;

  Job({
    this.id,
    required this.requestId,
    required this.artisanId,
    required this.clientId,
    required this.category,
    required this.description,
    required this.photos,
    required this.estimatedBudget,
    required this.address,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.completedAt,
    this.quotePrice,
    this.quoteDescription,
    this.quoteDuration,
    this.quoteMaterials,
    this.quoteNotes,
    this.quotedAt,
  });

  // Créer un Job à partir d'une Request acceptée
  factory Job.fromRequest({
    required String requestId,
    required String artisanId,
    required String clientId,
    required String category,
    required String description,
    required List<String> photos,
    required double estimatedBudget,
    required String address,
    required double quotePrice,
    required String quoteDescription,
    required int quoteDuration,
    required List<String> quoteMaterials,
    required String quoteNotes,
  }) {
    final now = Timestamp.now();
    return Job(
      requestId: requestId,
      artisanId: artisanId,
      clientId: clientId,
      category: category,
      description: description,
      photos: photos,
      estimatedBudget: estimatedBudget,
      address: address,
      status: 'accepted',
      createdAt: now,
      updatedAt: now,
      quotedAt: now,
      quotePrice: quotePrice,
      quoteDescription: quoteDescription,
      quoteDuration: quoteDuration,
      quoteMaterials: quoteMaterials,
      quoteNotes: quoteNotes,
    );
  }

  // Convertir depuis Firestore
  factory Job.fromMap(Map<String, dynamic> map, [String? id]) {
    return Job(
      id: id,
      requestId: map['requestId'] ?? '',
      artisanId: map['artisanId'] ?? '',
      clientId: map['clientId'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      estimatedBudget: (map['estimatedBudget'] ?? 0).toDouble(),
      address: map['address'] ?? '',
      status: map['status'] ?? 'accepted',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
      startedAt: map['startedAt'],
      completedAt: map['completedAt'],
      quotePrice: (map['quotePrice'])?.toDouble(),
      quoteDescription: map['quoteDescription'],
      quoteDuration: map['quoteDuration'],
      quoteMaterials: List<String>.from(map['quoteMaterials'] ?? []),
      quoteNotes: map['quoteNotes'],
      quotedAt: map['quotedAt'],
    );
  }

  // Convertir vers Firestore
  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'artisanId': artisanId,
      'clientId': clientId,
      'category': category,
      'description': description,
      'photos': photos,
      'estimatedBudget': estimatedBudget,
      'address': address,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'startedAt': startedAt,
      'completedAt': completedAt,
      'quotePrice': quotePrice,
      'quoteDescription': quoteDescription,
      'quoteDuration': quoteDuration,
      'quoteMaterials': quoteMaterials,
      'quoteNotes': quoteNotes,
      'quotedAt': quotedAt,
    };
  }

  // Copier avec modifications
  Job copyWith({
    String? id,
    String? requestId,
    String? artisanId,
    String? clientId,
    String? category,
    String? description,
    List<String>? photos,
    double? estimatedBudget,
    String? address,
    String? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? startedAt,
    Timestamp? completedAt,
    double? quotePrice,
    String? quoteDescription,
    int? quoteDuration,
    List<String>? quoteMaterials,
    String? quoteNotes,
    Timestamp? quotedAt,
  }) {
    return Job(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      artisanId: artisanId ?? this.artisanId,
      clientId: clientId ?? this.clientId,
      category: category ?? this.category,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      address: address ?? this.address,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      quotePrice: quotePrice ?? this.quotePrice,
      quoteDescription: quoteDescription ?? this.quoteDescription,
      quoteDuration: quoteDuration ?? this.quoteDuration,
      quoteMaterials: quoteMaterials ?? this.quoteMaterials,
      quoteNotes: quoteNotes ?? this.quoteNotes,
      quotedAt: quotedAt ?? this.quotedAt,
    );
  }

  // Getters pour l'affichage
  String get statusFormatted {
    switch (status) {
      case 'accepted':
        return 'Accepté';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  bool get isAccepted => status == 'accepted';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  // Calculer les gains (uniquement si terminé)
  double get earnings => isCompleted ? (quotePrice ?? estimatedBudget) : 0.0;

  @override
  String toString() {
    return 'Job(id: $id, category: $category, status: $status, budget: $estimatedBudget)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Job && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}