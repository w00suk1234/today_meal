import '../../core/constants/app_constants.dart';

class UserProfile {
  const UserProfile({
    required this.nickname,
    required this.targetKcal,
    required this.goalType,
    this.heightCm,
    this.weightKg,
  });

  final String nickname;
  final double targetKcal;
  final double? heightCm;
  final double? weightKg;
  final String goalType;

  factory UserProfile.defaultProfile() {
    return const UserProfile(
      nickname: '',
      targetKcal: AppConstants.defaultTargetKcal,
      goalType: 'maintain',
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    double? nullableDouble(Object? value) {
      if (value == null || '$value'.trim().isEmpty) {
        return null;
      }
      return value is num ? value.toDouble() : double.tryParse('$value');
    }

    double toDouble(Object? value, double fallback) {
      return value is num
          ? value.toDouble()
          : double.tryParse('$value') ?? fallback;
    }

    return UserProfile(
      nickname: json['nickname'] as String? ?? '',
      targetKcal: toDouble(json['targetKcal'], AppConstants.defaultTargetKcal),
      heightCm: nullableDouble(json['heightCm']),
      weightKg: nullableDouble(json['weightKg']),
      goalType: json['goalType'] as String? ?? 'maintain',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'targetKcal': targetKcal,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'goalType': goalType,
    };
  }
}
