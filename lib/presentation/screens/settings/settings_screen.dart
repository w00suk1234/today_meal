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
  final _ageController = TextEditingController();
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
    _ageController.text = profile.effectiveAgeYears > 0
        ? profile.effectiveAgeYears.toString()
        : '';
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
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _draftProfile().recalculated();
    final bmiCategory = HealthCalculator.getBmiCategory(current.bmi);
    final age = current.effectiveAgeYears;

    return AppScaffold(
      controller: widget.scrollController,
      children: [
        const AppPageHeader(
          title: '설정',
          subtitle: '내 기준을 저장해 AI 식단 코치가 더 자연스럽게 참고해요',
          icon: Icons.settings_outlined,
        ),
        _ProfileCard(
          nickname: _nicknameController.text.trim(),
          goalLabel: _goalLabel(_goalType),
          activityLabel: _activityLabel(_activityLevel),
          currentWeightKg: current.weightKg,
          targetWeightKg: current.targetWeightKg,
          ageYears: age,
        ),
        const SectionHeader(
          title: '몸상태 요약',
          subtitle: '아래 입력값을 기준으로 참고 지표를 계산해요',
        ),
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
        const SectionHeader(
          title: '내 몸 기준',
          subtitle: 'AI 플랜과 권장 섭취량 계산에 쓰이는 기본 정보예요',
        ),
        AppCard(
          child: Column(
            children: [
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: '닉네임',
                  hintText: '예: 우석',
                  helperText: '홈과 AI 플랜에서 부를 이름이에요',
                ),
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
                        labelText: '키',
                        suffixText: 'cm',
                        helperText: 'BMI 계산',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '현재 체중',
                        suffixText: 'kg',
                        helperText: '초기 기준값',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '나이',
                  suffixText: '세',
                  helperText: '권장 섭취량 계산에만 참고해요',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetWeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '목표 체중',
                  suffixText: 'kg',
                  helperText: '무리한 목표보다 꾸준한 흐름을 기준으로 봐요',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SectionHeader(
          title: '생활 패턴과 목표',
          subtitle: '성별, 활동량, 목표에 따라 하루 참고 섭취량이 달라져요',
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('성별', style: AppTextStyles.caption),
              const SizedBox(height: 8),
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
              const Text('목표', style: AppTextStyles.caption),
              const SizedBox(height: 8),
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
        const SectionHeader(title: '하루 목표 섭취량'),
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
                      '나이 ${age > 0 ? '$age세' : '미입력'} · 활동량과 목표를 반영한 참고값',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.76),
                          fontWeight: FontWeight.w700),
                    ),
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
      ageYears: int.tryParse(_ageController.text.trim()),
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

  Future<void> _pickSleepTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _sleepTime);
    if (picked != null) {
      setState(() => _sleepTime = picked);
    }
  }

  Future<void> _save() async {
    final profile = _draftProfile().recalculated();
    final validationMessage = _validateProfile(profile);
    if (validationMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }
    await AppScope.of(context).saveHealthProfile(profile);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('건강 정보가 저장되었습니다.')));
    }
  }

  String? _validateProfile(HealthProfile profile) {
    if (profile.heightCm < 50 || profile.heightCm > 250) {
      return '키는 50~250cm 범위로 입력해 주세요.';
    }
    if (profile.weightKg < 20 || profile.weightKg > 300) {
      return '현재 몸무게는 20~300kg 범위로 입력해 주세요.';
    }
    if (profile.targetWeightKg < 20 || profile.targetWeightKg > 300) {
      return '목표 몸무게는 20~300kg 범위로 입력해 주세요.';
    }
    final age = profile.effectiveAgeYears;
    if (age < 10 || age > 100) {
      return '나이는 10~100세 범위로 입력해 주세요.';
    }
    return null;
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
      'loss' => '천천히 감량',
      'gain' => '건강하게 증량',
      _ => '현재 리듬 유지',
    };
  }

  static String _activityLabel(String type) {
    return switch (type) {
      'sedentary' => '활동 적음',
      'moderate' => '보통 활동',
      'active' => '활동 많은 편',
      'veryActive' => '매우 활동적',
      _ => '가벼운 활동',
    };
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.nickname,
    required this.goalLabel,
    required this.activityLabel,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.ageYears,
  });

  final String nickname;
  final String goalLabel;
  final String activityLabel;
  final double currentWeightKg;
  final double targetWeightKg;
  final int ageYears;

  @override
  Widget build(BuildContext context) {
    final hasNickname = nickname.trim().isNotEmpty;
    final hasWeightPlan = currentWeightKg > 0 && targetWeightKg > 0;
    final displayName = hasNickname ? nickname.trim() : '닉네임을 정해 주세요';
    final supportText = hasNickname
        ? '$displayName님 기준으로 식단 목표를 맞춰요'
        : '저장하면 홈과 AI 플랜에 이름이 반영돼요';
    final journeyText = hasWeightPlan
        ? '${currentWeightKg.toStringAsFixed(1)}kg → ${targetWeightKg.toStringAsFixed(1)}kg'
        : '키와 몸무게를 입력하면 AI 플랜이 더 정확해져요';

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primarySoft,
                          AppColors.creamBackground,
                        ],
                      ),
                    ),
                    child: Icon(
                      hasNickname ? Icons.person_rounded : Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 34,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color:
                            hasNickname ? AppColors.primary : AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasNickname
                            ? Icons.check_rounded
                            : Icons.priority_high_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(supportText, style: AppTextStyles.caption),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        AppTag(
                          label: goalLabel,
                          icon: Icons.flag_outlined,
                          color: AppColors.primary,
                        ),
                        AppTag(
                          label: activityLabel,
                          icon: Icons.directions_walk_rounded,
                          color: AppColors.teal,
                        ),
                        if (ageYears > 0)
                          AppTag(
                            label: '$ageYears세',
                            icon: Icons.cake_outlined,
                            color: AppColors.orange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.route_outlined,
                  color: AppColors.primary,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    journeyText,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
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
