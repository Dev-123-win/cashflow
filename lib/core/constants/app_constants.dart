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
  static const int maxDailyCoins = 1200; // 1.20 * 1000
  static const int maxTasksPerDay = 3;
  static const int maxGamesPerDay = 6;
  static const int maxAdsPerDay = 15;
  static const int maxSpinsPerDay = 1;

  // Withdrawal Settings (OPTIMIZED - Backend source-of-truth)
  static const int minWithdrawalCoins = 100000; // 100 * 1000
  static const int maxWithdrawalCoins = 5000000; // 5000 * 1000
  static const int minAccountAgeDays = 7;
  static const double withdrawalFeePercentage = 0.02; // 2% fee

  // Task Rewards (OPTIMIZED - Reduced by 15%)
  static const Map<String, int> taskRewards = {
    'survey': 85, // 0.085 * 1000
    'social_share': 85, // 0.085 * 1000
    'app_rating': 85, // 0.085 * 1000
  };

  // Game Rewards (OPTIMIZED - Reduced by 25%)
  static const Map<String, int> gameRewards = {
    'tictactoe': 60, // 0.06 * 1000
    'memory_match': 60, // 0.06 * 1000
  };

  // Ad Rewards (OPTIMIZED - Reduced by 15%)
  static const int rewardedAdReward = 25; // 0.025 * 1000
  static const int interstitialAdReward = 20; // 0.02 * 1000

  // Spin Rewards (OPTIMIZED - Backend source-of-truth)
  static const int spinMinReward = 50; // 0.05 * 1000
  static const int spinMaxReward = 750; // 0.75 * 1000
  static const List<double> spinRewards = [50, 100, 150, 200, 300, 500, 750];

  // Cooldown Periods (in minutes)
  static const int taskCooldownMinutes = 0;
  static const int gameCooldownMinutes = 30;
  static const int adCooldownMinutes = 0;

  // Streak Bonuses
  static const Map<int, int> streakBonuses = {
    7: 500,
    14: 1000,
    30: 2000,
  }; // 0.50, 1.00, 2.00 * 1000

  // Referral Settings
  static const int referralReward = 2000; // 2.00 * 1000
  static const int referralLimit = 10000; // 10.0 * 1000

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
