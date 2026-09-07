import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/models/login_data.dart';

class SessionManager {
  static const String _keyUser = 'user_data';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keySkAccepted = 'sk_accepted';

  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveUser(LoginData user) async {
    await _prefs.setString(_keyUser, jsonEncode(user.toJson()));
    await _prefs.setBool(_keyIsLoggedIn, true);
  }

  LoginData? getUser() {
    final userStr = _prefs.getString(_keyUser);
    if (userStr == null) return null;
    return LoginData.fromJson(jsonDecode(userStr));
  }

  bool isLoggedIn() {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<void> setSkAccepted(bool accepted) async {
    await _prefs.setBool(_keySkAccepted, accepted);
  }

  bool isSkAccepted() {
    return _prefs.getBool(_keySkAccepted) ?? false;
  }

  Future<void> clear() async {
    // Keep SK accepted status but clear user data
    final skAccepted = isSkAccepted();
    await _prefs.clear();
    await setSkAccepted(skAccepted);
  }
}
