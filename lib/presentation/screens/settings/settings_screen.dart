import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/health_calculator.dart';
import '../../../data/models/health_profile.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/primary_action_button.dart';
import '../../widgets/section_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({this.scrollController, super.key});

  final ScrollController? scrollController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nicknameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'male';
  String _activityLevel = 'light';
  String _goalType = 'maintain';
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 30);
  bool _mealReminder = true;
  bool _aiGuide = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final profile = AppScope.of(context).healthProfile;
    _nicknameController.text = profile.nickname;
    _heightController.text = profile.heightCm.toStringAsFixed(0);
    _weightController.text = profile.weightKg.toStringAsFixed(1);
    _targetWeightController.text = profile.targetWeightKg.toStringAsFixed(1);
    _birthDate = profile.birthDate;
    _gender = profile.gender;
    _activityLevel = profile.activityLevel;
    _goalType = profile.goalType;
    _sleepTime = _parseTime(profile.sleepTime);
    _initialized = true;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _draftProfile().recalculated();
    final bmiCategory = HealthCalculator.getBmiCategory(current.bmi);
    final age = HealthCalculator.calculateAge(current.birthDate);

    return AppScaffold(
      controller: widget.scrollController,
      children: [
        const AppPageHeader(
          title: '설정',
          subtitle: '프로필과 건강 목표를 관리해요',
          icon: Icons.settings_outlined,
        ),
        _ProfileCard(
          nickname: _nicknameController.text.trim().isEmpty
              ? '오늘식단 사용자'
              : _nicknameController.text.trim(),
          goalType: _goalLabel(_goalType),
        ),
        const SectionHeader(title: '몸상태 요약'),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '현재 체중',
                value: '${current.weightKg.toStringAsFixed(1)}kg',
                subtitle: '목표 ${current.targetWeightKg.toStringAsFixed(1)}kg',
                icon: Icons.monitor_weight_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                title: 'BMI',
                value:
                    current.bmi <= 0 ? '미입력' : current.bmi.toStringAsFixed(1),
                subtitle: bmiCategory,
                icon: Icons.favorite_outline,
                color: AppColors.coral,
              ),
            ),
          ],
        ),
        const SectionHeader(title: '프로필 정보'),
        AppCard(
          child: Column(
            children: [
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: '닉네임'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: '키', suffixText: 'cm'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: '현재 체중', suffixText: 'kg'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetWeightController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: '목표 체중', suffixText: 'kg'),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SectionHeader(title: '신체 및 목표 설정'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const {
                  'male': '남성',
                  'female': '여성',
                  'other': '기타',
                }.entries.map((entry) {
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: _gender == entry.key,
                    onSelected: (_) => setState(() => _gender = entry.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickBirthDate,
                icon: const Icon(Icons.cake_outlined),
                label: Text(_birthDate == null
                    ? '생년월일 선택'
                    : '${_birthDate!.year}-${_birthDate!.month}-${_birthDate!.day} · 만 $age세'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _activityLevel,
                decoration: const InputDecoration(labelText: '활동량'),
                items: const [
                  DropdownMenuItem(value: 'sedentary', child: Text('거의 활동 없음')),
                  DropdownMenuItem(value: 'light', child: Text('가벼운 활동')),
                  DropdownMenuItem(value: 'moderate', child: Text('보통 활동')),
                  DropdownMenuItem(value: 'active', child: Text('높은 활동')),
                  DropdownMenuItem(
                      value: 'veryActive', child: Text('매우 높은 활동')),
                ],
                onChanged: (value) =>
                    setState(() => _activityLevel = value ?? 'light'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const {
                  'loss': '감량',
                  'maintain': '유지',
                  'gain': '증량',
                }.entries.map((entry) {
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: _goalType == entry.key,
                    onSelected: (_) => setState(() => _goalType = entry.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickSleepTime,
                icon: const Icon(Icons.bedtime_outlined),
                label: Text('평소 취침 시간 ${_sleepTime.format(context)}'),
              ),
            ],
          ),
        ),
        const SectionHeader(title: '일일 권장 섭취량'),
        AppCard(
          color: AppColors.primaryDark,
          borderColor: AppColors.primaryDark,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.bolt_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${current.targetKcal.round()} kcal',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                        'BMR ${current.bmr.round()} · TDEE ${current.tdee.round()} 기반 추정',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.76),
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(title: '알림 설정'),
        _SwitchCard(
          title: '식사 기록 리마인더',
          subtitle: '아침, 점심, 저녁 기록을 잊지 않도록 도와줘요',
          icon: Icons.notifications_active_outlined,
          value: _mealReminder,
          onChanged: (value) => setState(() => _mealReminder = value),
        ),
        const SizedBox(height: 10),
        _SwitchCard(
          title: 'AI 분석 안내 표시',
          subtitle: 'AI 분석이 참고용이라는 안내를 화면에 유지해요',
          icon: Icons.privacy_tip_outlined,
          value: _aiGuide,
          onChanged: (value) => setState(() => _aiGuide = value),
        ),
        const SectionHeader(title: '개인정보 / AI 분석 안내'),
        AppCard(
          color: AppColors.creamBackground,
          borderColor: AppColors.orange.withValues(alpha: 0.18),
          child: const Text(AppConstants.estimateNotice,
              style: AppTextStyles.body),
        ),
        const SectionHeader(title: '앱 설정'),
        const AppCard(
          child: Column(
            children: [
              _InfoRow(
                  icon: Icons.storage_outlined,
                  title: '데이터 저장',
                  value: '기기에 우선 저장'),
              Divider(height: 22, color: AppColors.divider),
              _InfoRow(
                  icon: Icons.auto_awesome,
                  title: 'AI 분석 안내',
                  value: '사진 기반 음식 후보 분석'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PrimaryActionButton(
            label: '건강 정보 저장', icon: Icons.save_outlined, onPressed: _save),
      ],
    );
  }

  HealthProfile _draftProfile() {
    return HealthProfile(
      nickname: _nicknameController.text.trim(),
      gender: _gender,
      birthDate: _birthDate,
      heightCm: double.tryParse(_heightController.text.trim()) ?? 0,
      weightKg: double.tryParse(_weightController.text.trim()) ?? 0,
      targetWeightKg: double.tryParse(_targetWeightController.text.trim()) ?? 0,
      activityLevel: _activityLevel,
      goalType: _goalType,
      sleepTime: _formatTime(_sleepTime),
      targetKcal: AppScope.of(context).healthProfile.targetKcal,
      bmr: 0,
      tdee: 0,
      bmi: 0,
    );
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1995),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _pickSleepTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _sleepTime);
    if (picked != null) {
      setState(() => _sleepTime = picked);
    }
  }

  Future<void> _save() async {
    final profile = _draftProfile().recalculated();
    if (profile.heightCm <= 0 || profile.weightKg <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('키와 몸무게를 입력해 주세요.')));
      return;
    }
    await AppScope.of(context).saveHealthProfile(profile);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('건강 정보가 저장되었습니다.')));
    }
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
        hour: int.tryParse(parts.first) ?? 23,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '30') ?? 30);
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static String _goalLabel(String type) {
    return switch (type) {
      'loss' => '감량 목표',
      'gain' => '증량 목표',
      _ => '유지 목표',
    };
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.nickname, required this.goalType});

  final String nickname;
  final String goalType;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    AppColors.primarySoft,
                    AppColors.creamBackground
                  ]),
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 34),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nickname,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(goalType, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
              value: value,
              activeThumbColor: AppColors.primary,
              onChanged: onChanged),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w800))),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
