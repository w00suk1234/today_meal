import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/user_profile.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_section_title.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nicknameController = TextEditingController();
  final _targetController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _goalType = 'maintain';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final profile = AppScope.of(context).profile;
    _nicknameController.text = profile.nickname;
    _targetController.text = profile.targetKcal.round().toString();
    _heightController.text = profile.heightCm?.toStringAsFixed(0) ?? '';
    _weightController.text = profile.weightKg?.toStringAsFixed(1) ?? '';
    _goalType = profile.goalType;
    _initialized = true;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _targetController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const Text('설정', style: AppTextStyles.title),
          const SizedBox(height: 4),
          const Text('목표 칼로리는 직접 입력합니다. BMR 계산은 추후 확장 범위입니다.', style: AppTextStyles.muted),
          const AppSectionTitle('프로필'),
          TextField(controller: _nicknameController, decoration: const InputDecoration(labelText: '이름 또는 닉네임')),
          const SizedBox(height: 12),
          TextField(
            controller: _targetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '목표 칼로리', suffixText: 'kcal'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '키', suffixText: 'cm'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '몸무게', suffixText: 'kg'),
                ),
              ),
            ],
          ),
          const AppSectionTitle('목표'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'loss', label: Text('감량')),
              ButtonSegment(value: 'maintain', label: Text('유지')),
              ButtonSegment(value: 'gain', label: Text('증량')),
            ],
            selected: {_goalType},
            onSelectionChanged: (value) => setState(() => _goalType = value.first),
          ),
          const SizedBox(height: 24),
          AppPrimaryButton(label: '설정 저장', icon: Icons.save_outlined, onPressed: _save),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final targetKcal = double.tryParse(_targetController.text.trim()) ?? 0;
    if (targetKcal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('목표 칼로리를 0보다 크게 입력해 주세요.')));
      return;
    }

    final profile = UserProfile(
      nickname: _nicknameController.text.trim(),
      targetKcal: targetKcal,
      heightCm: double.tryParse(_heightController.text.trim()),
      weightKg: double.tryParse(_weightController.text.trim()),
      goalType: _goalType,
    );

    try {
      await AppScope.of(context).saveProfile(profile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('설정이 저장되었습니다.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('설정 저장에 실패했습니다.')));
      }
    }
  }
}
