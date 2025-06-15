import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/label_model.dart';

class LabelChip extends StatelessWidget {
  final LabelModel label;
  final bool isSelected;
  final VoidCallback? onTap;

  const LabelChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(
          label.name,
          style: AppConstants.bodyStyle.copyWith(
            color: isSelected
                ? AppConstants.textPrimaryColor
                : AppConstants.textSecondaryColor,
          ),
        ),
        backgroundColor: Color(
          int.parse(label.color.replaceFirst('#', '0xFF')),
        ).withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: BorderSide(
            color: isSelected
                ? AppConstants.primaryColor
                : AppConstants.textSecondaryColor,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.smallPadding,
        ),
      ),
    );
  }
}
