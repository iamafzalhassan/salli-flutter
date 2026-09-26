abstract final class MockLimits {
  static const String basicTier = 'basic';
  static const String verifiedTier = 'verified';

  static const Map<String, ({int dailyCents, int monthlyCents, int perPaymentCents})> tiers = {
    basicTier: (dailyCents: 5000000, monthlyCents: 20000000, perPaymentCents: 2500000),
    verifiedTier: (dailyCents: 50000000, monthlyCents: 200000000, perPaymentCents: 20000000),
  };

  static const Duration dailyWindow = Duration(days: 1);
  static const Duration monthlyWindow = Duration(days: 30);

  static ({int dailyCents, int monthlyCents, int perPaymentCents}) of(Map<String, dynamic>? user) => tiers[tierOf(user)]!;

  static String tierOf(Map<String, dynamic>? user) => user?['kycTier'] as String? ?? basicTier;
}
