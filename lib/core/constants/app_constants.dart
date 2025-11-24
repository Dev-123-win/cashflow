class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://earnquest.workers.dev';

  // API Endpoints
  static const String taskEarningEndpoint = '/api/earn/task';
  static const String gameEarningEndpoint = '/api/earn/game';
  static const String adEarningEndpoint = '/api/earn/ad';
  static const String spinEndpoint = '/api/spin';
  static const String leaderboardEndpoint = '/api/leaderboard';
  static const String withdrawalEndpoint = '/api/withdrawal/request';
  static const String userStatsEndpoint = '/api/user/stats';

  // Daily Limits (OPTIMIZED for profitability)
  static const double maxDailyEarnings = 1.20; // Reduced from 1.50
  static const int maxTasksPerDay = 3;
  static const int maxGamesPerDay = 6;
  static const int maxAdsPerDay = 15;
  static const int maxSpinsPerDay = 1;

  // Withdrawal Settings (OPTIMIZED - Backend source-of-truth)
  static const double minWithdrawalAmount = 100.0; // Increased from 50.0
  static const double maxWithdrawalPerRequest = 5000.0;
  static const int minAccountAgeDays = 7;
  static const double withdrawalFeePercentage = 0.02; // 2% fee

  // Task Rewards (OPTIMIZED - Reduced by 15%)
  static const Map<String, double> taskRewards = {
    'survey': 0.085, // Was 0.10
    'social_share': 0.085, // Was 0.10
    'app_rating': 0.085, // Was 0.10
  };

  // Game Rewards (OPTIMIZED - Reduced by 25%)
  static const Map<String, double> gameRewards = {
    'tictactoe': 0.06, // Was 0.08
    'memory_match': 0.06, // Was 0.08
  };

  // Ad Rewards (OPTIMIZED - Reduced by 15%)
  static const double rewardedAdReward = 0.025; // Was 0.03
  static const double interstitialAdReward = 0.02;

  // Spin Rewards (OPTIMIZED - Backend source-of-truth)
  static const double spinMinReward = 0.05;
  static const double spinMaxReward = 0.75; // Reduced from 1.00
  static const List<double> spinRewards = [
    0.05,
    0.10,
    0.15,
    0.20,
    0.30,
    0.50,
    0.75, // Max reduced from 1.00
  ];

  // Cooldown Periods (in minutes)
  static const int taskCooldownMinutes = 0;
  static const int gameCooldownMinutes = 30;
  static const int adCooldownMinutes = 0;

  // Streak Bonuses
  static const Map<int, double> streakBonuses = {7: 0.50, 14: 1.00, 30: 2.00};

  // Referral Settings
  static const double referralReward = 2.00;
  static const double referralLimit = 10.0;

  // App Settings
  static const String appVersion = '1.0.0';
  static const String appName = 'EarnQuest';

  // SharedPreferences Keys
  static const String userIdKey = 'userId';
  static const String userEmailKey = 'userEmail';
  static const String userBalanceKey = 'userBalance';
  static const String userStreakKey = 'userStreak';
  static const String lastTaskTimeKey = 'lastTaskTime';
  static const String lastGameTimeKey = 'lastGameTime';
  static const String lastAdTimeKey = 'lastAdTime';
  static const String lastSpinTimeKey = 'lastSpinTime';

  // Ad Unit IDs (Configured for Rewardly Firebase Project)
  // Production App ID
  static const String appId = 'ca-app-pub-1006454812188~6738625297';

  // Test Ad Unit IDs (Google Test Ads - Use during development)
  static const String appOpenAdUnitId =
      'ca-app-pub-3940256099942544/5419468566'; //  App Open Ad
  static const String rewardedInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/6978759866'; //  Rewarded Interstitial
  static const String bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; //  Banner
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712'; //  Interstitial
  static const String nativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110'; //  Native
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917'; // Rewarded AD

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String transactionsCollection = 'transactions';
  static const String withdrawalsCollection = 'withdrawals';
  static const String leaderboardCollection = 'leaderboard';
  static const String dailySpinsCollection = 'daily_spins';
}
