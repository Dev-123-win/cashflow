class User {
  final String userId;
  final String email;
  final String displayName;
  final double totalEarnings;
  final double availableBalance;
  final double monthlyEarnings;
  final int totalTasks;
  final int completedTasks;
  final int streak;
  final DateTime createdAt;
  final String referralCode;
  final int referralCount;
  final double referralEarnings;
  final bool kycVerified;
  final String? upiId;
  final int failedWithdrawals;
  final bool accountLocked;

  User({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.totalEarnings,
    required this.availableBalance,
    required this.monthlyEarnings,
    required this.totalTasks,
    required this.completedTasks,
    required this.streak,
    required this.createdAt,
    required this.referralCode,
    required this.referralCount,
    required this.referralEarnings,
    required this.kycVerified,
    this.upiId,
    required this.failedWithdrawals,
    required this.accountLocked,
  });

  factory User.empty() {
    return User(
      userId: '',
      email: '',
      displayName: '',
      totalEarnings: 0,
      availableBalance: 0,
      monthlyEarnings: 0,
      totalTasks: 0,
      completedTasks: 0,
      streak: 0,
      createdAt: DateTime.now(),
      referralCode: '',
      referralCount: 0,
      referralEarnings: 0,
      kycVerified: false,
      failedWithdrawals: 0,
      accountLocked: false,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      totalEarnings: (json['totalEarned'] ?? json['totalEarnings'] ?? 0.0)
          .toDouble(),
      availableBalance: (json['availableBalance'] ?? 0.0).toDouble(),
      monthlyEarnings: (json['monthlyEarnings'] ?? 0.0).toDouble(),
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      streak: json['streak'] ?? json['currentStreak'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      referralCode: json['referralCode'] ?? '',
      referralCount: json['referralCount'] ?? 0,
      referralEarnings: (json['referralEarnings'] ?? 0.0).toDouble(),
      kycVerified: json['kycVerified'] ?? false,
      upiId: json['upiId'],
      failedWithdrawals: json['failedWithdrawals'] ?? 0,
      accountLocked: json['accountLocked'] ?? json['isAccountLocked'] ?? false,
    );
  }

  // Getters for backwards compatibility
  String get id => userId;
  int get currentStreak => streak;

  User copyWith({
    String? userId,
    String? email,
    String? displayName,
    double? totalEarnings,
    double? availableBalance,
    double? monthlyEarnings,
    int? totalTasks,
    int? completedTasks,
    int? streak,
    DateTime? createdAt,
    String? referralCode,
    int? referralCount,
    double? referralEarnings,
    bool? kycVerified,
    String? upiId,
    int? failedWithdrawals,
    bool? accountLocked,
  }) {
    return User(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      availableBalance: availableBalance ?? this.availableBalance,
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      streak: streak ?? this.streak,
      createdAt: createdAt ?? this.createdAt,
      referralCode: referralCode ?? this.referralCode,
      referralCount: referralCount ?? this.referralCount,
      referralEarnings: referralEarnings ?? this.referralEarnings,
      kycVerified: kycVerified ?? this.kycVerified,
      upiId: upiId ?? this.upiId,
      failedWithdrawals: failedWithdrawals ?? this.failedWithdrawals,
      accountLocked: accountLocked ?? this.accountLocked,
    );
  }
}
