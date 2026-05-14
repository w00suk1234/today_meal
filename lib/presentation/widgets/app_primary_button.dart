import 'package:flutter/material.dart';

import 'primary_action_button.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PrimaryActionButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
    );
  }
}
