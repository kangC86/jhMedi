import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // 앱 전역에서 로그인 상태를 구독할 수 있는 노티파이어
  static final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn.value = prefs.getBool('isLoggedIn') ?? false;
  }

  static Future<void> setLoggedIn(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', v);
    isLoggedIn.value = v; // 모든 구독자에게 즉시 알림 → UI 자동 리빌드
  }

  static Future<void> logout() => setLoggedIn(false);
}
