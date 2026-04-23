import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.safetyOrange,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.safetyOrange.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.local_taxi_rounded,
          size: size * 0.6,
          color: Colors.black,
        ),
      ),
    );
  }
}
