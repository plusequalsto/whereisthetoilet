import 'package:whereisthetoilet/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomSnackBar extends StatelessWidget {
  final String message;
  final bool? success;

  const CustomSnackBar({Key? key, required this.message, this.success})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: success == true ? AppColors.dullGreen : AppColors.dullRed,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.normal,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }
}
