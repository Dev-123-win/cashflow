class Withdrawal {
  final String withdrawalId;
  final String userId;
  final double amount;
  final String upiId;
  final String status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? transactionRef;

  Withdrawal({
    required this.withdrawalId,
    required this.userId,
    required this.amount,
    required this.upiId,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.transactionRef,
  });

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      withdrawalId: json['withdrawalId'] ?? json.keys.first ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      upiId: json['upiId'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'].toString())
          : null,
      transactionRef: json['transactionRef'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'withdrawalId': withdrawalId,
      'userId': userId,
      'amount': amount,
      'upiId': upiId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'transactionRef': transactionRef,
    };
  }
}
