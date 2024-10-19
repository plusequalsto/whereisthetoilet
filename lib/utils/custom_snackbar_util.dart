import 'package:whereisthetoilet/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';

class CustomSnackBarUtil {
  static final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  static showCustomSnackBar(String message, {bool success = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final snackBar = SnackBar(
        content: CustomSnackBar(
          message: message,
          success: success,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      );

      rootScaffoldMessengerKey.currentState?.showSnackBar(snackBar);
    });
  }
}
