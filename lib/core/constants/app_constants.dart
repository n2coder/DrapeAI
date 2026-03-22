class AppConstants {
  AppConstants._();

  // API
  static const String apiBaseUrl = 'https://drapeai-wnum.onrender.com';

  // Image upload is proxied through backend — never hardcode credentials in production.
  // Set via backend — never hardcode in production.
  static const String cloudinaryCloudName = 'dqrbdm6mt';
  static const String cloudinaryUploadPreset = 'drapeai_mobile';

  // SharedPreferences keys
  static const String jwtTokenKey = 'jwt_token';
  static const String userIdKey = 'user_id';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String userProfileKey = 'user_profile';

  // Occasion types
  static const List<String> occasionTypes = [
    'Casual',
    'Office',
    'Party',
    'Wedding',
    'Date',
    'Gym',
    'Travel',
  ];

  // Style types
  static const List<String> styleTypes = [
    'Ethnic',
    'Casual',
    'Urban',
    'Formal',
    'Streetwear',
    'Bohemian',
    'Minimalist',
  ];

  // Clothing category types
  static const List<String> categoryTypes = [
    'Top',
    'Bottom',
    'Footwear',
    'Outerwear',
    'Accessories',
    'Dress',
    'Ethnic Wear',
  ];

  // Color options
  static const List<String> colorOptions = [
    'Black',
    'White',
    'Navy',
    'Grey',
    'Beige',
    'Brown',
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Pink',
    'Purple',
    'Orange',
    'Multi-color',
  ];

  // Gender options
  static const List<String> genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  // Age ranges
  static const List<String> ageRanges = [
    '13-17',
    '18-24',
    '25-34',
    '35-44',
    '45-54',
    '55+',
  ];

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusCircular = 100.0;
}
