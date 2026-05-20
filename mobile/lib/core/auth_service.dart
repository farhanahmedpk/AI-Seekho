import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _usersKey = 'auth_users';
  static const _sessionKey = 'auth_session';

  static Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    final Map<String, dynamic> users =
        usersJson != null ? jsonDecode(usersJson) : {};
    final key = email.trim().toLowerCase();
    if (users.containsKey(key)) return 'Account already exists.';
    users[key] = {
      'name': name.trim(),
      'email': key,
      'password': base64Encode(utf8.encode(password)),
    };
    await prefs.setString(_usersKey, jsonEncode(users));
    await prefs.setString(_sessionKey, jsonEncode({'email': key, 'name': name.trim()}));
    return null;
  }

  static Future<String?> login({required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return 'No account found.';
    final Map<String, dynamic> users = jsonDecode(usersJson);
    final key = email.trim().toLowerCase();
    if (!users.containsKey(key)) return 'No account with this email.';
    final user = users[key];
    final stored = utf8.decode(base64Decode(user['password'] as String));
    if (stored != password) return 'Incorrect password.';
    await prefs.setString(_sessionKey, jsonEncode({'email': key, 'name': user['name']}));
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_sessionKey);
  }

  static Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_sessionKey);
    if (s == null) return null;
    return (jsonDecode(s))['name'] as String?;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
