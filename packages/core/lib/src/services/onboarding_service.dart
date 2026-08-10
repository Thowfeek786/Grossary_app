import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _keyUserOnboarding = 'has_seen_user_onboarding';
  static const String _keyDealerOnboarding = 'has_seen_dealer_onboarding';
  static const String _keyDeliveryOnboarding = 'has_seen_delivery_onboarding';

  /// Check if user has seen onboarding for specific app type
  static Future<bool> hasSeenOnboarding(String appType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKeyForApp(appType);
    return prefs.getBool(key) ?? false;
  }

  /// Mark onboarding as completed
  static Future<void> setOnboardingCompleted(String appType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKeyForApp(appType);
    await prefs.setBool(key, true);
  }

  /// Reset onboarding status (for testing or profile settings)
  static Future<void> resetOnboarding(String appType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKeyForApp(appType);
    await prefs.remove(key);
  }

  static String _getKeyForApp(String appType) {
    switch (appType.toLowerCase()) {
      case 'dealer':
        return _keyDealerOnboarding;
      case 'delivery':
        return _keyDeliveryOnboarding;
      case 'user':
      default:
        return _keyUserOnboarding;
    }
  }
}
