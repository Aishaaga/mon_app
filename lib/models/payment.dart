enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
}

enum PaymentMethod {
  creditCard,
  debitCard,
  paypal,
  stripe,
  cash,
  bankTransfer,
}

class Payment {
  final String id;
  final String jobId;
  final String clientId;
  final String artisanId;
  final double amount;
  final String currency;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? transactionId;
  final String? description;
  final Map<String, dynamic>? metadata;

  Payment({
    required this.id,
    required this.jobId,
    required this.clientId,
    required this.artisanId,
    required this.amount,
    this.currency = 'EUR',
    required this.method,
    this.status = PaymentStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.transactionId,
    this.description,
    this.metadata,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] ?? '',
      jobId: map['jobId'] ?? '',
      clientId: map['clientId'] ?? '',
      artisanId: map['artisanId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'EUR',
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${map['method']}',
        orElse: () => PaymentMethod.creditCard,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${map['status']}',
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      completedAt: map['completedAt']?.toDate(),
      transactionId: map['transactionId'],
      description: map['description'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobId': jobId,
      'clientId': clientId,
      'artisanId': artisanId,
      'amount': amount,
      'currency': currency,
      'method': method.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'transactionId': transactionId,
      'description': description,
      'metadata': metadata,
    };
  }

  Payment copyWith({
    String? id,
    String? jobId,
    String? clientId,
    String? artisanId,
    double? amount,
    String? currency,
    PaymentMethod? method,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? transactionId,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return Payment(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      clientId: clientId ?? this.clientId,
      artisanId: artisanId ?? this.artisanId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      method: method ?? this.method,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      transactionId: transactionId ?? this.transactionId,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  String get statusText {
    switch (status) {
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.processing:
        return 'En traitement';
      case PaymentStatus.completed:
        return 'Terminé';
      case PaymentStatus.failed:
        return 'Échoué';
      case PaymentStatus.refunded:
        return 'Remboursé';
    }
  }

  String get methodText {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Carte de crédit';
      case PaymentMethod.debitCard:
        return 'Carte de débit';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.stripe:
        return 'Stripe';
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.bankTransfer:
        return 'Virement bancaire';
    }
  }
}

class PaymentRequest {
  final String jobId;
  final String clientId;
  final String artisanId;
  final double amount;
  final PaymentMethod method;
  final String? description;

  PaymentRequest({
    required this.jobId,
    required this.clientId,
    required this.artisanId,
    required this.amount,
    required this.method,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'clientId': clientId,
      'artisanId': artisanId,
      'amount': amount,
      'method': method.toString().split('.').last,
      'description': description,
    };
  }
}