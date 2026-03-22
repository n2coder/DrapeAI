import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:style_ai/core/constants/app_constants.dart';

class WeatherData {
  final double temperature;
  final String description;
  final String icon;
  final String cityName;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String condition;

  const WeatherData({
    required this.temperature,
    required this.description,
    required this.icon,
    required this.cityName,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '01d',
      cityName: json['cityName'] as String? ?? '',
      feelsLike: (json['feelsLike'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (json['windSpeed'] as num?)?.toDouble() ?? 0.0,
      condition: json['condition'] as String? ?? 'clear',
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';

  String get temperatureCelsius => '${temperature.round()}°C';

  String get contextDescription {
    final temp = temperature;
    if (temp < 10) return 'Cold';
    if (temp < 18) return 'Cool';
    if (temp < 25) return 'Mild';
    if (temp < 32) return 'Warm';
    return 'Hot';
  }

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'description': description,
    'icon': icon,
    'cityName': cityName,
    'feelsLike': feelsLike,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'condition': condition,
  };
}

/// Fetches weather data via the StyleAI backend (GET /users/weather?city=...).
/// The Flutter app never calls OpenWeather directly — the API key lives on the server.
class WeatherService {
  final String _baseUrl = AppConstants.apiBaseUrl;
  final http.Client _client;
  final _secureStorage = const FlutterSecureStorage();

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> _getToken() async {
    return _secureStorage.read(key: AppConstants.jwtTokenKey);
  }

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await _getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<WeatherData> getWeatherByCity(String city) async {
    final headers = await _buildHeaders();
    final uri = Uri.parse('$_baseUrl/users/weather').replace(
      queryParameters: {'city': city},
    );
    final response = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return WeatherData.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('City not found: $city');
    } else {
      throw Exception('Failed to fetch weather: ${response.statusCode}');
    }
  }

  String getWeatherOutfitContext(WeatherData weather) {
    final temp = weather.temperature;
    final condition = weather.condition.toLowerCase();

    if (condition.contains('rain') || condition.contains('drizzle')) {
      return 'rainy';
    }
    if (condition.contains('snow')) {
      return 'snowy';
    }
    if (temp < 10) return 'cold';
    if (temp < 18) return 'cool';
    if (temp < 25) return 'mild';
    if (temp < 32) return 'warm';
    return 'hot';
  }

  void dispose() {
    _client.close();
  }
}
