import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/health_calculator.dart';
import '../../../data/models/health_profile.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_section_title.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  final _nicknameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'male';
  String _activityLevel = 'light';
  String _goalType = 'maintain';
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 30);
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
    final weightDiff = HealthCalculator.calculateWeightDiff(current.weightKg, current.targetWeightKg);
    final weightLogs = AppScope.of(context).weightLogs.reversed.take(5).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const Text('내 몸 상태', style: AppTextStyles.title),
          const SizedBox(height: 4),
          const Text(AppConstants.estimateNotice, style: AppTextStyles.muted),
          const AppSectionTitle('기본 정보'),
          TextField(controller: _nicknameController, decoration: const InputDecoration(labelText: '닉네임')),
          const SizedBox(height: 12),
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
            label: Text(_birthDate == null ? '생년월일 선택' : '${_birthDate!.year}-${_birthDate!.month}-${_birthDate!.day}'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '키', suffixText: 'cm'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '몸무게', suffixText: 'kg'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetWeightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '목표 체중', suffixText: 'kg'),
            onChanged: (_) => setState(() {}),
          ),
          const AppSectionTitle('활동과 목표'),
          DropdownButtonFormField<String>(
            initialValue: _activityLevel,
            decoration: const InputDecoration(labelText: '활동량'),
            items: const [
              DropdownMenuItem(value: 'sedentary', child: Text('거의 활동 없음')),
              DropdownMenuItem(value: 'light', child: Text('가벼운 활동')),
              DropdownMenuItem(value: 'moderate', child: Text('보통 활동')),
              DropdownMenuItem(value: 'active', child: Text('높은 활동')),
              DropdownMenuItem(value: 'veryActive', child: Text('매우 높은 활동')),
            ],
            onChanged: (value) => setState(() => _activityLevel = value ?? 'light'),
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
          const AppSectionTitle('추정 건강 지표'),
          _MetricCard(
            title: 'BMI',
            value: current.bmi <= 0 ? '미입력' : current.bmi.toStringAsFixed(1),
            subtitle: bmiCategory,
          ),
          _MetricCard(
            title: '기초대사량 / 유지 칼로리',
            value: '${current.bmr.round()} / ${current.tdee.round()}kcal',
            subtitle: 'Mifflin-St Jeor 공식 기반 추정값',
          ),
          _MetricCard(
            title: '목표 칼로리',
            value: '${current.targetKcal.round()}kcal',
            subtitle: '목표 체중까지 ${weightDiff.toStringAsFixed(1)}kg',
          ),
          const AppSectionTitle('몸무게 변화 기록'),
          if (weightLogs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('아직 저장된 몸무게 변화 기록이 없습니다.', style: AppTextStyles.muted),
              ),
            )
          else
            for (final log in weightLogs)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.monitor_weight_outlined),
                  title: Text('${log.weightKg.toStringAsFixed(1)}kg'),
                  subtitle: Text('BMI ${log.bmi.toStringAsFixed(1)} · ${log.loggedAt.month}/${log.loggedAt.day}'),
                ),
              ),
          const SizedBox(height: 16),
          AppPrimaryButton(label: '내 몸 상태 저장', icon: Icons.save_outlined, onPressed: _save),
        ],
      ),
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
    final picked = await showTimePicker(context: context, initialTime: _sleepTime);
    if (picked != null) {
      setState(() => _sleepTime = picked);
    }
  }

  Future<void> _save() async {
    final profile = _draftProfile().recalculated();
    if (profile.heightCm <= 0 || profile.weightKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('키와 몸무게를 입력해 주세요.')));
      return;
    }
    await AppScope.of(context).saveHealthProfile(profile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('내 몸 상태가 저장되었습니다.')));
    }
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.tryParse(parts.first) ?? 23, minute: int.tryParse(parts.length > 1 ? parts[1] : '30') ?? 30);
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, required this.subtitle});

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.muted),
              const SizedBox(height: 6),
              Text(value, style: AppTextStyles.section),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.muted),
            ],
          ),
        ),
      ),
    );
  }
}
