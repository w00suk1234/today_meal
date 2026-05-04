import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/report_generator.dart';
import '../../widgets/app_section_title.dart';
import 'widgets/report_message_card.dart';
import 'widgets/report_summary_card.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final summary = controller.todaySummary;
    final messages = ReportGenerator.generateAdvancedDailyReport(
      summary: summary,
      profile: controller.profile,
      healthProfile: controller.healthProfile,
      weightLogs: controller.weightLogs,
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const Text('오늘 리포트', style: AppTextStyles.title),
          const SizedBox(height: 4),
          const Text('외부 AI 없이 규칙 기반 템플릿으로 생성됩니다.', style: AppTextStyles.muted),
          const SizedBox(height: 18),
          ReportSummaryCard(summary: summary, targetKcal: controller.profile.targetKcal),
          const AppSectionTitle('피드백'),
          for (final message in messages) ReportMessageCard(message: message),
        ],
      ),
    );
  }
}
