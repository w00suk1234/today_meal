import 'dart:convert';

import '../local/local_storage_service.dart';
import '../models/user_profile.dart';

class UserRepository {
  UserRepository(this._storage);

  static const _key = 'user_profile_v1';
  final LocalStorageService _storage;

  Future<UserProfile> loadProfile() async {
    try {
      final raw = _storage.getString(_key);
      if (raw == null || raw.isEmpty) {
        return UserProfile.defaultProfile();
      }
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return UserProfile.defaultProfile();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final ok = await _storage.setString(_key, jsonEncode(profile.toJson()));
    if (!ok) {
      throw Exception('사용자 설정 저장에 실패했습니다.');
    }
  }
}
