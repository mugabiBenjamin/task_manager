import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class LoadingWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingWidget({
    super.key,
    this.size = AppConstants.iconSize * 2,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: color ?? AppConstants.primaryColor,
          strokeWidth: 3,
        ),
      ),
    );
  }
}
