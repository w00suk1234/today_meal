import 'package:flutter/material.dart';

import 'section_header.dart';

class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(title: title);
  }
}
