import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/truck.dart';
import '../models/incident.dart';
import '../models/agent_step.dart';

class ApiService {
  static const String _defaultBaseUrl = 'http://192.168.100.8:8000';
  static const String _prefsKey = 'backend_url';

  late Dio _dio;
  String _baseUrl;

  ApiService._internal(this._baseUrl)
      : _dio = Dio(BaseOptions(baseUrl: _baseUrl, connectTimeout: const Duration(seconds: 5))) {
    print('🚀 [ApiService] New instance created with Base URL: $_baseUrl');
  }

  static ApiService? _instance;

  /// Factory that reads from SharedPreferences on first call
  static Future<ApiService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_prefsKey) ?? _defaultBaseUrl;
    _instance = ApiService._internal(url);
    return _instance!;
  }

  /// Synchronous getter — uses last created instance or default
  factory ApiService() {
    if (_instance == null) {
      print('⚠️ [ApiService] Accessing instance before initialization! Using default: $_defaultBaseUrl');
      _instance = ApiService._internal(_defaultBaseUrl);
    }
    return _instance!;
  }

  /// Update the base URL at runtime and persist it
  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, url);
    _instance = ApiService._internal(url);
  }

  /// Get the current base URL
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey) ?? _defaultBaseUrl;
  }

  /// Test connection to the backend
  static Future<bool> testConnection(String url) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ));
      final response = await dio.get('/sensors');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Truck>> getSensors() async {
    print('📡 [ApiService] getSensors() calling: $_baseUrl/sensors');
    try {
      final response = await _dio.get('/sensors');
      
      // Handle the wrapped format: {"sensors": [...], "count": 10}
      if (response.data is Map && response.data.containsKey('sensors')) {
        final List sensorList = response.data['sensors'];
        return sensorList.map((json) => Truck.fromJson(json)).toList();
      }
      
      // Fallback for raw list format
      if (response.data is List) {
        return (response.data as List).map((json) => Truck.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('❌ [ApiService] getSensors error: $e');
      rethrow;
    }
  }

  Future<void> triggerBreach(String truckId, double temperature) async {
    try {
      await _dio.post(
        '/trigger-breach',
        data: {
          'truck_id': truckId,
          'temperature': temperature,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resolveAllBreaches() async {
    try {
      await _dio.post(
        '/resolve-all-breaches',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
    } catch (_) {
      // Ignore all errors - backend continues processing in background
    }
  }

  Stream<Map<String, dynamic>> streamAgentTrace(String truckId, double temperature) async* {
    try {
      final response = await _dio.get<ResponseBody>(
        '/agent-trace/stream/$truckId/$temperature',
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      final stream = response.data?.stream;
      if (stream == null) return;

      final linesStream = stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in linesStream) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6).trim();
          if (jsonStr.isNotEmpty) {
            try {
              final Map<String, dynamic> data = jsonDecode(jsonStr);
              yield data;
            } catch (e) {
              // Ignore invalid JSON parsing errors
            }
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Incident>> getIncidents() async {
    print('📡 [ApiService] getIncidents() calling: $_baseUrl/incidents');
    try {
      final response = await _dio.get('/incidents');
      
      // Handle the wrapped format: {"incidents": [...], "count": X}
      if (response.data is Map && response.data.containsKey('incidents')) {
        final List incidentList = response.data['incidents'];
        return incidentList.map((json) => Incident.fromJson(json)).toList();
      }
      
      // Fallback for raw list format
      if (response.data is List) {
        return (response.data as List).map((json) => Incident.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('❌ [ApiService] getIncidents error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAgentTrace(String incidentId) async {
    try {
      final response = await _dio.get('/agent-trace/$incidentId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ [ApiService] getAgentTrace error: $e');
      rethrow;
    }
  }
}
